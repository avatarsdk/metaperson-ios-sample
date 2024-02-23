/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 * You may not use this file except in compliance with an authorized license
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 * See the License for the specific language governing permissions and limitations under the License.
 * Written by Itseez3D, Inc. <support@itseez3D.com>, May 2017
 */

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#endif

#import <CoreMedia/CoreMedia.h>
#import <SceneKit/SceneKit.h>

typedef void (^AnimationIsOver)();

typedef NS_ENUM(NSInteger, AvatarViewerGestures) {
    AvatarViewerGesturesAll,
    AvatarViewerGesturesSafe,
    AvatarViewerGesturesNone
};

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_IOS
@interface AvatarViewer : UIView <UIGestureRecognizerDelegate>
#else
@interface AvatarViewer : NSView <NSGestureRecognizerDelegate>
#endif
@property (nonatomic, assign) AvatarViewerGestures allowedGestures;
@property (nonatomic, assign) BOOL withAvatar;

- (void)commonInit;

- (void)deinitialize;

- (void)rotateModel:(CGPoint)point;
- (void)rotateZModel:(float)angle;
- (void)zoomModel:(float)factor;
- (void)moveModel:(CGPoint)point;
- (void)resetModelPosition;

@end

NS_ASSUME_NONNULL_END
