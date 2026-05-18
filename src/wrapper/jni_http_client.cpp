#ifdef __ANDROID__

#include "jni_http_client.h"

#include <stdexcept>
#include <string>
#include <vector>

namespace {

constexpr const char* kClientClassName = "com/valhalla/valhalla/http/ValhallaHttpClient";
constexpr const char* kGetResponseClassName =
    "com/valhalla/valhalla/http/ValhallaHttpClient$GetResponse";
constexpr const char* kHeadResponseClassName =
    "com/valhalla/valhalla/http/ValhallaHttpClient$HeadResponse";

constexpr const char* kGetSignature =
    "(Ljava/lang/String;JJ)Lcom/valhalla/valhalla/http/ValhallaHttpClient$GetResponse;";
constexpr const char* kHeadSignature =
    "(Ljava/lang/String;I)Lcom/valhalla/valhalla/http/ValhallaHttpClient$HeadResponse;";

// Resolve a Java class once and promote the local ref to a global. Throws on
// failure so that actor construction surfaces the problem to Kotlin via the
// existing exception path in `nativeCreateActor`.
jclass FindGlobalClassOrThrow(JNIEnv* env, const char* name) {
  jclass local = env->FindClass(name);
  if (local == nullptr) {
    env->ExceptionClear();
    throw std::runtime_error(std::string("JNI FindClass failed for ") + name);
  }
  jclass global = static_cast<jclass>(env->NewGlobalRef(local));
  env->DeleteLocalRef(local);
  if (global == nullptr) {
    throw std::runtime_error(std::string("NewGlobalRef failed for ") + name);
  }
  return global;
}

jmethodID GetMethodOrThrow(JNIEnv* env, jclass cls, const char* name, const char* sig) {
  jmethodID id = env->GetMethodID(cls, name, sig);
  if (id == nullptr) {
    env->ExceptionClear();
    throw std::runtime_error(std::string("GetMethodID failed for ") + name + sig);
  }
  return id;
}

} // namespace

JniHttpClient::JniHttpClient(JNIEnv* env, jobject kotlinClient) {
  if (env->GetJavaVM(&jvm_) != JNI_OK) {
    throw std::runtime_error("GetJavaVM failed");
  }

  client_global_ref_ = env->NewGlobalRef(kotlinClient);
  if (client_global_ref_ == nullptr) {
    throw std::runtime_error("NewGlobalRef for ValhallaHttpClient failed");
  }

  jclass client_cls = FindGlobalClassOrThrow(env, kClientClassName);
  // Resolve the interface methods then release the class ref — we only need
  // it to look up the method IDs, the IDs themselves are process-global.
  client_get_method_ = GetMethodOrThrow(env, client_cls, "get", kGetSignature);
  client_head_method_ = GetMethodOrThrow(env, client_cls, "head", kHeadSignature);
  env->DeleteGlobalRef(client_cls);

  get_response_class_ = FindGlobalClassOrThrow(env, kGetResponseClassName);
  get_response_success_ = GetMethodOrThrow(env, get_response_class_, "getSuccess", "()Z");
  get_response_http_code_ = GetMethodOrThrow(env, get_response_class_, "getHttpCode", "()I");
  get_response_body_ = GetMethodOrThrow(env, get_response_class_, "getBody", "()[B");

  head_response_class_ = FindGlobalClassOrThrow(env, kHeadResponseClassName);
  head_response_success_ = GetMethodOrThrow(env, head_response_class_, "getSuccess", "()Z");
  head_response_http_code_ = GetMethodOrThrow(env, head_response_class_, "getHttpCode", "()I");
  head_response_last_modified_ =
      GetMethodOrThrow(env, head_response_class_, "getLastModifiedTime", "()J");
}

JniHttpClient::~JniHttpClient() {
  if (jvm_ == nullptr) {
    return;
  }
  bool should_detach = false;
  JNIEnv* env = AttachIfNeeded(should_detach);
  if (env != nullptr) {
    if (client_global_ref_ != nullptr) {
      env->DeleteGlobalRef(client_global_ref_);
    }
    if (get_response_class_ != nullptr) {
      env->DeleteGlobalRef(get_response_class_);
    }
    if (head_response_class_ != nullptr) {
      env->DeleteGlobalRef(head_response_class_);
    }
  }
  DetachIfAttached(should_detach);
}

JNIEnv* JniHttpClient::AttachIfNeeded(bool& should_detach) const {
  should_detach = false;
  JNIEnv* env = nullptr;
  jint result = jvm_->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
  if (result == JNI_OK) {
    return env;
  }
  if (result == JNI_EDETACHED) {
    if (jvm_->AttachCurrentThread(&env, nullptr) == JNI_OK) {
      should_detach = true;
      return env;
    }
  }
  return nullptr;
}

