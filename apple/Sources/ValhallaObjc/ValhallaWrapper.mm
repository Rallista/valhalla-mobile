#import "ValhallaWrapper.h"

#import <include/main.h>
#import <Foundation/Foundation.h>

namespace {

/**
 * Runs one request to completion and hands back what it produced.
 *
 * Valhalla's tile getter is synchronous — it asks for a tile and expects the bytes back — so the
 * asynchronous session API is bridged with a semaphore rather than pushed up into the caller.
 *
 * Waiting here cannot deadlock: NSURLSession runs a completion handler on its own delegate queue,
 * never on the thread that resumed the task, so the thread being blocked is not the thread the
 * completion needs. It does block, though, which is why a routing action against a config with a
 * tile URL does not belong on the main thread.
 *
 * `sendSynchronousRequest:returningResponse:error:` did this before, and has been deprecated since
 * iOS 9.
 *
 * @param request       the request to run.
 * @param outResponse   set to the HTTP response, or nil if the request never got one.
 * @param outError      set to the transport error, if there was one.
 * @return              the response body, or nil.
 */
NSData* PerformSynchronously(NSURLRequest* request,
                             NSHTTPURLResponse* __strong * outResponse,
                             NSError* __strong * outError) {
    __block NSData* data = nil;
    __block NSURLResponse* response = nil;
    __block NSError* error = nil;

    dispatch_semaphore_t finished = dispatch_semaphore_create(0);

    NSURLSessionDataTask* task =
        [[NSURLSession sharedSession] dataTaskWithRequest:request
                                       completionHandler:^(NSData* taskData,
                                                           NSURLResponse* taskResponse,
                                                           NSError* taskError) {
            data = taskData;
            response = taskResponse;
            error = taskError;
            dispatch_semaphore_signal(finished);
        }];
    [task resume];
    dispatch_semaphore_wait(finished, DISPATCH_TIME_FOREVER);

    // A non-HTTP response cannot carry a status code, so it is treated as no response at all.
    *outResponse = [response isKindOfClass:[NSHTTPURLResponse class]]
                       ? (NSHTTPURLResponse*)response
                       : nil;
    *outError = error;

    return data;
}

} // namespace

/**
 * iOS implementation of ValhallaMobileHttpClient using NSMutableURLRequest
 */
class ValhallaMobileHttpClientImpl : public ValhallaMobileHttpClient {
public:
    valhalla::baldr::tile_getter_t::GET_response_t 
    get(const std::string& url, uint64_t range_offset = 0, uint64_t range_size = 0) override {
        valhalla::baldr::tile_getter_t::GET_response_t response;
        
        @autoreleasepool {
            NSString* urlString = [NSString stringWithUTF8String:url.c_str()];
            NSURL* nsurl = [NSURL URLWithString:urlString];
            
            if (!nsurl) {
                response.status_ = valhalla::baldr::tile_getter_t::status_code_t::FAILURE;
                response.http_code_ = 0;
                return response;
            }
            
            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsurl];
            request.HTTPMethod = @"GET";
            request.timeoutInterval = 10;
            
            // Set range header if needed
            if (range_size > 0) {
                NSString* rangeHeader = [NSString stringWithFormat:@"bytes=%llu-%llu", 
                                                  range_offset, range_offset + range_size - 1];
                [request setValue:rangeHeader forHTTPHeaderField:@"Range"];
            }
            
            NSHTTPURLResponse* httpResponse = nil;
            NSError* error = nil;
            
            NSData* data = PerformSynchronously(request, &httpResponse, &error);
            
            if (error || !httpResponse) {
                response.status_ = valhalla::baldr::tile_getter_t::status_code_t::FAILURE;
                response.http_code_ = httpResponse ? httpResponse.statusCode : 0;
                return response;
            }
            
            response.http_code_ = httpResponse.statusCode;
            
            if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                // Copy data to response bytes
                if (data) {
                    const char* dataBytes = static_cast<const char*>(data.bytes);
                    response.bytes_.assign(dataBytes, dataBytes + data.length);
                }
                response.status_ = valhalla::baldr::tile_getter_t::status_code_t::SUCCESS;
            } else {
                response.status_ = valhalla::baldr::tile_getter_t::status_code_t::FAILURE;
            }
        }
        
        return response;
    }
    
    valhalla::baldr::tile_getter_t::HEAD_response_t 
    head(const std::string& url, valhalla::baldr::tile_getter_t::header_mask_t header_mask) override {
        valhalla::baldr::tile_getter_t::HEAD_response_t response;
        
        @autoreleasepool {
            NSString* urlString = [NSString stringWithUTF8String:url.c_str()];
            NSURL* nsurl = [NSURL URLWithString:urlString];
            
            if (!nsurl) {
                response.status_ = valhalla::baldr::tile_getter_t::status_code_t::FAILURE;
                response.http_code_ = 0;
                return response;
            }
            
            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsurl];
            request.HTTPMethod = @"HEAD";
            request.timeoutInterval = 10;
            
            NSHTTPURLResponse* httpResponse = nil;
            NSError* error = nil;
            
            PerformSynchronously(request, &httpResponse, &error);
            
            if (error || !httpResponse) {
                response.status_ = valhalla::baldr::tile_getter_t::status_code_t::FAILURE;
                response.http_code_ = httpResponse ? httpResponse.statusCode : 0;
                return response;
            }
            
            response.http_code_ = httpResponse.statusCode;
            
            if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                response.status_ = valhalla::baldr::tile_getter_t::status_code_t::SUCCESS;
                
                // Extract Last-Modified header if requested
                if (header_mask & valhalla::baldr::tile_getter_t::kHeaderLastModified) {
                    NSString* lastModified = [httpResponse valueForHTTPHeaderField:@"Last-Modified"];
                    if (lastModified) {
                        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
                        formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss zzz";
                        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                        NSDate* date = [formatter dateFromString:lastModified];
                        response.last_modified_time_ = (uint64_t)[date timeIntervalSince1970];
                    } else {
                        response.last_modified_time_ = 0;
                    }
                }
            } else {
                response.status_ = valhalla::baldr::tile_getter_t::status_code_t::FAILURE;
            }
        }
        
        return response;
    }
};


