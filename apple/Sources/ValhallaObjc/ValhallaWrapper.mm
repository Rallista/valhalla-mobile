#import "ValhallaWrapper.h"

#import <include/main.h>

@implementation ValhallaWrapper

- (instancetype)initWithConfigPath:(NSString*)config_path error:(__autoreleasing NSError **)error
{
    self = [super init];
    std::string path = std::string([config_path UTF8String]);
    try {
        _actor = create_valhalla_actor(path.c_str());
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
        // Convert the NSString to std::string
        std::string req = std::string([request UTF8String]);
        
        // Generate the valhalla response
        std::string res = route(req.c_str(), _actor);
        
        return [NSString stringWithUTF8String:res.c_str()];
    }
}

- (void) dealloc
{
    delete_valhalla_actor(_actor);
    _actor = nil;
}

@end
