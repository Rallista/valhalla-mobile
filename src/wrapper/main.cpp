
#include <valhalla/worker.h>
#include "main.h"
#include "valhalla_actor.h"

#ifdef __ANDROID__
// The Android JNI interface uses a different function signature.
#include <jni.h>
#include "jni_http_client.h"

#include <cstdint>
#include <cstdio>
#include <string>

namespace {

// Build the canonical `{"code": ..., "message": "..."}` JSON used across
// the wrapper so callers parse exceptions uniformly with successful payloads.
std::string error_json(int code, const std::string& message) {
    // Escape the bare minimum required for a JSON string literal — at this
    // layer message text comes from C++ exceptions, so we expect ASCII with
    // possible quotes/backslashes.
    std::string escaped;
    escaped.reserve(message.size());
    for (char c : message) {
        switch (c) {
            case '"': escaped += "\\\""; break;
            case '\\': escaped += "\\\\"; break;
            case '\b': escaped += "\\b"; break;
            case '\f': escaped += "\\f"; break;
            case '\n': escaped += "\\n"; break;
            case '\r': escaped += "\\r"; break;
            case '\t': escaped += "\\t"; break;
            default:
                if (static_cast<unsigned char>(c) < 0x20) {
                    char buf[8];
                    std::snprintf(buf, sizeof(buf), "\\u%04x", c);
                    escaped += buf;
                } else {
                    escaped += c;
                }
        }
    }
    return "{\"code\":" + std::to_string(code) + ",\"message\":\"" + escaped + "\"}";
}

ValhallaActor* actor_from_handle(jlong handle) {
    return reinterpret_cast<ValhallaActor*>(static_cast<uintptr_t>(handle));
}

} // namespace

extern "C"
JNIEXPORT jlong JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_nativeCreateActor(JNIEnv *env,
                                                            jobject /*thiz*/,
                                                            jstring jConfigPath,
                                                            jobject jHttpClient) {
    const char *config_path = env->GetStringUTFChars(jConfigPath, nullptr);
    if (config_path == nullptr) {
        // GetStringUTFChars returns null only on OOM; the JVM has already
        // raised OutOfMemoryError. Nothing more to do here.
        return 0;
    }

    // Build the JNI -> Kotlin HttpClient bridge before constructing the
    // actor. The actor takes ownership via its TileGetterWrapper as soon as
    // graph_reader is built. If the actor's constructor throws BEFORE the
    // wrapper is constructed (e.g. JSON config parse failure) the bridge
    // leaks; that path also fails the whole call so the leak is a one-off
    // transient cost.
    JniHttpClient* http_client = nullptr;
    if (jHttpClient != nullptr) {
        try {
            http_client = new JniHttpClient(env, jHttpClient);
        } catch (const std::exception &err) {
            printf("[ValhallaActor] failed to bind ValhallaHttpClient: %s\n", err.what());
            env->ReleaseStringUTFChars(jConfigPath, config_path);
            const std::string payload = error_json(
                -1,
                std::string("Failed to bind ValhallaHttpClient: ") + err.what());
            jclass cls = env->FindClass("java/lang/RuntimeException");
            if (cls != nullptr) {
                env->ThrowNew(cls, payload.c_str());
            }
            return 0;
        }
    }

    ValhallaActor* actor = nullptr;
    int error_code = -1;
    std::string error_message;

    try {
        actor = new ValhallaActor(config_path, http_client);
    } catch (const valhalla::valhalla_exception_t &err) {
        printf("[ValhallaActor] createActor valhalla_exception: %s\n", err.what());
        error_code = err.code;
        error_message = err.message;
    } catch (const std::exception &err) {
        printf("[ValhallaActor] createActor std::exception: %s\n", err.what());
        error_message = err.what();
    } catch (...) {
        printf("[ValhallaActor] createActor unknown exception\n");
        error_message = "unknown exception";
    }

    env->ReleaseStringUTFChars(jConfigPath, config_path);

    if (actor == nullptr) {
        // Surface the original error to Kotlin as a Java exception. The
        // ValhallaActor Kotlin class rewraps this into ValhallaException so
        // consumers see a single uniform exception type.
        const std::string payload = error_json(error_code, error_message);
        jclass cls = env->FindClass("java/lang/RuntimeException");
        if (cls != nullptr) {
            env->ThrowNew(cls, payload.c_str());
        }
        return 0;
    }

    return static_cast<jlong>(reinterpret_cast<uintptr_t>(actor));
}

