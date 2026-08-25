#import "ValhallaWrapper.h"

#import <include/main.h>
#import <Foundation/Foundation.h>

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
            
            NSData* data = [NSURLConnection sendSynchronousRequest:request 
                                                  returningResponse:&httpResponse 
                                                              error:&error];
            
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
            
            [NSURLConnection sendSynchronousRequest:request 
                                  returningResponse:&httpResponse 
                                              error:&error];
            
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
NSString* PerformAction(ActorAction action, NSString* request, void* actor) {
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
        return PerformAction(&route, request, _actor);
    }
}

- (NSString*)traceRoute:(NSString*)request
{
    @synchronized(self) {
        return PerformAction(&trace_route, request, _actor);
    }
}

- (NSString*)traceAttributes:(NSString*)request
{
    @synchronized(self) {
        return PerformAction(&trace_attributes, request, _actor);
    }
}

- (NSString*)height:(NSString*)request
{
    @synchronized(self) {
        return PerformAction(&height, request, _actor);
    }
}

- (NSString*)matrix:(NSString*)request
{
    @synchronized(self) {
        return PerformAction(&matrix, request, _actor);
    }
}

- (void) dealloc
{
    delete_valhalla_actor(_actor);
    _actor = nil;
}

@end
