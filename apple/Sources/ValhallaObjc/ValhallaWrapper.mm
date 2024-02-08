#import "ValhallaWrapper.h"

#import <include/main.h>

@implementation ValhallaWrapper

- (instancetype)init
{
    self = [super init];
    return self;
}

- (NSString*)route:(NSString*)request configPath:(NSString*)config_path
{
    // Get the config path
    std::string path = std::string([config_path UTF8String]);
    std::string config_file(path);
    
    // Convert the NSString to std::string
    std::string req = std::string([request UTF8String]);
    
    // Generate the valhalla response
    std::string res = route(req.c_str(), path.c_str());
    
    return [NSString stringWithUTF8String:res.c_str()];
}

@end
