#ifndef WRAPPER_H
#define WRAPPER_H

#include "valhalla_actor.h"

#ifdef __ANDROID__
#include <jni.h>


#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT jstring JNICALL Java_com_valhalla_valhalla_ValhallaKotlin_route(JNIEnv *env,
                                                jobject thiz,
                                                jstring jRequest,
                                                jstring jConfigPath);

#ifdef __cplusplus
}
#endif

#elif __APPLE__

std::string route(const char *request, void* actor);
void* create_valhalla_actor(const char *config_path);
void delete_valhalla_actor(void* actor);

#endif

#endif // WRAPPER_H
