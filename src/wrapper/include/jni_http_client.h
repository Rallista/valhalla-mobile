#ifndef JNI_HTTP_CLIENT_H
#define JNI_HTTP_CLIENT_H

#ifdef __ANDROID__

#include <jni.h>
#include <string>

#include "valhalla_actor.h"

/**
 * JNI bridge that lets Valhalla's GraphReader fetch tiles via a Kotlin
 * `ValhallaHttpClient` implementation. Constructed once at actor-creation
 * time, held by `TileGetterWrapper` (which deletes it on actor destruction).
 *
 * Implements the abstract `ValhallaMobileHttpClient` interface declared in
 * `valhalla_actor.h` so that the existing C++ wiring in `ValhallaActor` and
 * `TileGetterWrapper` works unchanged. Only the Android JNI entry point in
 * `main.cpp` knows how to construct this class.
 *
 * Thread-safety: Valhalla calls `get` / `head` from background worker
 * threads. Each invocation independently attaches the calling thread to the
 * JVM if needed and releases its local refs via a `PushLocalFrame` /
 * `PopLocalFrame` pair.
 */
class JniHttpClient : public ValhallaMobileHttpClient {
public:
  /**
   * @param env         JNIEnv on the thread that constructed the actor (used
   *                    once, here, to resolve class refs and method IDs).
   * @param kotlinClient Local ref to the Kotlin `ValhallaHttpClient` instance.
   *                     A JNI global ref is taken from it and kept for the
   *                     lifetime of this object.
   * @throws std::runtime_error if any required class / method cannot be
   *                            resolved or if the JavaVM cannot be retrieved.
   */
  JniHttpClient(JNIEnv* env, jobject kotlinClient);

  ~JniHttpClient() override;

  // Non-copyable, non-movable — owns JNI global refs.
  JniHttpClient(const JniHttpClient&) = delete;
  JniHttpClient& operator=(const JniHttpClient&) = delete;
  JniHttpClient(JniHttpClient&&) = delete;
  JniHttpClient& operator=(JniHttpClient&&) = delete;

  valhalla::baldr::tile_getter_t::GET_response_t
  get(const std::string& url, uint64_t range_offset = 0, uint64_t range_size = 0) override;

  valhalla::baldr::tile_getter_t::HEAD_response_t
  head(const std::string& url, valhalla::baldr::tile_getter_t::header_mask_t header_mask) override;

private:
  /**
   * Attach to the JVM if not already attached. Returns the JNIEnv* and sets
   * `should_detach` accordingly. The caller MUST pair a successful attach
   * with a corresponding detach via DetachIfAttached.
   */
  JNIEnv* AttachIfNeeded(bool& should_detach) const;
  void DetachIfAttached(bool should_detach) const;

  JavaVM* jvm_ = nullptr;
  // Global ref to the Kotlin ValhallaHttpClient instance.
  jobject client_global_ref_ = nullptr;

  // Cached method IDs (process-global lifetime, no ref needed).
  jmethodID client_get_method_ = nullptr;
  jmethodID client_head_method_ = nullptr;

  // Cached global class refs for the nested response types and their getters.
  jclass get_response_class_ = nullptr;
  jmethodID get_response_success_ = nullptr;
  jmethodID get_response_http_code_ = nullptr;
  jmethodID get_response_body_ = nullptr;

  jclass head_response_class_ = nullptr;
  jmethodID head_response_success_ = nullptr;
  jmethodID head_response_http_code_ = nullptr;
  jmethodID head_response_last_modified_ = nullptr;
};

#endif // __ANDROID__

#endif // JNI_HTTP_CLIENT_H
