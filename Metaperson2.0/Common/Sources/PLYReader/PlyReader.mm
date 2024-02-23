/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 *  You may not use this file except in compliance with an authorized license
 *  Unauthorized copying of this file, via any medium is strictly prohibited
 *  Proprietary and confidential
 *  UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 *  CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 *  See the License for the specific language governing permissions and limitations under the License.
 *  Written by Itseez3D, Inc. <support@itseez3D.com>, October 2018
 */

#import "PlyReader.h"
#import "loadModel3D.hpp"
#include <fstream>
#include <unordered_map>

cv::Vec3f ModelPLY::computeCross(cv::Point3f* v1, cv::Point3f* v2, cv::Point3f* v3)
{
    cv::Vec3f a = cv::Vec3f(*v1);
    cv::Vec3f b = cv::Vec3f(*v2);
    cv::Vec3f c = cv::Vec3f(*v3);
    return (b - a).cross(c - a);
}

cv::Point3f* ModelPLY::computeNormals(cv::Point3f *_vertices) {
    std::vector<float> originalNormals;

    originalNormals.resize(originalVertexCount * 3);

    size_t numFaces = originalFaces.size();
    for (int faceIdx = 0; faceIdx < numFaces; ++faceIdx) {
        int v1 = (int)originalFaces[faceIdx][0];
        int v2 = (int)originalFaces[faceIdx][1];
        int v3 = (int)originalFaces[faceIdx][2];

        cv::Vec3f crossVec = computeCross(&_vertices[v1], &_vertices[v2], &_vertices[v3]);
        cv::Vec3f normal = cv::normalize(crossVec);

        float weight = cv::norm(crossVec);
        normal *= weight;

        for (int j = 0; j < 3; j++)
        {
            int vertexIdx = (int)originalFaces[faceIdx][j];
            originalNormals[vertexIdx*3 + 0] += normal[0];
            originalNormals[vertexIdx*3 + 1] += normal[1];
            originalNormals[vertexIdx*3 + 2] += normal[2];
        }
    }

    for (int i = 0; i < originalVertexCount; i++)
    {
        cv::Vec3f n = cv::normalize(cv::Vec3f(&originalNormals[i * 3]));
        memcpy(&originalNormals[i*3], n.val, 3 * sizeof(float));
    }
    cv::Point3f* _normals = new cv::Point3f[vertexCount];
    memcpy(_normals, originalNormals.data(), originalNormals.size() * sizeof(float));

    for (int i = 0; i < vertexCount; ++i) {
        int duplicateIdx = indexMap[i];
        _normals[i] = _normals[duplicateIdx];
    }

    return _normals;
}

void ModelPLY::load(NSURL *meshFileURL)
{
    std::vector<float> originalVertices;
    std::vector<float> _facesTextures;

    pointcloudMerge::loadModelFromBinPLYinFloat([meshFileURL.path UTF8String], &originalVertices, 0, &originalFaces, &_facesTextures);

    originalVertexCount = (int)originalVertices.size() / 3;
    // If different uv coordinates correspond to single vertex we need to
    // duplicate this vertex in order to comply with SceneKit mesh format.

    // originalVertcies may contain vertices that doesn't belong to any faces,
    // so maximum number of vertcices after transformation is number of faces * 3 (which is faces.size) + originalVertcies.size
    int maxVerticesCount = (int)originalFaces.size() * 3 + originalVertexCount;

    // This array holds indices of created duplicates.
    std::vector<int> duplicate;
    duplicate.resize(maxVerticesCount);
    for (int i = 0; i < maxVerticesCount; ++i) {
        duplicate[i] = -1;
    }

    // each vertex in each face has unique uv coord pair
    std::vector<cv::Point2f> vertexUv;
    vertexUv.resize(maxVerticesCount);
    cv::Point2f uninitialized = cv::Point2f(-1, -1);
    for (int i = 0; i < vertexUv.size(); ++i) {
        vertexUv[i] = uninitialized;
    }

    indexCount = originalFaces.size();
    indices = new cv::Point3i[indexCount];

    size_t numFaces = indexCount;
    int numVertices = originalVertexCount;

    for (int faceIdx = 0; faceIdx < numFaces; ++faceIdx) {
        for (int j = 0; j < 3; ++j) {
            int vertexIdx = (int)originalFaces[faceIdx][j];
            cv::Point2f currentUv = cv::Point2f(_facesTextures[faceIdx*6 + j*2], _facesTextures[faceIdx*6  + j*2 + 1]);

            // Iterate over duplicates of this vertex until we find copy with exact same uv.
            // Create new duplicate vertex if none were found.
            while (vertexUv[vertexIdx] != uninitialized && vertexUv[vertexIdx] != currentUv) {
                if (duplicate[vertexIdx] == -1) {
                    duplicate[vertexIdx] = numVertices++;  // "allocate" new vertex and save link to it
                }
                vertexIdx = duplicate[vertexIdx];
            }

            vertexUv[vertexIdx] = currentUv;
            memcpy((int*)&indices[faceIdx] + j, &vertexIdx, sizeof(int));
        }
    }


    vertexCount = numVertices;
    vertices = new cv::Point3f[vertexCount];
    indexMap = new uint[vertexCount];
    memcpy(vertices, originalVertices.data(), originalVertexCount * 3 * sizeof(float));

    //    for (int i = 0; i < originalVertexCount; ++i) {
    //        vertices [i] *= 100;
    //    }

    for (int i = 0; i < originalVertexCount; ++i) {
        indexMap [i] = i;
    }

    for (int i = 0; i < originalVertexCount; ++i) {
        int duplicateIdx = duplicate[i];
        while (duplicateIdx != -1) {
            vertices [duplicateIdx] = vertices[i];
            indexMap [duplicateIdx] = i;
            duplicateIdx = duplicate [duplicateIdx];
        }
    }

    normals = computeNormals(vertices);

    texCoord = new cv::Point2f[numVertices];
    memcpy(texCoord, vertexUv.data(), numVertices * sizeof(cv::Point2f));
    return;
}

