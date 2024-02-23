/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 * You may not use this file except in compliance with an authorized license
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 * See the License for the specific language governing permissions and limitations under the License.
 * Written by Itseez3D, Inc. <support@itseez3D.com>, May 2017
 */

#import "AvatarViewer.h"

#if TARGET_OS_IOS
#elif TARGET_OS_OSX
typedef NSGestureRecognizer UIGestureRecognizer;
typedef NS_ENUM(NSInteger, UIGestureRecognizerState) {
    UIGestureRecognizerStatePossible,
    UIGestureRecognizerStateBegan,
    UIGestureRecognizerStateChanged,
    UIGestureRecognizerStateEnded,
    UIGestureRecognizerStateCancelled,
    UIGestureRecognizerStateFailed,
    UIGestureRecognizerStateRecognized = UIGestureRecognizerStateEnded
};
typedef NSMagnificationGestureRecognizer UIPinchGestureRecognizer;
typedef NSPanGestureRecognizer UIPanGestureRecognizer;
typedef NSRotationGestureRecognizer UIRotationGestureRecognizer;
#endif

@interface AvatarViewer () {
    CGFloat previousScaleFactor;
    CGPoint previousMovePoint;
    CGPoint previousRotatePoint;
    CGPoint inertiaVelocity;
    float rotationRad;
    int gesture;
    NSTimer *inertiaTimer;
}

@end

@implementation AvatarViewer

- (id)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }

    return self;
}

- (void)commonInit {
    [self setupGestures];
}

- (void)deinitialize {
    [self stopInertiaTimer];
}

#pragma mark - UIGestureRecognizerHandle

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
    if (!_withAvatar) {return;}
    [self stopInertiaTimer];
}

- (void)handleLongPressGesture:(UIGestureRecognizer *)gestureRecognizer {
    if (!_withAvatar) {return;}

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self stopInertiaTimer];
        if (_allowedGestures != AvatarViewerGesturesNone) {
            [self resetModelPosition];
        }
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if (!_withAvatar) {return;}
    [self stopInertiaTimer];

    switch ([sender state]) {
    case UIGestureRecognizerStateBegan:
#if TARGET_OS_IOS
        previousScaleFactor = 1.0;
#elif TARGET_OS_OSX
        previousScaleFactor = 0.0;
#endif
        break;
    case UIGestureRecognizerStateEnded:
        break;
    default:
#if TARGET_OS_IOS
        float scale = sender.scale;
#elif TARGET_OS_OSX
        float scale = sender.magnification;
#endif
        float factor = previousScaleFactor - scale;
        previousScaleFactor = scale;
        if (_allowedGestures == AvatarViewerGesturesAll) {
            [self zoomModel:1 - factor];
        }
        break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)sender {
    if (!_withAvatar) {return;}
    [self stopInertiaTimer];

    switch ([sender state]) {
    case UIGestureRecognizerStateBegan:
        previousRotatePoint = [sender translationInView:self];
        break;
    case UIGestureRecognizerStateEnded:
        if (_allowedGestures != AvatarViewerGesturesNone) {
            [self addInertiaRotation:[sender velocityInView:self]];
        }
        break;
    default:
        if (_allowedGestures != AvatarViewerGesturesNone) {
            CGPoint translatedPointPan = [sender translationInView:self];
#if TARGET_OS_IOS
            CGPoint diff = CGPointMake(-(previousRotatePoint.x - translatedPointPan.x), -(previousRotatePoint.y - translatedPointPan.y));
#elif TARGET_OS_OSX
            CGPoint diff = CGPointMake(-(previousRotatePoint.x - translatedPointPan.x), previousRotatePoint.y - translatedPointPan.y);
#endif
            previousRotatePoint = translatedPointPan;
            [self rotateWithVector:diff];
        }
        break;
    }
}

- (void)handleDoublePanGesture:(UIPanGestureRecognizer*)sender {
    if (!_withAvatar) {return;}
#if TARGET_OS_IOS
    if ([sender numberOfTouches] != 2) {return;}
#endif
    [self stopInertiaTimer];

    switch ([sender state]) {
    case UIGestureRecognizerStateBegan:
        previousMovePoint = [(UIPanGestureRecognizer*)sender locationInView:self];
        break;
    case UIGestureRecognizerStateEnded:
        break;
    default:
        CGPoint translatedMovePoint = [(UIPanGestureRecognizer*)sender locationInView:self];
        CGPoint diff = CGPointMake(previousMovePoint.x - translatedMovePoint.x, previousMovePoint.y - translatedMovePoint.y);
        previousMovePoint = translatedMovePoint;

        if (_allowedGestures == AvatarViewerGesturesAll) {
#if TARGET_OS_IOS
            [self moveModel:CGPointMake(-diff.x / 8, -diff.y / 8)];
#elif TARGET_OS_OSX
            [self moveModel:CGPointMake(-diff.x / 8, diff.y / 8)];
#endif
        }
        break;
    }
}


