
#include <valhalla/worker.h>
#include "main.h"
#include "valhalla_actor.h"

#include <cstdint>
#include <cstdio>
#include <string>

#include <valhalla/baldr/rapidjson_utils.h>

// Build the JSON error payload.
//
// The message is not always ours. Valhalla copies caller-supplied text into it
// verbatim. An unrecognized action name becomes error 144 that carries that
// name (src/valhalla/src/worker.cc:1192, src/valhalla/src/exceptions.cc:172).
// A quote or a control character in the message makes a document the platform
// layer cannot parse, so the real error is lost behind a decode failure. The
// writer escapes the message, and it also builds the object, so no caller can
// write malformed JSON by hand.
//
// The code parameter is int64_t because valhalla_exception_t::code is
// unsigned, and the other two cases use -1.
static std::string error_json(int64_t code, const std::string& message) {
    rapidjson::writer_wrapper_t writer;

    writer.start_object();
    writer("code", code);
    writer("message", message);
    writer.end_object();

    return writer.get_buffer();
}

namespace {

/**
 * Runs one actor action, converting every C++ exception into the error envelope.
 *
 * No C++ exception may cross the JNI or Obj-C++ boundary, so all three catch
 * clauses are mandatory on every entry point — this wrapper is what keeps them
 * from drifting apart as actions are added.
 *
 * @param action_name  the action being run, used only for debug logging
 * @param action       callable producing the serialized response
 */
template <typename Action>
std::string invoke_action(const char* action_name, Action&& action) {
    try {
        return action();
    } catch (const valhalla::valhalla_exception_t &err) {
        printf("[ValhallaActor] %s valhalla_exception: %s\n", action_name, err.what());
        return error_json(static_cast<int64_t>(err.code), err.message);
    } catch (const std::exception &err) {
        printf("[ValhallaActor] %s std::exception: %s\n", action_name, err.what());
        return error_json(-1, err.what());
    } catch (...) {
        printf("[ValhallaActor] %s unknown exception\n", action_name);
        return error_json(-1, "unknown exception");
    }
}

// Pointer to one of the ValhallaActor action methods, all of which share a signature.
using ActorAction = std::string (ValhallaActor::*)(const std::string&);

} // namespace

#ifdef __ANDROID__
// The Android JNI interface uses a different function signature.
#include <jni.h>

namespace {

/**
 * Borrows a Java string's UTF-8 characters for the duration of a scope.
 *
 * Hand-written release calls are easy to skip on an early return, and the JNI
 * entry points below have several. Tying the release to scope exit also keeps
 * it correct if a future change lets something unwind out of the middle.
 */
class ScopedUtfChars {
public:
    ScopedUtfChars(JNIEnv* env, jstring value)
        : env(env), value(value), chars(env->GetStringUTFChars(value, nullptr)) {
    }

    ~ScopedUtfChars() {
        if (chars) {
            env->ReleaseStringUTFChars(value, chars);
        }
    }

    ScopedUtfChars(const ScopedUtfChars&) = delete;
    ScopedUtfChars& operator=(const ScopedUtfChars&) = delete;

    // Null when the JVM could not allocate the copy, in which case it has already
    // thrown OutOfMemoryError on this thread.
    const char* get() const {
        return chars;
    }

private:
    JNIEnv* env;
    jstring value;
    const char* chars;
};

/**
 * Shared body of every JNI entry point: read the Java strings, build an actor,
 * run one action against it, and hand the response back as a Java string.
 *
 * A null from either ScopedUtfChars means a pending OutOfMemoryError, which
 * would be thrown into Kotlin the moment we return, in place of the String this
 * method promises. It is cleared and reported through the envelope callers
 * already know how to handle.
 */
jstring run_jni_action(JNIEnv *env,
                       jstring jRequest,
                       jstring jConfigPath,
                       ActorAction action,
                       const char* action_name) {
    ScopedUtfChars request(env, jRequest);
    ScopedUtfChars config_path(env, jConfigPath);

    std::string result;
    if (request.get() == nullptr || config_path.get() == nullptr) {
        env->ExceptionClear();
        result = error_json(-1, std::string("failed to read the ") + action_name +
                                    " request from the JVM");
    } else {
        result = invoke_action(action_name, [&]() {
            // TODO: Android currently creates a new actor every time. Optimize to be like iOS later.
            ValhallaActor valhallaActor(config_path.get());
            return (valhallaActor.*action)(request.get());
        });
    }

    return env->NewStringUTF(result.c_str());
}

} // namespace

extern "C"
JNIEXPORT jstring

JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_route(JNIEnv *env,
                                                jobject thiz,
                                                jstring jRequest,
                                                jstring jConfigPath) {
    return run_jni_action(env, jRequest, jConfigPath, &ValhallaActor::route, "route");
}

extern "C"
JNIEXPORT jstring

JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_traceRoute(JNIEnv *env,
                                                     jobject thiz,
                                                     jstring jRequest,
                                                     jstring jConfigPath) {
    return run_jni_action(env, jRequest, jConfigPath, &ValhallaActor::trace_route, "trace_route");
}

extern "C"
JNIEXPORT jstring

JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_traceAttributes(JNIEnv *env,
                                                          jobject thiz,
                                                          jstring jRequest,
                                                          jstring jConfigPath) {
    return run_jni_action(env, jRequest, jConfigPath, &ValhallaActor::trace_attributes,
                          "trace_attributes");
}

#elif __APPLE__
void* create_valhalla_actor(const char *config_path, ValhallaMobileHttpClient* http_client) {
    return new ValhallaActor(config_path, http_client);
}

void delete_valhalla_actor(void* actor) {
    delete ((ValhallaActor*) actor);
}

std::string route(const char *request, void* actor) {
    return invoke_action("route", [&]() {
        return ((ValhallaActor*) actor)->route(request);
    });
}

std::string trace_route(const char *request, void* actor) {
    return invoke_action("trace_route", [&]() {
        return ((ValhallaActor*) actor)->trace_route(request);
    });
}

std::string trace_attributes(const char *request, void* actor) {
    return invoke_action("trace_attributes", [&]() {
        return ((ValhallaActor*) actor)->trace_attributes(request);
    });
}
#endif
