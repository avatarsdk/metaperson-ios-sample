/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 *  You may not use this file except in compliance with an authorized license
 *  Unauthorized copying of this file, via any medium is strictly prohibited
 *  Proprietary and confidential
 *  UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 *  CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 *  See the License for the specific language governing permissions and limitations under the License.
 *  Written by Itseez3D, Inc. <support@itseez3D.com>, October 2018
 */

#import "SceneKitAdditions.h"
#import "PlyReader.h"

@implementation NormalComputer

+ (SCNGeometrySource*)computeNormalsForVertex:(SCNGeometrySource*)vertexSource faces:(SCNGeometryElement*)facesSource {
    ModelPLY modelPly = ModelPLY();
    modelPly.loadFromData(vertexSource, facesSource);
    NSData *normals = [NSData dataWithBytesNoCopy:modelPly.normals length:modelPly.vertexCount * 3 * sizeof(float) freeWhenDone:YES];
    SCNGeometrySource *normalSource = [SCNGeometrySource geometrySourceWithData:normals
                                                                       semantic:SCNGeometrySourceSemanticNormal
                                                                    vectorCount:modelPly.vertexCount
                                                                floatComponents:YES
                                                            componentsPerVector:3
                                                              bytesPerComponent:sizeof(float)
                                                                     dataOffset:0
                                                                     dataStride:sizeof(float) * 3];
    return normalSource;
}

@end