void ModelPLY::loadFromData(SCNGeometrySource *vertexSource, SCNGeometryElement *facesSource)
{
    vertexCount = (int)vertexSource.vectorCount;
    vertices = new cv::Point3f[vertexCount];
    indexMap = new uint[vertexCount];
    texCoord = new cv::Point2f[1];
    std::vector<int> idx(vertexCount);

    char *vData = (char*)vertexSource.data.bytes + vertexSource.dataOffset;
    for (int i = 0; i < vertexCount; i++) {
        float *current = (float*)(vData + vertexSource.dataStride * i);
        vertices[i] = cv::Point3f(current[0], current[1], current[2]);
        indexMap[i] = -1;
        idx[i] = i;
    }

    // sort indexes based on comparing values in v
    sort(idx.begin(), idx.end(),
         [this](size_t i1, size_t i2) {return (vertices[i1].x < vertices[i2].x || vertices[i1].y < vertices[i2].y) || vertices[i1].z < vertices[i2].z;});

    originalVertexCount = vertexCount;
    int dupIndex = 0;
    cv::Point3f dupVertex, curVertex;

    if (vertexCount > 0) {
        dupIndex = idx[0];
        dupVertex = vertices[dupIndex];
        int curIndex;
        for (int i = 0; i < vertexCount; i++) {
            curIndex = idx[i];
            curVertex = vertices[curIndex];

            if (curVertex == dupVertex) {
                indexMap[curIndex] = dupIndex;
            } else {
                dupIndex = curIndex;
                dupVertex = vertices[dupIndex];
                indexMap[curIndex] = curIndex;
            }
        }
    }

    indexCount = facesSource.primitiveCount;
    indices = new cv::Point3i[indexCount];
    originalFaces.resize(indexCount);

    char *iData = (char*)facesSource.data.bytes;
    for (int i = 0; i < indexCount; i++) {
        int *current = (int*)(iData + i * 3 * 4);
        indices[i] = cv::Point3i(current[0], current[1], current[2]);
        originalFaces[i].resize(3);
        originalFaces[i][0] = indexMap[current[0]];
        originalFaces[i][1] = indexMap[current[1]];
        originalFaces[i][2] = indexMap[current[2]];
    }

    normals = computeNormals(vertices);

    return;
}

cv::Point3f* ModelPLY::loadBlendshape(NSURL *url) {
    NSData *blendshapeVerticesData = [NSData dataWithContentsOfURL:url];
    cv::Point3f *blendshapeVertices = new cv::Point3f[vertexCount];
    memcpy(blendshapeVertices, blendshapeVerticesData.bytes, blendshapeVerticesData.length);

    for (int i = originalVertexCount; i < vertexCount; ++i) {
        int duplicateIdx = indexMap[i];
        blendshapeVertices[i] = blendshapeVertices[duplicateIdx];
    }

    return blendshapeVertices;
}

cv::Point3f* ModelPLY::loadPlyBlendshape(NSURL *url) {
    cv::Point3f *blendshapeVertices = new cv::Point3f[vertexCount];
    std::vector<float> vertices;
    pointcloudMerge::loadModelFromBinPLYinFloat([url.path UTF8String], &vertices, 0, 0, 0);
    memcpy(blendshapeVertices, vertices.data(), vertices.size() * 4);

    for (int i = originalVertexCount; i < vertexCount; ++i) {
        int duplicateIdx = indexMap[i];
        blendshapeVertices[i] = blendshapeVertices[duplicateIdx];
    }

    return blendshapeVertices;
}

ModelPLY::~ModelPLY() {
    delete vertices;
    delete normals;
    delete texCoord;
    delete indices;
    delete indexMap;
}
