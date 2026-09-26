#ifndef ValhallaWrapperHeader_h
#define ValhallaWrapperHeader_h

#import <Foundation/Foundation.h>

@class ValhallaWrapper;

@interface ValhallaWrapper : NSObject {
    @private
    void* _actor;
    /// std::atomic<bool>*, owned here and freed in dealloc. See `cancel`.
    void* _cancelFlag;
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

/// Asks the action running now to stop, before its next tile fetch or during its path search.
/// Sticky until `resume`.
- (void)cancel;

/// Clears a previous `cancel` so further actions can run.
- (void)resume;

/// Computes a matrix of costs and times between every source and every target.
/// @param request a `sources_to_targets` request as JSON.
- (NSString*)matrix:(NSString*)request;

@end

#endif /* ValhallaWrapperHeader_h */
