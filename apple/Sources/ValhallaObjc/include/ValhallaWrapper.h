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

/// Samples terrain heights under a shape, from the configured elevation tiles.
/// @param request a `height` request as JSON.
- (NSString*)height:(NSString*)request;

/// Computes a matrix of costs and times between every source and every target.
/// @param request a `sources_to_targets` request as JSON.
- (NSString*)matrix:(NSString*)request;

@end

#endif /* ValhallaWrapperHeader_h */
