
#include <valhalla/worker.h>
#include "main.h"
#include "valhalla_actor.h"

#include <cstdio>
#include <string>

namespace {

/**
 * Escapes a string so it can be embedded in a JSON string literal.
 *
 * Exception messages are not ours: they come from Valhalla and from the C++
 * runtime, and can carry quotes or backslashes — a config path echoed back by
 * `Cannot open file ...`, for instance. Concatenating one of those into a JSON
 * literal unescaped produces a payload the Swift and Kotlin decoders cannot
 * parse, turning a legible routing error into a decoding failure.
 */
std::string escape_json(const std::string& value) {
    std::string escaped;
    escaped.reserve(value.size());
    for (const char c : value) {
        switch (c) {
            case '"': escaped += "\\\""; break;
            case '\\': escaped += "\\\\"; break;
            case '\b': escaped += "\\b"; break;
            case '\f': escaped += "\\f"; break;
            case '\n': escaped += "\\n"; break;
            case '\r': escaped += "\\r"; break;
            case '\t': escaped += "\\t"; break;
            default:
                // Everything else below the space is a control character, which JSON
                // only permits in \u form. Bytes at or above 0x20 — including UTF-8
                // continuation bytes — pass through untouched.
                if (static_cast<unsigned char>(c) < 0x20) {
                    char buffer[7];
                    std::snprintf(buffer, sizeof(buffer), "\\u%04x", c);
                    escaped += buffer;
                } else {
                    escaped += c;
                }
        }
    }
    return escaped;
}

/**
 * Builds the error envelope every platform layer parses: `{"code":<int>,"message":"<string>"}`.
 *
 * @param code     Valhalla's error code, or -1 for failures raised outside Valhalla
 * @param message  human readable description of the failure
 */
std::string error_json(long long code, const std::string& message) {
    return "{\"code\":" + std::to_string(code) + ",\"message\":\"" + escape_json(message) + "\"}";
}

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
        return error_json(static_cast<long long>(err.code), err.message);
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
        // A pending OutOfMemoryError would be thrown into Kotlin the moment we
        // return, in place of the String this method promises. Clear it and
        // report through the envelope callers already know how to handle.
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
