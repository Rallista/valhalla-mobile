#import "ValhallaWrapper.h"

#import <include/main.h>

@implementation ValhallaWrapper

- (instancetype)initWithConfigPath:(NSString*)config_path
{
    self = [super init];
    std::string path = std::string([config_path UTF8String]);
    _actor = create_valhalla_actor(path.c_str());
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
