#ifndef WRAPPER_H
#define WRAPPER_H

#include "valhalla_actor.h"

#ifdef __ANDROID__
#include <jni.h>


#ifdef __cplusplus
extern "C" {
#endif

// Android holds one native actor per Kotlin ValhallaActor, the way iOS holds one
// per ValhallaWrapper. createActor hands back an opaque handle that every action
// takes and deleteActor frees; 0 means the handle could not be allocated.
//
// jHttpClient is a com.valhalla.valhalla.http.ValhallaHttpClient used to fetch
// tiles when the config sets mjolnir.tile_url, and fills the role
// ValhallaMobileHttpClientImpl fills on iOS. Null turns tile fetching off.

JNIEXPORT jlong JNICALL Java_com_valhalla_valhalla_ValhallaKotlin_createActor(JNIEnv *env,
                                                jobject thiz,
                                                jstring jConfigPath,
                                                jobject jHttpClient);

JNIEXPORT void JNICALL Java_com_valhalla_valhalla_ValhallaKotlin_deleteActor(JNIEnv *env,
                                                jobject thiz,
                                                jlong handle);

JNIEXPORT jbyteArray JNICALL Java_com_valhalla_valhalla_ValhallaKotlin_route(JNIEnv *env,
                                                jobject thiz,
                                                jlong handle,
                                                jbyteArray jRequest);

JNIEXPORT jbyteArray JNICALL Java_com_valhalla_valhalla_ValhallaKotlin_traceRoute(JNIEnv *env,
                                                jobject thiz,
                                                jlong handle,
                                                jbyteArray jRequest);

JNIEXPORT jbyteArray JNICALL Java_com_valhalla_valhalla_ValhallaKotlin_traceAttributes(JNIEnv *env,
                                                jobject thiz,
                                                jlong handle,
                                                jbyteArray jRequest);

JNIEXPORT jbyteArray JNICALL Java_com_valhalla_valhalla_ValhallaKotlin_height(JNIEnv *env,
                                                jobject thiz,
                                                jlong handle,
                                                jbyteArray jRequest);

#ifdef __cplusplus
}
#endif

#elif __APPLE__

std::string route(const char *request, void* actor);
std::string trace_route(const char *request, void* actor);
std::string trace_attributes(const char *request, void* actor);
std::string height(const char *request, void* actor);
void* create_valhalla_actor(const char *config_path, ValhallaMobileHttpClient* http_client = nullptr);
void delete_valhalla_actor(void* actor);

#endif

#endif // WRAPPER_H