void JniHttpClient::DetachIfAttached(bool should_detach) const {
  if (should_detach && jvm_ != nullptr) {
    jvm_->DetachCurrentThread();
  }
}

valhalla::baldr::tile_getter_t::GET_response_t
JniHttpClient::get(const std::string& url, uint64_t range_offset, uint64_t range_size) {
  using GET_response_t = valhalla::baldr::tile_getter_t::GET_response_t;
  using status_code_t = valhalla::baldr::tile_getter_t::status_code_t;

  GET_response_t failure;
  failure.status_ = status_code_t::FAILURE;

  bool should_detach = false;
  JNIEnv* env = AttachIfNeeded(should_detach);
  if (env == nullptr) {
    return failure;
  }

  // Reserve a small frame; we only create a handful of local refs per call.
  if (env->PushLocalFrame(8) != JNI_OK) {
    DetachIfAttached(should_detach);
    return failure;
  }

  GET_response_t result = failure;

  jstring jurl = env->NewStringUTF(url.c_str());
  if (jurl == nullptr || env->ExceptionCheck()) {
    env->ExceptionClear();
    env->PopLocalFrame(nullptr);
    DetachIfAttached(should_detach);
    return failure;
  }

  jobject response = env->CallObjectMethod(
      client_global_ref_, client_get_method_, jurl,
      static_cast<jlong>(range_offset), static_cast<jlong>(range_size));

  if (env->ExceptionCheck()) {
    // The Kotlin contract says don't throw. If a consumer breaks it, swallow
    // the exception here — propagating it into Valhalla's worker threads
    // would crash the process.
    env->ExceptionDescribe();
    env->ExceptionClear();
    env->PopLocalFrame(nullptr);
    DetachIfAttached(should_detach);
    return failure;
  }
  if (response == nullptr) {
    env->PopLocalFrame(nullptr);
    DetachIfAttached(should_detach);
    return failure;
  }

  const jboolean success = env->CallBooleanMethod(response, get_response_success_);
  const jint http_code = env->CallIntMethod(response, get_response_http_code_);
  result.http_code_ = static_cast<long>(http_code);

  if (success == JNI_TRUE) {
    jobject body_obj = env->CallObjectMethod(response, get_response_body_);
    if (body_obj != nullptr) {
      jbyteArray body = static_cast<jbyteArray>(body_obj);
      const jsize length = env->GetArrayLength(body);
      result.bytes_.resize(static_cast<size_t>(length));
      if (length > 0) {
        env->GetByteArrayRegion(
            body, 0, length, reinterpret_cast<jbyte*>(result.bytes_.data()));
      }
      result.status_ = status_code_t::SUCCESS;
    }
  }

  env->PopLocalFrame(nullptr);
  DetachIfAttached(should_detach);
  return result;
}

valhalla::baldr::tile_getter_t::HEAD_response_t
JniHttpClient::head(const std::string& url,
                    valhalla::baldr::tile_getter_t::header_mask_t header_mask) {
  using HEAD_response_t = valhalla::baldr::tile_getter_t::HEAD_response_t;
  using status_code_t = valhalla::baldr::tile_getter_t::status_code_t;

  HEAD_response_t failure;
  failure.status_ = status_code_t::FAILURE;

  bool should_detach = false;
  JNIEnv* env = AttachIfNeeded(should_detach);
  if (env == nullptr) {
    return failure;
  }

  if (env->PushLocalFrame(4) != JNI_OK) {
    DetachIfAttached(should_detach);
    return failure;
  }

  HEAD_response_t result = failure;

  jstring jurl = env->NewStringUTF(url.c_str());
  if (jurl == nullptr || env->ExceptionCheck()) {
    env->ExceptionClear();
    env->PopLocalFrame(nullptr);
    DetachIfAttached(should_detach);
    return failure;
  }

  jobject response = env->CallObjectMethod(
      client_global_ref_, client_head_method_, jurl, static_cast<jint>(header_mask));

  if (env->ExceptionCheck()) {
    env->ExceptionDescribe();
    env->ExceptionClear();
    env->PopLocalFrame(nullptr);
    DetachIfAttached(should_detach);
    return failure;
  }
  if (response == nullptr) {
    env->PopLocalFrame(nullptr);
    DetachIfAttached(should_detach);
    return failure;
  }

  const jboolean success = env->CallBooleanMethod(response, head_response_success_);
  const jint http_code = env->CallIntMethod(response, head_response_http_code_);
  result.http_code_ = static_cast<long>(http_code);

  if (success == JNI_TRUE) {
    const jlong last_modified = env->CallLongMethod(response, head_response_last_modified_);
    result.last_modified_time_ = static_cast<uint64_t>(last_modified);
    result.status_ = status_code_t::SUCCESS;
  }

  env->PopLocalFrame(nullptr);
  DetachIfAttached(should_detach);
  return result;
}

#endif // __ANDROID__
