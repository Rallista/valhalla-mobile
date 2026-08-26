
#include <valhalla/worker.h>
#include "main.h"
#include "valhalla_actor.h"

#include <cstdint>
#include <cstdio>
#include <memory>
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
 * Resolves a JNIEnv for the calling thread, attaching it if the JVM does not know it yet and
 * detaching again on scope exit.
 *
 * Valhalla runs the tile getter on whichever thread called the action, and that thread came from
 * Kotlin, so it is normally attached already — in which case nothing is attached or detached here.
 * The attach path exists because GraphReader is free to fetch from a thread of its own, and
 * calling into the JVM from an unattached thread is undefined behaviour.
 */
class ScopedEnv {
public:
    explicit ScopedEnv(JavaVM* vm) : vm(vm) {
        if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) == JNI_OK) {
            return;
        }
        if (vm->AttachCurrentThread(&env, nullptr) == JNI_OK) {
            attached = true;
        } else {
            env = nullptr;
        }
    }

    ~ScopedEnv() {
        if (attached) {
            vm->DetachCurrentThread();
        }
    }

    ScopedEnv(const ScopedEnv&) = delete;
    ScopedEnv& operator=(const ScopedEnv&) = delete;

    JNIEnv* get() const {
        return env;
    }

private:
    JavaVM* vm;
    JNIEnv* env = nullptr;
    bool attached = false;
};

/**
 * Frees every local reference made inside the scope.
 *
 * A tile fetch makes several, and the JVM only reclaims them automatically when a native method
 * returns to Java. These calls run the other way round — C++ into Java and back — so without this
 * the references accumulate for as long as routing continues and eventually overflow the local
 * reference table.
 */
class ScopedLocalFrame {
public:
    explicit ScopedLocalFrame(JNIEnv* env) : env(env) {
        if (env->PushLocalFrame(kCapacity) == 0) {
            pushed = true;
        } else {
            env->ExceptionClear();
        }
    }

    ~ScopedLocalFrame() {
        if (pushed) {
            env->PopLocalFrame(nullptr);
        }
    }

    ScopedLocalFrame(const ScopedLocalFrame&) = delete;
    ScopedLocalFrame& operator=(const ScopedLocalFrame&) = delete;

    bool entered() const {
        return pushed;
    }

private:
    static constexpr jint kCapacity = 8;

    JNIEnv* env;
    bool pushed = false;
};

/// The Kotlin client object plus the ids needed to call it. Borrowed by every JniHttpClient;
/// owned by the JniHttpClientFactory that outlives them.
struct JniHttpBinding {
    JavaVM* vm = nullptr;
    jobject client = nullptr;
    jmethodID get = nullptr;
    jmethodID head = nullptr;
    jfieldID success = nullptr;
    jfieldID http_code = nullptr;
    jfieldID last_modified = nullptr;
    jfieldID body = nullptr;
};

/**
 * Runs tile fetches by calling back into Kotlin's ValhallaHttpClient.
 *
 * The Android counterpart of ValhallaMobileHttpClientImpl in ValhallaWrapper.mm. Only the
 * transport differs: iOS talks to NSURLConnection directly from Obj-C++, and here the request
 * crosses back into the JVM.
 *
 * Holds the binding by pointer rather than owning it. ValhallaActor takes ownership of the client
 * it is given and frees it when the config turns out to have no tile_url, and the actor is rebuilt
 * on the deferred-construction path — so a client cannot own anything that must survive one actor.
 * JniHttpClientFactory owns the global reference instead, and outlives every client it makes.
 *
 * Neither entry point lets an exception escape: Kotlin's client catches its own, and anything
 * still pending afterwards (an OutOfMemoryError, a class that failed to initialise) is cleared and
 * reported as a failed fetch. Letting one stay pending would corrupt the next JNI call.
 */
class JniHttpClient : public ValhallaMobileHttpClient {
public:
    explicit JniHttpClient(const JniHttpBinding* binding) : binding(binding) {
    }

