/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 *  You may not use this file except in compliance with an authorized license
 *  Unauthorized copying of this file, via any medium is strictly prohibited
 *  Proprietary and confidential
 *  UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 *  CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 *  See the License for the specific language governing permissions and limitations under the License.
 *  Written by Itseez3D, Inc. <support@itseez3D.com>, October 2018
 */

#include <fstream>
#include <vector>
#include "loadModel3D.hpp"
#import <opencv2/highgui/highgui.hpp>

void parsePlyHeader(std::istream &inputMesh,
                    std::string &textureBasename,
                    bool &existVertices,
                    bool &existVerticesNormals,
                    bool &existVerticesFlags,
                    bool &existVerticesColors,
                    bool &existVerticesWeights,
                    bool &existFaces,
                    bool &existUvMapping,
                    size_t &countElementVertexInMesh,
                    size_t &countElementFacesInMesh)
{
    std::string line;
    while(std::getline(inputMesh, line))
    {
        if (line.find("comment TextureFile ") != std::string::npos)
        {
            textureBasename = line.substr(line.find_last_of(" ") + 1);
            continue;
        }

        if (line.find("element vertex ") != std::string::npos)
        {
            countElementVertexInMesh = atoi(line.substr(line.find_last_of(" ") + 1).c_str());
            continue;
        }

        if (line.find("property float x") != std::string::npos)
        {
            existVertices = true;
            continue;
        }

        if (line.find("property float nx") != std::string::npos)
        {
            existVerticesNormals = true;
            continue;
        }

        if ((line.find("property int flags") != std::string::npos) ||
                (line.find("property float value") != std::string::npos))
        {
            existVerticesFlags = true;
            continue;
        }

        if (line.find("property uchar red") != std::string::npos)
        {
            existVerticesColors = true;
            continue;
        }

        if (line.find("property float w") != std::string::npos)
        {
            existVerticesWeights = true;
            continue;
        }

        if (line.find("element face ") != std::string::npos)
        {
            countElementFacesInMesh = atoi(line.substr(line.find_last_of(" ") + 1).c_str());
            continue;
        }

        if (line.find("property list uchar int vertex_indices") != std::string::npos)
        {
            existFaces = true;
            continue;
        }

        if (line.find("property list uchar float texcoord") != std::string::npos)
        {
            existUvMapping = true;
            continue;
        }

        if (line.find("end_header") != std::string::npos)
        {
            break;
        }
    }
}

namespace pointcloudMerge
{

    void loadModelFromBinPLYinFloat(const std::string &filename,
                                    std::vector<float> *vertices,
                                    std::vector<float> *verticesNormals,
                                    std::vector<std::vector<size_t> > *faces,
                                    std::vector<float> *uvMapping)
    {
        std::ifstream inputMesh(filename.c_str(),std::ios::binary);
        if (!inputMesh.is_open())
        {
            return;
        }
        loadModelFromBinPLYinFloat(inputMesh, vertices, verticesNormals, faces, uvMapping);
    }

