#ifndef ValhallaWrapperHeader_h
#define ValhallaWrapperHeader_h

#import <Foundation/Foundation.h>

@class ValhallaWrapper;

@interface ValhallaWrapper : NSObject {
    @private
    void* _actor;
}

- (instancetype)initWithConfigPath:(NSString*)config_path error:(__autoreleasing NSError **)error;

- (NSString*)route:(NSString*)request;

/// Map-matches a GPS trace and returns a route along the matched path.
/// @param request a `trace_route` request as JSON.
- (NSString*)traceRoute:(NSString*)request;

/// Map-matches a GPS trace and returns the attributes of every edge along the matched path.
/// @param request a `trace_attributes` request as JSON.
- (NSString*)traceAttributes:(NSString*)request;

@end

#endif /* ValhallaWrapperHeader_h */