    valhalla::baldr::tile_getter_t::GET_response_t
    get(const std::string& url, uint64_t range_offset = 0, uint64_t range_size = 0) override {
        valhalla::baldr::tile_getter_t::GET_response_t response;
        response.status_ = valhalla::baldr::tile_getter_t::status_code_t::FAILURE;

        ScopedEnv env(binding->vm);
        if (env.get() == nullptr) {
            return response;
        }

        ScopedLocalFrame frame(env.get());
        if (!frame.entered()) {
            return response;
        }

        jstring j_url = env.get()->NewStringUTF(url.c_str());
        if (j_url == nullptr) {
            env.get()->ExceptionClear();
            return response;
        }

        jobject result = env.get()->CallObjectMethod(binding->client, binding->get, j_url,
                                                     static_cast<jlong>(range_offset),
                                                     static_cast<jlong>(range_size));
        if (!completed(env.get(), result)) {
            return response;
        }

        response.http_code_ = env.get()->GetIntField(result, binding->http_code);
        if (env.get()->GetBooleanField(result, binding->success) == JNI_TRUE) {
            auto body = static_cast<jbyteArray>(env.get()->GetObjectField(result, binding->body));
            if (body != nullptr) {
                const jsize length = env.get()->GetArrayLength(body);
                response.bytes_.resize(static_cast<size_t>(length));
                env.get()->GetByteArrayRegion(body, 0, length,
                                              reinterpret_cast<jbyte*>(response.bytes_.data()));
            }
            response.status_ = valhalla::baldr::tile_getter_t::status_code_t::SUCCESS;
        }

        return response;
    }

    valhalla::baldr::tile_getter_t::HEAD_response_t
    head(const std::string& url,
         valhalla::baldr::tile_getter_t::header_mask_t header_mask) override {
        valhalla::baldr::tile_getter_t::HEAD_response_t response;
        response.status_ = valhalla::baldr::tile_getter_t::status_code_t::FAILURE;

        ScopedEnv env(binding->vm);
        if (env.get() == nullptr) {
            return response;
        }

        ScopedLocalFrame frame(env.get());
        if (!frame.entered()) {
            return response;
        }

        jstring j_url = env.get()->NewStringUTF(url.c_str());
        if (j_url == nullptr) {
            env.get()->ExceptionClear();
            return response;
        }

        jobject result = env.get()->CallObjectMethod(binding->client, binding->head, j_url,
                                                     static_cast<jint>(header_mask));
        if (!completed(env.get(), result)) {
            return response;
        }

        response.http_code_ = env.get()->GetIntField(result, binding->http_code);
        if (env.get()->GetBooleanField(result, binding->success) == JNI_TRUE) {
            response.last_modified_time_ =
                static_cast<uint64_t>(env.get()->GetLongField(result, binding->last_modified));
            response.status_ = valhalla::baldr::tile_getter_t::status_code_t::SUCCESS;
        }

        return response;
    }

private:
    /**
     * Whether a call into Kotlin produced a usable result.
     *
     * Clears anything pending, because a JNI call made while an exception is pending is undefined
     * behaviour, and the next tile fetch would make one.
     */
    static bool completed(JNIEnv* env, jobject result) {
        if (env->ExceptionCheck() == JNI_TRUE) {
            env->ExceptionDescribe();
            env->ExceptionClear();
            return false;
        }
        return result != nullptr;
    }

    const JniHttpBinding* binding;
};

/**
 * Owns the global reference to the Kotlin client, and mints a fresh JniHttpClient for each actor
 * build.
 *
 * The local reference createActor is handed dies when that call returns, so it is promoted to a
 * global one here and released when the handle is deleted. Field and method ids are looked up once
 * and cached — they stay valid as long as the class is not unloaded, and the class is reachable
 * from the referenced object, so it cannot be.
 */
