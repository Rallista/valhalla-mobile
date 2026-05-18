#ifndef WRAPPER_H
#define WRAPPER_H

#include "valhalla_actor.h"

#ifdef __ANDROID__
#include <jni.h>


#ifdef __cplusplus
extern "C" {
#endif

// Persistent-actor lifecycle.
// Creating a ValhallaActor parses the config and opens the GraphReader
// (mmap'ing the tile_extract if configured), both of which are expensive.
// The Kotlin layer is expected to create one actor and reuse it across
// calls — see `ValhallaActor.kt`.

JNIEXPORT jlong JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_nativeCreateActor(JNIEnv *env,
                                                            jobject thiz,
                                                            jstring jConfigPath,
                                                            jobject jHttpClient);

JNIEXPORT void JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_nativeDestroyActor(JNIEnv *env,
                                                             jobject thiz,
                                                             jlong actorHandle);

JNIEXPORT jstring JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_nativeRoute(JNIEnv *env,
                                                     jobject thiz,
                                                     jlong actorHandle,
                                                     jstring jRequest);

JNIEXPORT jstring JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_nativeTraceAttributes(JNIEnv *env,
                                                                jobject thiz,
                                                                jlong actorHandle,
                                                                jstring jRequest);

#ifdef __cplusplus
}
#endif

#elif __APPLE__

std::string route(const char *request, void* actor);
void* create_valhalla_actor(const char *config_path, ValhallaMobileHttpClient* http_client = nullptr);
void delete_valhalla_actor(void* actor);

#endif

#endif // WRAPPER_H
