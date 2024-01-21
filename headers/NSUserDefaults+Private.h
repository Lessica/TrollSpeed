#import <Foundation/Foundation.h>

@interface NSUserDefaults (Private)

- (instancetype)_initWithSuiteName:(NSString *)suiteName container:(NSURL *)container;

- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;

- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;

@end