class JniHttpClientFactory {
public:
    /**
     * @param env     the environment of the thread calling createActor.
     * @param client  a Kotlin ValhallaHttpClient. May be null, for a caller that wants no fetching.
     * @return        the factory, or nullptr when the JNI plumbing could not be set up, in which
     *                case the actor is built without a client and behaves as it did before.
     */
    static std::unique_ptr<JniHttpClientFactory> create(JNIEnv* env, jobject client) {
        if (client == nullptr) {
            return nullptr;
        }

        JniHttpBinding binding;
        if (env->GetJavaVM(&binding.vm) != JNI_OK || binding.vm == nullptr) {
            return nullptr;
        }

        jclass client_class = env->GetObjectClass(client);
        jclass response_class = env->FindClass("com/valhalla/valhalla/http/ValhallaHttpResponse");
        if (client_class == nullptr || response_class == nullptr) {
            env->ExceptionClear();
            return nullptr;
        }

        binding.get =
            env->GetMethodID(client_class, "get",
                             "(Ljava/lang/String;JJ)Lcom/valhalla/valhalla/http/ValhallaHttpResponse;");
        binding.head =
            env->GetMethodID(client_class, "head",
                             "(Ljava/lang/String;I)Lcom/valhalla/valhalla/http/ValhallaHttpResponse;");
        binding.success = env->GetFieldID(response_class, "success", "Z");
        binding.http_code = env->GetFieldID(response_class, "httpCode", "I");
        binding.last_modified = env->GetFieldID(response_class, "lastModified", "J");
        binding.body = env->GetFieldID(response_class, "body", "[B");

        if (binding.get == nullptr || binding.head == nullptr || binding.success == nullptr ||
            binding.http_code == nullptr || binding.last_modified == nullptr ||
            binding.body == nullptr) {
            env->ExceptionClear();
            return nullptr;
        }

        binding.client = env->NewGlobalRef(client);
        if (binding.client == nullptr) {
            env->ExceptionClear();
            return nullptr;
        }

        return std::unique_ptr<JniHttpClientFactory>(new JniHttpClientFactory(binding));
    }

    ~JniHttpClientFactory() {
        // Deleting the handle can happen on a thread other than the one that built it, so the
        // environment is resolved the same way as for a request.
        ScopedEnv env(binding.vm);
        if (env.get() != nullptr) {
            env.get()->DeleteGlobalRef(binding.client);
        }
    }

    JniHttpClientFactory(const JniHttpClientFactory&) = delete;
    JniHttpClientFactory& operator=(const JniHttpClientFactory&) = delete;

    /// A client for one actor. ValhallaActor takes ownership of it.
    JniHttpClient* new_client() const {
        return new JniHttpClient(&binding);
    }

private:
    explicit JniHttpClientFactory(const JniHttpBinding& binding) : binding(binding) {
    }

    JniHttpBinding binding;
};

/**
 * Owns the actor for the lifetime of one Kotlin ValhallaActor.
 *
 * Building an actor parses the config and opens the GraphReader, which mmaps the
 * tile extract — far too expensive to repeat per request, which is what this
 * layer used to do. createActor builds it up front so the config file is read
 * before anything else can overwrite it; the default ValhallaConfigManager writes
 * every config to one fixed valhalla.json, so a second instance clobbers the
 * first's config, and a later read would pick up the wrong one.
 *
 * A build that fails leaves the pointer null and the next call tries again, which
 * keeps a config that cannot be read reporting through the error envelope on every
 * call rather than failing construction, and lets an instance created before its
 * tiles finished downloading recover on a later call.
 *
 * Kotlin serialises every call on one instance, so no lock is needed here. See
 * ValhallaActor.kt.
 */
struct ActorHandle {
    ActorHandle(std::string config_path, std::unique_ptr<JniHttpClientFactory> http_clients)
        : config_path(std::move(config_path)), http_clients(std::move(http_clients)) {
    }

    /// A client for the next actor build, or null when there is no factory. Ownership passes to
    /// the actor, which is why a new one is minted for every attempt rather than reused.
    ValhallaMobileHttpClient* new_http_client() const {
        return http_clients ? http_clients->new_client() : nullptr;
    }

    std::string config_path;

    // Declared before `actor` so it is destroyed after it: the actor's client borrows the
    // factory's global reference, and must not outlive it.
    std::unique_ptr<JniHttpClientFactory> http_clients;
    std::unique_ptr<ValhallaActor> actor;
};

std::string copy_bytes(JNIEnv* env, jbyteArray array) {
    std::string bytes(static_cast<size_t>(env->GetArrayLength(array)), '\0');
    env->GetByteArrayRegion(array, 0, static_cast<jsize>(bytes.size()),
                            reinterpret_cast<jbyte*>(bytes.data()));
    return bytes;
}

/**
 * Shared body of every JNI action: read the request, run one action against the
 * handle's actor, and hand the response back.
 *
 * Requests and responses cross as UTF-8 bytes, not Java strings: JNI strings are
 * Modified UTF-8, which cannot carry a character outside the BMP or a binary
 * `format: pbf` response. Kotlin does the decoding. A zero handle means Kotlin
 * called after close, which its own guard should have caught.
 */