namespace {

/// One of the actor entry points in `main.h`. They all take a request and an actor,
/// and they all answer with either a serialized response or the wrapper's error
/// envelope — they never throw.
using ActorAction = std::string (*)(const char*, void*);

/// Shared body of every action method: hand the request to the C++ wrapper and
/// bridge the response back. Callers hold the lock; this does not.
///
/// A null actor means the caller ran an action after `close`. Swift guards that
/// case first, so reaching here is a bug rather than ordinary use — but the
/// wrapper still has to answer something instead of dereferencing null, and the
/// envelope it answers matches the Android JNI layer's wording exactly.
NSString* PerformAction(ActorAction action,
                        NSString* request,
                        void* actor,
                        const char* action_name) {
    if (actor == nullptr) {
        return [NSString stringWithFormat:
                @"{\"code\":-1,\"message\":\"the actor is closed, cannot run %s\"}",
                action_name];
    }

    std::string result = action([request UTF8String], actor);

    // Swift imports this return as implicitly unwrapped, so a nil would trap in
    // the host app. Invalid UTF-8 answers the wrapper's error envelope instead.
    NSString* response = [[NSString alloc] initWithBytes:result.data()
                                                  length:result.size()
                                                encoding:NSUTF8StringEncoding];

    return response ?: @"{\"code\":-1,\"message\":\"response was not valid UTF-8\"}";
}

} // namespace


@implementation ValhallaWrapper

- (instancetype)initWithConfigPath:(NSString*)config_path error:(__autoreleasing NSError **)error
{
    self = [super init];
    std::string path = std::string([config_path UTF8String]);
    try {
        // Create the network interface implementation for iOS
        ValhallaMobileHttpClient* httpClient = new ValhallaMobileHttpClientImpl();
        _actor = create_valhalla_actor(path.c_str(), httpClient);
    } catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:@{
            NSUnderlyingErrorKey: exception,
            NSLocalizedDescriptionKey: exception.reason,
            @"CallStackSymbols": exception.callStackSymbols
        }];
        return nil;
    } catch (const std::exception &err) {
        *error = [[NSError alloc] initWithDomain: [NSString stringWithUTF8String:err.what()] code:-1 userInfo: nil];
        return nil;
    } catch (...) {
        *error = [[NSError alloc] initWithDomain: @"unknown exception" code:-1 userInfo: nil];
        return nil;
    }
    return self;
}

- (NSString*)route:(NSString*)request
{
    @synchronized(self) {
        return PerformAction(&route, request, _actor, "route");
    }
}

- (NSString*)traceRoute:(NSString*)request
{
    @synchronized(self) {
        return PerformAction(&trace_route, request, _actor, "trace_route");
    }
}

- (NSString*)traceAttributes:(NSString*)request
{
    @synchronized(self) {
        return PerformAction(&trace_attributes, request, _actor, "trace_attributes");
    }
}

- (NSString*)height:(NSString*)request
{
    @synchronized(self) {
        return PerformAction(&height, request, _actor, "height");
    }
}

- (void)close
{
    // The same lock every action takes, so a close cannot free the actor out from
    // under a request that is already running on another thread.
    @synchronized(self) {
        // Deleting null is well defined, so a double close is harmless.
        delete_valhalla_actor(_actor);
        _actor = nil;
    }
}

- (void) dealloc
{
    [self close];
}

@end
