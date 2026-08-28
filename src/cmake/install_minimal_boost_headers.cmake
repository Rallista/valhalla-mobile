# Install the headers that the public wrapper API reaches, and no others.
#
# This is the body of install_minimal_boost_headers() in src/CMakeLists.txt. It
# runs at install time, because it has to see the headers that the build
# generates.
#
# The steps are:
#   1. Write one probe source that includes every public header.
#   2. Ask the compiler which headers the probe reads.
#   3. Keep the ones under the vcpkg include tree, and copy them.
#
# The caller sets these variables in the install(CODE) block that runs first:
#
#   BOOST_HEADERS_COMPILER      the C++ compiler to scan with
#   BOOST_HEADERS_FLAGS         flags that make the scan match a consumer build
#   BOOST_HEADERS_INCLUDE_DIRS  the include path the public headers need
#   BOOST_HEADERS_PUBLIC        the public headers to scan
#   BOOST_HEADERS_ROOT          the vcpkg include tree to prune
#   BOOST_HEADERS_KEEP          globs under the root to keep whatever the scan says
#   BOOST_HEADERS_DESTINATION   where the kept headers go
#   BOOST_HEADERS_SCRATCH       a directory for the probe and the scan output

foreach(_required
        BOOST_HEADERS_COMPILER
        BOOST_HEADERS_INCLUDE_DIRS
        BOOST_HEADERS_PUBLIC
        BOOST_HEADERS_ROOT
        BOOST_HEADERS_DESTINATION
        BOOST_HEADERS_SCRATCH)
    if(NOT ${_required})
        message(FATAL_ERROR "install_minimal_boost_headers: ${_required} is not set.")
    endif()
endforeach()

get_filename_component(_root "${BOOST_HEADERS_ROOT}" REALPATH)

# Step 1. Write one probe source that includes every public header.
set(_probe_text "")
foreach(_header IN LISTS BOOST_HEADERS_PUBLIC)
    string(APPEND _probe_text "#include \"${_header}\"\n")
endforeach()
set(_probe "${BOOST_HEADERS_SCRATCH}/minimal_boost_headers_probe.cpp")
set(_depfile "${BOOST_HEADERS_SCRATCH}/minimal_boost_headers.d")
file(WRITE "${_probe}" "${_probe_text}")

# Step 2. Ask the compiler which headers the probe reads. -M reports all of
# them, system headers included. -MM would skip the vcpkg tree, because CMake
# passes that tree with -isystem.
set(_include_flags "")
foreach(_dir IN LISTS BOOST_HEADERS_INCLUDE_DIRS)
    if(_dir)
        list(APPEND _include_flags "-I${_dir}")
    endif()
endforeach()

execute_process(
    COMMAND "${BOOST_HEADERS_COMPILER}" ${BOOST_HEADERS_FLAGS} ${_include_flags}
            -M "${_probe}" -o "${_depfile}"
    RESULT_VARIABLE _scan_status
    ERROR_VARIABLE _scan_error)

if(NOT _scan_status EQUAL 0)
    message(FATAL_ERROR
        "install_minimal_boost_headers: the scan failed, so the install tree "
        "would get every vcpkg header or none of them.\n${_scan_error}")
endif()

# Step 3. Keep the headers under the vcpkg tree. The scan writes a makefile
# rule, so join the line continuations first. Escaped spaces get a placeholder,
# so that a path with a space in it survives the split.
file(READ "${_depfile}" _deps)
string(REGEX REPLACE "\\\\[\r\n]+" " " _deps "${_deps}")
string(REPLACE "\\ " "@BOOST_HEADERS_SPACE@" _deps "${_deps}")
string(REGEX REPLACE "[ \t\r\n]+" ";" _deps "${_deps}")

set(_keep "")
foreach(_dep IN LISTS _deps)
    string(REPLACE "@BOOST_HEADERS_SPACE@" " " _dep "${_dep}")
    # The rule starts with its target, which is not a file. Drop it here.
    if(_dep STREQUAL "" OR NOT EXISTS "${_dep}")
        continue()
    endif()
    get_filename_component(_dep "${_dep}" REALPATH)
    string(FIND "${_dep}" "${_root}/" _under_root)
    if(_under_root EQUAL 0)
        list(APPEND _keep "${_dep}")
    endif()
endforeach()

if(NOT _keep)
    message(FATAL_ERROR
        "install_minimal_boost_headers: the scan found no headers under "
        "${_root}. The include path is probably wrong.")
endif()
list(LENGTH _keep _scanned_count)

# Some headers pick their content by compiler, platform, or standard library.
# The scan sees only the choice this machine makes. Keep those directories
# whole, so a consumer on a different Xcode still finds the header it selects.
foreach(_glob IN LISTS BOOST_HEADERS_KEEP)
    file(GLOB_RECURSE _always "${_root}/${_glob}")
    list(APPEND _keep ${_always})
endforeach()

list(REMOVE_DUPLICATES _keep)
list(LENGTH _keep _total_count)

foreach(_file IN LISTS _keep)
    file(RELATIVE_PATH _relative "${_root}" "${_file}")
    get_filename_component(_relative_dir "${_relative}" DIRECTORY)
    file(COPY "${_file}" DESTINATION "${BOOST_HEADERS_DESTINATION}/${_relative_dir}")
endforeach()

message(STATUS
    "Installed ${_total_count} headers from ${_root} "
    "(${_scanned_count} reached by the public API).")
