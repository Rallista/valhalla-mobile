
#include <valhalla/worker.h>
#include "main.h"
#include "valhalla_actor.h"

#include <cstdint>
#include <cstdio>
#include <string>

// rapidjson_fwd.h first, as valhalla does. It sets the rapidjson macros that
// the rest of the build uses.
#include <valhalla/baldr/rapidjson_fwd.h>
#include <rapidjson/stringbuffer.h>
#include <rapidjson/writer.h>

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
    rapidjson::StringBuffer buffer;
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);

    writer.StartObject();
    writer.Key("code");
    writer.Int64(code);
    writer.Key("message");
    writer.String(message.data(), static_cast<rapidjson::SizeType>(message.size()));
    writer.EndObject();

    return std::string(buffer.GetString(), buffer.GetSize());
}

#ifdef __ANDROID__
// The Android JNI interface uses a different function signature.
#include <jni.h>

extern "C"
JNIEXPORT jstring

JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_route(JNIEnv *env,
                                                jobject thiz,
                                                jstring jRequest,
                                                jstring jConfigPath) {
    
    const char *request = env->GetStringUTFChars(jRequest, 0);
    const char *config_path = env->GetStringUTFChars(jConfigPath, 0);

    std::string result;
    try {
        // TODO: Android currently creates a new actor every time. Optimize to be like iOS later.
        ValhallaActor valhallaActor(config_path);
        result = valhallaActor.route(request);
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
    env->ReleaseStringUTFChars(jConfigPath, config_path);

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
        result = error_json(err.code, err.message);
    } catch (const std::exception &err) {
        printf("[ValhallaActor] route std::exception: %s\n", err.what());
        result = error_json(-1, err.what());
    } catch (...) {
        printf("[ValhallaActor] route unknown exception\n");
        result = error_json(-1, "unknown exception");
    }

    return result;
}
#endif
