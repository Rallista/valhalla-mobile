#ifndef ValhallaWrapperHeader_h
#define ValhallaWrapperHeader_h

#import <Foundation/Foundation.h>

@class ValhallaWrapper;

@interface ValhallaWrapper : NSObject {}

- (instancetype)init;

- (NSString*)route:(NSString*)request configPath:(NSString*)config_path;

@end

#endif /* ValhallaWrapperHeader_h */
