/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 *  You may not use this file except in compliance with an authorized license
 *  Unauthorized copying of this file, via any medium is strictly prohibited
 *  Proprietary and confidential
 *  UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 *  CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 *  See the License for the specific language governing permissions and limitations under the License.
 *  Written by Itseez3D, Inc. <support@itseez3D.com>, October 2018
 */

#ifndef __LOADMODEL3D_HPP__
#define __LOADMODEL3D_HPP__

namespace pointcloudMerge
{

    void loadModelFromBinPLYinFloat(const std::string &filename,
                                    std::vector<float> *vertices = 0,
                                    std::vector<float> *verticesNormals = 0,
                                    std::vector<std::vector<size_t> > *faces = 0,
                                    std::vector<float> *uvMapping = 0);

    void loadModelFromBinPLYinFloat(std::istream &inputMesh,
                                    std::vector<float> *vertices,
                                    std::vector<float> *verticesNormals,
                                    std::vector<std::vector<size_t> > *faces,
                                    std::vector<float> *uvMapping);
}

#endif //__LOADMODEL3D_HPP__