jbyteArray run_jni_action(JNIEnv *env,
                          jlong handle,
                          jbyteArray jRequest,
                          ActorAction action,
                          const char* action_name) {
    std::string result;
    if (handle == 0) {
        result = error_json(-1, std::string("the actor is closed, cannot run ") + action_name);
    } else {
        auto* actor_handle = reinterpret_cast<ActorHandle*>(handle);
        result = invoke_action(action_name, [&]() {
            // Copied inside invoke_action so a bad_alloc becomes the envelope.
            const std::string request = copy_bytes(env, jRequest);
            // Normally already built by createActor; this is the retry path.
            if (!actor_handle->actor) {
                actor_handle->actor = std::make_unique<ValhallaActor>(
                    actor_handle->config_path, actor_handle->new_http_client());
            }
            return ((*actor_handle->actor).*action)(request);
        });
    }

    // Null only when the JVM could not allocate, with OutOfMemoryError already pending.
    jbyteArray response = env->NewByteArray(static_cast<jsize>(result.size()));
    if (response != nullptr) {
        env->SetByteArrayRegion(response, 0, static_cast<jsize>(result.size()),
                                reinterpret_cast<const jbyte*>(result.data()));
    }
    return response;
}

} // namespace

extern "C"
JNIEXPORT jlong

JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_createActor(JNIEnv *env,
                                                       jobject thiz,
                                                       jstring jConfigPath,
                                                       jobject jHttpClient) {
    ScopedUtfChars config_path(env, jConfigPath);
    if (config_path.get() == nullptr) {
        env->ExceptionClear();
        return 0;
    }

    // A null factory is not fatal. The actor is then built without a client, which is exactly how
    // Android behaved before it had one: a config with no tile_url is unaffected, and one with a
    // tile_url reports every fetch as a failure.
    std::unique_ptr<JniHttpClientFactory> http_clients = JniHttpClientFactory::create(env, jHttpClient);
    if (jHttpClient != nullptr && !http_clients) {
        printf("[ValhallaActor] createActor could not bind the HTTP client; tile fetching is off\n");
    }

    // Returning 0 lets Kotlin raise a typed error instead of taking a C++
    // exception across the boundary.
    std::unique_ptr<ActorHandle> handle;
    try {
        handle = std::make_unique<ActorHandle>(config_path.get(), std::move(http_clients));
    } catch (...) {
        printf("[ValhallaActor] createActor failed to allocate the handle\n");
        return 0;
    }
    try {
        handle->actor = std::make_unique<ValhallaActor>(handle->config_path,
                                                       handle->new_http_client());
    } catch (const std::exception &err) {
        printf("[ValhallaActor] createActor deferred, will retry on first use: %s\n", err.what());
    } catch (...) {
        printf("[ValhallaActor] createActor deferred, will retry on first use\n");
    }

    return reinterpret_cast<jlong>(handle.release());
}

extern "C"
JNIEXPORT void

JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_deleteActor(JNIEnv *env,
                                                        jobject thiz,
                                                        jlong handle) {
    // Deleting null is well defined, so a double close from Kotlin is harmless.
    delete reinterpret_cast<ActorHandle*>(handle);
}

extern "C"
JNIEXPORT jbyteArray

JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_route(JNIEnv *env,
                                                      jobject thiz,
                                                      jlong handle,
                                                      jbyteArray jRequest) {
    return run_jni_action(env, handle, jRequest, &ValhallaActor::route, "route");
}

extern "C"
JNIEXPORT jbyteArray

JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_traceRoute(JNIEnv *env,
                                                           jobject thiz,
                                                           jlong handle,
                                                           jbyteArray jRequest) {
    return run_jni_action(env, handle, jRequest, &ValhallaActor::trace_route, "trace_route");
}

extern "C"
JNIEXPORT jbyteArray

JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_traceAttributes(JNIEnv *env,
                                                                jobject thiz,
                                                                jlong handle,
                                                                jbyteArray jRequest) {
    return run_jni_action(env, handle, jRequest, &ValhallaActor::trace_attributes,
                          "trace_attributes");
}

extern "C"
JNIEXPORT jbyteArray

JNICALL
Java_com_valhalla_valhalla_ValhallaKotlin_height(JNIEnv *env,
                                                       jobject thiz,
                                                       jlong handle,
                                                       jbyteArray jRequest) {
    return run_jni_action(env, handle, jRequest, &ValhallaActor::height, "height");
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

std::string height(const char *request, void* actor) {
    return invoke_action("height", [&]() {
        return ((ValhallaActor*) actor)->height(request);
    });
}
#endif