    void loadModelFromBinPLYinFloat(std::istream &inputMesh,
                                    std::vector<float> *vertices,
                                    std::vector<float> *verticesNormals,
                                    std::vector<std::vector<size_t> > *faces,
                                    std::vector<float> *uvMapping)
    {
        bool existVertices = false, loadVertices = vertices != 0;
        bool existVerticesNormals = false, loadVerticesNormals = verticesNormals != 0;
        bool existFaces = false, loadFaces = faces != 0;
        bool existUvMapping = false, loadUvMapping = uvMapping != 0;
        bool existVerticesFlags = false, existVerticesColors = false, existVerticesWeights = false;

        const int sizeofInt = sizeof(int);
        const int sizeofChar = sizeof(char);
        const int sizeofFloat = sizeof(float);

        std::string textureBasename;
        size_t countElementVertexInMesh, countElementFacesInMesh;
        parsePlyHeader(inputMesh, textureBasename, existVertices, existVerticesNormals,
                       existVerticesFlags, existVerticesColors, existVerticesWeights,
                       existFaces, existUvMapping, countElementVertexInMesh, countElementFacesInMesh);

        std::vector<std::vector<cv::Point2d> > junkUvMapping;
        if (!loadUvMapping && existUvMapping)
        {
            uvMapping->resize(junkUvMapping.size()*6);
            for (size_t index = 0; index < junkUvMapping.size(); index++)
            {
                (*uvMapping)[index*6] = (float)junkUvMapping[index][0].x;
                (*uvMapping)[index*6+1] = (float)junkUvMapping[index][0].y;
                (*uvMapping)[index*6+2] = (float)junkUvMapping[index][1].x;
                (*uvMapping)[index*6+3] = (float)junkUvMapping[index][1].y;
                (*uvMapping)[index*6+4] = (float)junkUvMapping[index][2].x;
                (*uvMapping)[index*6+5] = (float)junkUvMapping[index][2].y;
            }
            loadUvMapping = true;
        }

        if (loadVertices)
        {
            vertices->resize(countElementVertexInMesh*3);
        }
        if (loadVerticesNormals)
        {
            verticesNormals->resize(countElementVertexInMesh*3);
        }
        if (loadFaces)
        {
            faces->resize(countElementFacesInMesh);
        }
        if (loadUvMapping)
        {
            uvMapping->resize(countElementFacesInMesh*6);
        }

        if (loadVertices && !existVertices)
        {
            loadVertices = false;
        }
        if (loadVerticesNormals && !existVerticesNormals)
        {
            loadVerticesNormals = false;
        }
        if (loadFaces && !existFaces)
        {
            loadFaces = false;
        }
        if (loadUvMapping && !existUvMapping)
        {
            loadUvMapping = false;
        }

        if (existVertices || existVerticesNormals)
        {
            const int verticesValuesInLine = (existVertices ? 3 : 0) +
            (existVerticesNormals ? 3 : 0) +
            (existVerticesFlags ? 1 : 0) +
            (existVerticesColors ? 1 : 0) +
            (existVerticesWeights ? 1 : 0);

            if (existVerticesNormals || existVerticesFlags || existVerticesColors || existVerticesWeights)
            {
                for (size_t i = 0; i < countElementVertexInMesh; ++i)
                {
                    std::vector<float> values(verticesValuesInLine);
                    inputMesh.read(reinterpret_cast<char *>(values.data()), sizeofFloat * verticesValuesInLine);
                    if (loadVertices)
                    {
                        memcpy(&((*vertices)[i*3]), &values[0], 3*sizeofFloat);
                    }

                    if (loadVerticesNormals)
                    {
                        memcpy(&((*verticesNormals)[i*3]), &values[0], 3*sizeofFloat);
                    }
                }
            }
            else
            {
                inputMesh.read(reinterpret_cast<char *>(vertices->data()), sizeofFloat * verticesValuesInLine*countElementVertexInMesh);
            }
        }

        if (loadFaces || loadUvMapping)
        {
            for (size_t i = 0; i < countElementFacesInMesh; ++i)
            {
                u_char countVertices;
                inputMesh.read(reinterpret_cast<char *>(&countVertices), sizeofChar);
                if (countVertices != 3)
                {
                }
                if (loadFaces)
                {
                    (*faces)[i].resize(countVertices);
                    std::vector<int> values(countVertices);
                    inputMesh.read(reinterpret_cast<char *>(values.data()), sizeofInt * countVertices);
                    for (size_t j = 0; j < countVertices; ++j)
                    {
                        (*faces)[i][j] = values[j];
                    }
                }

                if (loadUvMapping)
                {
                    u_char countUvMapping;
                    inputMesh.read(reinterpret_cast<char *>(&countUvMapping), sizeofChar);
                    std::vector<float> values(countUvMapping);
                    inputMesh.read(reinterpret_cast<char *>(values.data()), sizeofFloat * countUvMapping);
                    (*uvMapping)[6*i] = (float)values[0];
                    (*uvMapping)[6*i+1] = (float)(1 - values[1]);
                    (*uvMapping)[6*i+2] = (float)values[2];
                    (*uvMapping)[6*i+3] = (float)(1 - values[3]);
                    (*uvMapping)[6*i+4] = (float)values[4];
                    (*uvMapping)[6*i+5] = (float)(1 - values[5]);
                }
            }
        }
    }

}
