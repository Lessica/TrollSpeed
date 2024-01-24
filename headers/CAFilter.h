/* CoreAnimation - CAFilter.h

 Copyright (c) 2006-2007 Apple Inc.
 All rights reserved. */

#ifndef CAFILTER_H
#define CAFILTER_H

#include <QuartzCore/CABase.h>

NS_ASSUME_NONNULL_BEGIN
CA_EXTERN_C_BEGIN

@interface CAFilter : NSObject <NSCopying, NSMutableCopying>

@property (class, readonly) NSArray<NSString *> *_Nonnull filterTypes;

@property (assign) BOOL cachesInputImage;
@property (assign, getter=isEnabled) BOOL enabled;
@property (copy) NSString *name;
@property (readonly, assign) NSString *type;

@property (readonly, strong) NSArray<NSString *> *inputKeys;
@property (readonly, strong) NSArray<NSString *> *outputKeys;

+ (nullable CAFilter *)filterWithType:(nonnull NSString *)type NS_SWIFT_UNAVAILABLE("Use init(type:) instead.");
+ (nullable CAFilter *)filterWithName:(nonnull NSString *)name NS_SWIFT_UNAVAILABLE("Use init(type:) instead.");
- (nullable instancetype)initWithType:(nonnull NSString *)type;
- (nullable instancetype)initWithName:(nonnull NSString *)name NS_SWIFT_UNAVAILABLE("Use init(type:) instead.");

- (void)setDefaults;

@end

/** Filter types. **/

CA_EXTERN NSString * const kCAFilterMultiplyColor;
CA_EXTERN NSString * const kCAFilterColorAdd;
CA_EXTERN NSString * const kCAFilterColorSubtract;
CA_EXTERN NSString * const kCAFilterColorMonochrome;
CA_EXTERN NSString * const kCAFilterColorMatrix;
CA_EXTERN NSString * const kCAFilterColorHueRotate;
CA_EXTERN NSString * const kCAFilterColorSaturate;
CA_EXTERN NSString * const kCAFilterColorBrightness;
CA_EXTERN NSString * const kCAFilterColorContrast;
CA_EXTERN NSString * const kCAFilterColorInvert;
CA_EXTERN NSString * const kCAFilterLuminanceToAlpha;
CA_EXTERN NSString * const kCAFilterBias;
CA_EXTERN NSString * const kCAFilterDistanceField;
CA_EXTERN NSString * const kCAFilterGaussianBlur;
CA_EXTERN NSString * const kCAFilterLanczosResize;
CA_EXTERN NSString * const kCAFilterClear;
CA_EXTERN NSString * const kCAFilterCopy;
CA_EXTERN NSString * const kCAFilterSourceOver;
CA_EXTERN NSString * const kCAFilterSourceIn;
CA_EXTERN NSString * const kCAFilterSourceOut;
CA_EXTERN NSString * const kCAFilterSourceAtop;
CA_EXTERN NSString * const kCAFilterDest;
CA_EXTERN NSString * const kCAFilterDestOver;
CA_EXTERN NSString * const kCAFilterDestIn;
CA_EXTERN NSString * const kCAFilterDestOut;
CA_EXTERN NSString * const kCAFilterDestAtop;
CA_EXTERN NSString * const kCAFilterXor;
CA_EXTERN NSString * const kCAFilterPlusL;
CA_EXTERN NSString * const kCAFilterSubtractS;
CA_EXTERN NSString * const kCAFilterSubtractD;
CA_EXTERN NSString * const kCAFilterMultiply;
CA_EXTERN NSString * const kCAFilterMinimum;
CA_EXTERN NSString * const kCAFilterMaximum;
CA_EXTERN NSString * const kCAFilterPlusD;
CA_EXTERN NSString * const kCAFilterNormalBlendMode;
CA_EXTERN NSString * const kCAFilterMultiplyBlendMode;
CA_EXTERN NSString * const kCAFilterScreenBlendMode;
CA_EXTERN NSString * const kCAFilterOverlayBlendMode;
CA_EXTERN NSString * const kCAFilterDarkenBlendMode;
CA_EXTERN NSString * const kCAFilterLightenBlendMode;
CA_EXTERN NSString * const kCAFilterColorDodgeBlendMode;
CA_EXTERN NSString * const kCAFilterColorBurnBlendMode;
CA_EXTERN NSString * const kCAFilterSoftLightBlendMode;
CA_EXTERN NSString * const kCAFilterHardLightBlendMode;
CA_EXTERN NSString * const kCAFilterDifferenceBlendMode;
CA_EXTERN NSString * const kCAFilterExclusionBlendMode;
CA_EXTERN NSString * const kCAFilterSubtractBlendMode;
CA_EXTERN NSString * const kCAFilterDivideBlendMode;
CA_EXTERN NSString * const kCAFilterLinearBurnBlendMode;
CA_EXTERN NSString * const kCAFilterLinearDodgeBlendMode;
CA_EXTERN NSString * const kCAFilterLinearLightBlendMode;
CA_EXTERN NSString * const kCAFilterPinLightBlendMode;
CA_EXTERN NSString * const kCAFilterPageCurl;
CA_EXTERN NSString * const kCAFilterVibrantDark;
CA_EXTERN NSString * const kCAFilterVibrantLight;
CA_EXTERN NSString * const kCAFilterDarkenSourceOver;
CA_EXTERN NSString * const kCAFilterLightenSourceOver;

CA_EXTERN NSString * const kCAFilterHomeAffordanceBase;

CA_EXTERN_C_END

struct CAColorMatrix {
    float m11, m12, m13, m14, m15;
    float m21, m22, m23, m24, m25;
    float m31, m32, m33, m34, m35;
    float m41, m42, m43, m44, m45;
};
typedef struct CAColorMatrix CAColorMatrix;

@interface NSValue (CADetails)
+ (NSValue *)valueWithCAColorMatrix:(CAColorMatrix)t;
@end

NS_ASSUME_NONNULL_END

#endif // CAFILTER_H