extern "C"
JNIEXPORT void JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_nativeDestroyActor(JNIEnv * /*env*/,
                                                             jobject /*thiz*/,
                                                             jlong actorHandle) {
    delete actor_from_handle(actorHandle);
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_nativeRoute(JNIEnv *env,
                                                     jobject /*thiz*/,
                                                     jlong actorHandle,
                                                     jstring jRequest) {
    ValhallaActor* actor = actor_from_handle(actorHandle);
    std::string result;

    if (actor == nullptr) {
        result = error_json(-1, "Valhalla actor is not initialised");
        return env->NewStringUTF(result.c_str());
    }

    const char *request = env->GetStringUTFChars(jRequest, nullptr);
    if (request == nullptr) {
        result = error_json(-1, "Failed to read request string");
        return env->NewStringUTF(result.c_str());
    }

    try {
        result = actor->route(request);
    } catch (const valhalla::valhalla_exception_t &err) {
        printf("[ValhallaActor] route valhalla_exception: %s\n", err.what());
        result = error_json(err.code, err.message);
    } catch (const std::exception &err) {
        printf("[ValhallaActor] route std::exception: %s\n", err.what());
        result = error_json(-1, err.what());
    } catch (...) {
        printf("[ValhallaActor] route unknown exception\n");
        result = error_json(-1, "unknown exception");
    }

    env->ReleaseStringUTFChars(jRequest, request);
    return env->NewStringUTF(result.c_str());
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_nativeTraceAttributes(JNIEnv *env,
                                                                jobject /*thiz*/,
                                                                jlong actorHandle,
                                                                jstring jRequest) {
    ValhallaActor* actor = actor_from_handle(actorHandle);
    std::string result;

    if (actor == nullptr) {
        result = error_json(-1, "Valhalla actor is not initialised");
        return env->NewStringUTF(result.c_str());
    }

    const char *request = env->GetStringUTFChars(jRequest, nullptr);
    if (request == nullptr) {
        result = error_json(-1, "Failed to read request string");
        return env->NewStringUTF(result.c_str());
    }

    try {
        result = actor->trace_attributes(request);
    } catch (const valhalla::valhalla_exception_t &err) {
        printf("[ValhallaActor] trace_attributes valhalla_exception: %s\n", err.what());
        result = error_json(err.code, err.message);
    } catch (const std::exception &err) {
        printf("[ValhallaActor] trace_attributes std::exception: %s\n", err.what());
        result = error_json(-1, err.what());
    } catch (...) {
        printf("[ValhallaActor] trace_attributes unknown exception\n");
        result = error_json(-1, "unknown exception");
    }

    env->ReleaseStringUTFChars(jRequest, request);
    return env->NewStringUTF(result.c_str());
}

#elif __APPLE__
void* create_valhalla_actor(const char *config_path, ValhallaMobileHttpClient* http_client) {
    return new ValhallaActor(config_path, http_client);
}

void delete_valhalla_actor(void* actor) {
    delete ((ValhallaActor*) actor);
}

std::string route(const char *request, void* actor) {
    std::string result;
    try {
        result = ((ValhallaActor*) actor)->route(request);
    } catch (const valhalla::valhalla_exception_t &err) {
        printf("[ValhallaActor] route valhalla_exception: %s\n", err.what());
        std::string code = std::to_string(err.code);
        std::string message = err.message.c_str();

        result = "{\"code\":" + code + ",\"message\":\"" + message + "\"}";
    } catch (const std::exception &err) {
        printf("[ValhallaActor] route std::exception: %s\n", err.what());
        result = "{\"code\":-1,\"message\":\"" + std::string(err.what()) + "\"}";
    } catch (...) {
        printf("[ValhallaActor] route unknown exception");
        result = "{\"code\":-1,\"message\":\"unknown exception\"}";
    }

    return result;
}
#endif