- (void)handleRotateGesture:(UIRotationGestureRecognizer *)sender {
    if (!_withAvatar) {return;}
    [self stopInertiaTimer];

    switch ([sender state]) {
    case UIGestureRecognizerStateBegan:
        rotationRad = [sender rotation];
        break;
    case UIGestureRecognizerStateEnded:
        break;
    default:
        if (_allowedGestures == AvatarViewerGesturesAll) {
            float angle = (rotationRad - [(UIRotationGestureRecognizer *)sender rotation]) * 2;
            rotationRad = [(UIRotationGestureRecognizer *)sender rotation];
#if TARGET_OS_IOS
            [self rotateZModel:angle];
#elif TARGET_OS_OSX
            [self rotateZModel:-angle];
#endif
        }
        break;
    }
}

#pragma mark -

- (void)rotateWithVector:(CGPoint)vec {
    if (_allowedGestures != AvatarViewerGesturesNone) {
        [self rotateModel:CGPointMake(vec.x, vec.y)];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (([gestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]])    ||
        ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]    && [otherGestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]]) ||
        ([gestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])      ||
        ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]      && [otherGestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]]) ||
        ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]    && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])      ||
        ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]      && [otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]])) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (void)setupGestures {
#if TARGET_OS_IOS
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = YES;

    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self addGestureRecognizer:panRecognizer];

    UIPanGestureRecognizer *doublePanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoublePanGesture:)];
    [doublePanRecognizer setMinimumNumberOfTouches:2];
    [doublePanRecognizer setMaximumNumberOfTouches:2];
    [doublePanRecognizer requireGestureRecognizerToFail:panRecognizer];
    [doublePanRecognizer setDelegate:self];
    [self addGestureRecognizer:doublePanRecognizer];

    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [pinchRecognizer setDelegate:self];
    [pinchRecognizer requireGestureRecognizerToFail:panRecognizer];
    [self addGestureRecognizer:pinchRecognizer];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [singleTap setDelegate:self];
    [self addGestureRecognizer:singleTap];

    UIRotationGestureRecognizer *rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotateGesture:)];
    [rotateGesture setDelegate:self];
    [rotateGesture requireGestureRecognizerToFail:panRecognizer];
    [self addGestureRecognizer:rotateGesture];

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [longPressGesture setDelegate:self];
    [self addGestureRecognizer:longPressGesture];
#elif TARGET_OS_OSX
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [panRecognizer setDelegate:self];
    [self addGestureRecognizer:panRecognizer];
    NSLog(@"%@", panRecognizer);

    UIPanGestureRecognizer *doublePanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoublePanGesture:)];
    [doublePanRecognizer setDelegate:self];
    doublePanRecognizer.buttonMask = 0x2;
    [self addGestureRecognizer:doublePanRecognizer];
    NSLog(@"%@", doublePanRecognizer);

    NSMagnificationGestureRecognizer *pinchRecognizer = [[NSMagnificationGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [pinchRecognizer setDelegate:self];
    [self addGestureRecognizer:pinchRecognizer];

    NSClickGestureRecognizer *singleTap = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTap setDelegate:self];
    [self addGestureRecognizer:singleTap];

    UIRotationGestureRecognizer *rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotateGesture:)];
    [rotateGesture setDelegate:self];
    [self addGestureRecognizer:rotateGesture];

    NSPressGestureRecognizer *longPressGesture = [[NSPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [longPressGesture setDelegate:self];
    [self addGestureRecognizer:longPressGesture];
#endif
}

#pragma mark - Timers

- (void)addInertiaRotation:(CGPoint)velocity {
    inertiaVelocity = velocity;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self->inertiaTimer = [NSTimer scheduledTimerWithTimeInterval:1 / 60.0 target:self selector:@selector(inertiaTick) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self->inertiaTimer forMode:NSRunLoopCommonModes];
    });
}

- (void)inertiaTick {
    float velocity = sqrtf(inertiaVelocity.x * inertiaVelocity.x + inertiaVelocity.y * inertiaVelocity.y);

    CGFloat dec = MAX(0.99 - 10/velocity, 0.92);
    inertiaVelocity = CGPointMake(inertiaVelocity.x*dec, inertiaVelocity.y*dec);

    if (ABS(inertiaVelocity.x) + ABS(inertiaVelocity.y) > 50) {
        [self rotateWithVector:CGPointMake(inertiaVelocity.x / 245 * M_PI * 2, inertiaVelocity.y / 245 * M_PI * 2)];
    } else {
        [self stopInertiaTimer];
    }
}

- (void)stopInertiaTimer {
    if ([inertiaTimer isValid]) {
        [inertiaTimer invalidate];
        inertiaTimer = nil;
    }
}

- (void)rotateModel:(CGPoint)point {}
- (void)rotateZModel:(float)angle {}
- (void)zoomModel:(float)factor {}
- (void)moveModel:(CGPoint)point {}
- (void)resetModelPosition {}

@end
