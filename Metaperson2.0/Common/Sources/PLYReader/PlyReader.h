/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 *  You may not use this file except in compliance with an authorized license
 *  Unauthorized copying of this file, via any medium is strictly prohibited
 *  Proprietary and confidential
 *  UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 *  CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 *  See the License for the specific language governing permissions and limitations under the License.
 *  Written by Itseez3D, Inc. <support@itseez3D.com>, October 2018
 */

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <opencv2/highgui/highgui.hpp>

#ifndef __3DViewer__plyReader__
#define __3DViewer__plyReader__

@class PlyItem;

class ModelPLY
{
public:
    void load(NSURL *meshFileURL);
    void loadFromData(SCNGeometrySource *vertexSource, SCNGeometryElement *facesSource);

    cv::Point3f* loadBlendshape(NSURL *url);
    cv::Point3f* loadPlyBlendshape(NSURL *url);

    cv::Point3f* computeNormals(cv::Point3f* vertices);
    cv::Vec3f computeCross(cv::Point3f* v1, cv::Point3f* v2, cv::Point3f* v3);
    ~ModelPLY();

public:
    std::vector<std::vector<size_t>> originalFaces;

    int originalVertexCount;
    int vertexCount;
    cv::Point3f* vertices;
    cv::Point3f* normals;
    cv::Point2f* texCoord;

    uint* indexMap;

    size_t indexCount;
    cv::Point3i* indices;

    NSString *imageName;
};

#endif /* defined(__3DViewer__plyReader__) */
