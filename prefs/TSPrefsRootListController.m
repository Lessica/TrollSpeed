#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>

#import <libroot.h>

#import "TSPrefsRootListController.h"

@implementation TSPrefsRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *path = [NSString
        stringWithFormat:JBROOT_PATH_NSSTRING(@"/var/mobile/Library/Preferences/%@.plist"), specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *path = [NSString
        stringWithFormat:JBROOT_PATH_NSSTRING(@"/var/mobile/Library/Preferences/%@.plist"), specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    [settings setObject:value forKey:specifier.properties[@"key"]];
    [settings writeToFile:path atomically:YES];
    CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL,
                                             YES);
    }
}

- (void)resetToDefaults:(PSSpecifier *)specifier {
    NSString *path = [NSString
        stringWithFormat:JBROOT_PATH_NSSTRING(@"/var/mobile/Library/Preferences/%@.plist"), specifier.properties[@"defaults"]];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings writeToFile:path atomically:YES];
    CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (notificationName) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL,
                                             YES);
    }
    [self reloadSpecifiers];
}

- (UISlider *_Nullable)findSliderInView:(UIView *)view {
    if ([view isKindOfClass:[UISlider class]]) {
        return (UISlider *)view;
    }
    for (UIView *subview in view.subviews) {
        UISlider *slider = [self findSliderInView:subview];
        if (slider) {
            return slider;
        }
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
    NSString *key = [specifier propertyForKey:@"cell"];
    if ([key isEqualToString:@"PSButtonCell"]) {
        UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        NSNumber *isDestructiveValue = [specifier propertyForKey:@"isDestructive"];
        BOOL isDestructive = [isDestructiveValue boolValue];
        cell.textLabel.textColor = isDestructive ? [UIColor systemRedColor] : [UIColor systemBlueColor];
        cell.textLabel.highlightedTextColor = isDestructive ? [UIColor systemRedColor] : [UIColor systemBlueColor];
        return cell;
    }
    if ([key isEqualToString:@"PSSliderCell"]) {
        UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        NSNumber *isContinuousValue = [specifier propertyForKey:@"isContinuous"];
        BOOL isContinuous = [isContinuousValue boolValue];
        UISlider *slider = [self findSliderInView:cell];
        if (slider) {
            slider.continuous = isContinuous;
        }
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

@end
