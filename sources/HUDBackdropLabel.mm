//
//  HUDBackdropLabel.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import "HUDBackdropLabel.h"
#import "HUDBackdropView.h"
#import "CAFilter.h"

@implementation HUDBackdropLabel {
    BOOL _isColorInvertEnabled;
    HUDBackdropView *_backdropView;
    CATextLayer *_backdropTextLayer;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupAppearance];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupAppearance];
    }
    return self;
}

- (void)setColorInvertEnabled:(BOOL)colorInvertEnabled
{
    _isColorInvertEnabled = colorInvertEnabled;
    [self setupAppearance];
}

- (void)setupAppearance
{
    self.alpha = 0.85;
    self.textColor = _isColorInvertEnabled ? [UIColor clearColor] : [UIColor whiteColor];
    if (_isColorInvertEnabled)
    {
        if (!_backdropView)
        {
            _backdropView = [[HUDBackdropView alloc] initWithFrame:self.bounds];
            _backdropView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

            CAFilter *blurFilter = [CAFilter filterWithName:kCAFilterGaussianBlur];
            [blurFilter setValue:@(50.0) forKey:@"inputRadius"];  // radius 50pt
            [blurFilter setValue:@YES forKey:@"inputNormalizeEdges"];  // do not use inputHardEdges

            CAFilter *contrastFilter = [CAFilter filterWithName:kCAFilterColorContrast];
            [contrastFilter setValue:@(1000.0) forKey:@"inputAmount"];   // 1000x

            CAFilter *brightnessFilter = [CAFilter filterWithName:kCAFilterColorBrightness];
            [brightnessFilter setValue:@(-0.285) forKey:@"inputAmount"];  // -28.5%

            CAFilter *saturateFilter = [CAFilter filterWithName:kCAFilterColorSaturate];
            [saturateFilter setValue:@(0.0) forKey:@"inputAmount"];

            CAFilter *colorInvertFilter = [CAFilter filterWithName:kCAFilterColorInvert];

            [_backdropView.layer setFilters:@[
                blurFilter, brightnessFilter, contrastFilter,
                saturateFilter, colorInvertFilter,
            ]];

            _backdropTextLayer = [CATextLayer layer];
            _backdropTextLayer.contentsScale = self.layer.contentsScale * 1.2;
            _backdropTextLayer.actions = @{
                @"bounds": [NSNull null],
                @"contents": [NSNull null],
                @"position": [NSNull null],
            };
            _backdropView.layer.mask = _backdropTextLayer;

            [self addSubview:_backdropView];
        }
    }
    else
    {
        if (_backdropView)
        {
            [_backdropView removeFromSuperview];
            _backdropView = nil;
            _backdropTextLayer = nil;
        }
    }
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    if (layer == self.layer && _backdropTextLayer)
    {
        [_backdropTextLayer setFrame:self.layer.bounds];
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [_backdropTextLayer setString:attributedText];
}

@end
