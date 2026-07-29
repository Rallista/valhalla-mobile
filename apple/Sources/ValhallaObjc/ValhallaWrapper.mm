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

// Every action crosses the boundary the same way, and the actor is not
// thread-safe, so the @synchronized contract lives here once rather than
// being restated per action.
- (NSString*)invoke:(NSString*)request
             action:(std::string (*)(const char*, void*))action
{
    @synchronized(self) {
        std::string res = action([request UTF8String], _actor);

        // Not stringWithUTF8String:, which returns nil on invalid UTF-8 and
        // would trap: Swift imports these as non-optional String. Road names
        // come straight out of the graph tiles, so a corrupt tile pack is a
        // real source of bad bytes. This also skips a strlen over a response
        // that can run to megabytes.
        NSString* response = [[NSString alloc] initWithBytes:res.data()
                                                      length:res.size()
                                                    encoding:NSUTF8StringEncoding];

        return response ?: @"{\"code\":-1,\"message\":\"response was not valid UTF-8\"}";
    }
}

- (NSString*)route:(NSString*)request
{
    return [self invoke:request action:route];
}

- (NSString*)traceRoute:(NSString*)request
{
    return [self invoke:request action:trace_route];
}

- (NSString*)traceAttributes:(NSString*)request
{
    return [self invoke:request action:trace_attributes];
}

- (NSString*)height:(NSString*)request
{
    return [self invoke:request action:height];
}

- (void) dealloc
{
    delete_valhalla_actor(_actor);
    _actor = nil;
}

@end
