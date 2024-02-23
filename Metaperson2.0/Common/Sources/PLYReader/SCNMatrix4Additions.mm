/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 *  You may not use this file except in compliance with an authorized license
 *  Unauthorized copying of this file, via any medium is strictly prohibited
 *  Proprietary and confidential
 *  UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 *  CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 *  See the License for the specific language governing permissions and limitations under the License.
 *  Written by Itseez3D, Inc. <support@itseez3D.com>, October 2018
 */

#import "SCNMatrix4Additions.h"

#if TARGET_OS_IOS
FOUNDATION_EXTERN float DegreeToRadians(CGFloat degrees) {
    return ((degrees)/180.0*M_PI);
}
FOUNDATION_EXTERN SCNVector3 SCNVector3Create(CGFloat x, CGFloat y, CGFloat z) {
    return (SCNVector3){float(x), float(y), float(z)};
}
FOUNDATION_EXTERN SCNMatrix4 SCNMatrix4MakeEulerRotation(float x, float y, float z) {
    SCNMatrix4 xM = SCNMatrix4MakeRotation(x, 1, 0, 0);
    SCNMatrix4 yM = SCNMatrix4MakeRotation(y, 0, 1, 0);
    SCNMatrix4 zM = SCNMatrix4MakeRotation(z, 0, 0, 1);
    return SCNMatrix4Mult(SCNMatrix4Mult(xM, yM), zM);
}
#elif TARGET_OS_OSX
#import <CoreGraphics/CoreGraphics.h>
FOUNDATION_EXTERN CGFloat DegreeToRadians(CGFloat degrees) {
    return ((degrees)/180.0*M_PI);
}
FOUNDATION_EXTERN SCNVector3 SCNVector3Create(CGFloat x, CGFloat y, CGFloat z) {
    return (SCNVector3){x, y, z};
}
FOUNDATION_EXTERN SCNMatrix4 SCNMatrix4MakeEulerRotation(float x, float y, float z) {
    SCNMatrix4 xM = SCNMatrix4MakeRotation(x, 1, 0, 0);
    SCNMatrix4 yM = SCNMatrix4MakeRotation(y, 0, 1, 0);
    SCNMatrix4 zM = SCNMatrix4MakeRotation(z, 0, 0, 1);
    return SCNMatrix4Mult(SCNMatrix4Mult(xM, yM), zM);
}
#endif
