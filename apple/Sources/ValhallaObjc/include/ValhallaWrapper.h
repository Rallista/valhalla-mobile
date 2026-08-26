#ifndef ValhallaWrapperHeader_h
#define ValhallaWrapperHeader_h

#import <Foundation/Foundation.h>

@class ValhallaWrapper;

@interface ValhallaWrapper : NSObject {
    @private
    void* _actor;
}

- (instancetype)initWithConfigPath:(NSString*)config_path error:(__autoreleasing NSError **)error;

/// Releases the native actor, and with it the mmapped tile extract.
///
/// Safe to call more than once. Every action afterwards answers the wrapper's
/// error envelope rather than touching the freed actor — byte for byte what the
/// Android JNI layer answers for a call after close. `dealloc` calls this, so a
/// caller that never closes still frees the actor.
- (void)close;

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

@end

#endif /* ValhallaWrapperHeader_h */
