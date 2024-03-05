/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 *  You may not use this file except in compliance with an authorized license
 *  Unauthorized copying of this file, via any medium is strictly prohibited
 *  Proprietary and confidential
 *  UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 *  CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 *  See the License for the specific language governing permissions and limitations under the License.
 *  Written by Itseez3D, Inc. <support@itseez3D.com>, October 2018
 */

import GLTF

class AvatarNode: SCNNode {
    private let avatarNode: SCNNode

    public var headNode = SCNNode()
    private var headTransform = SCNMatrix4Identity
    public var haircutNode = SCNNode()
    private var haircutTransform = SCNMatrix4Identity
    public var outfitNode = SCNNode()
    private var outfitTransform = SCNMatrix4Identity
    private var morpherNode = SCNNode()
    private var textureNode = SCNNode()

    init(avatarURL: URL) {
        avatarNode = AvatarNode.createNode(url: avatarURL)
        super.init()
        parseAvatar(node: avatarNode)
        
        avatarNode.position = SCNVector3(0, 0, 0)
        if haircutNode.childNodes.count > 0 {
            let haircutNode2 = deepCopyNode(node: haircutNode.childNodes[0])
            haircutNode.addChildNode(haircutNode2)

            haircutNode.childNodes[0].geometry?.firstMaterial?.writesToDepthBuffer = false
            haircutNode.childNodes[0].geometry?.firstMaterial?.isDoubleSided = false
        }
        
        addChildNode(avatarNode)
    }
    
    fileprivate func deepCopyNode(node: SCNNode) -> SCNNode {
        let clone = node.clone()
        clone.geometry = node.geometry?.copy() as? SCNGeometry
        if let g = node.geometry {
            clone.geometry?.materials = g.materials.map{ $0.copy() as! SCNMaterial }
        }
        return clone
    }

    static func createNode(url: URL) -> SCNNode {
        let node: SCNNode
        let name = url
        let bufferAllocator = GLTFDefaultBufferAllocator()
        let asset = GLTFAsset(url: name, bufferAllocator: bufferAllocator)

        let scnAsset = SCNScene.asset(from: asset, options: [:])
        node = scnAsset.defaultScene?.rootNode ?? SCNNode()

        return node
    }

    static func findTextureNode(node: SCNNode) -> SCNNode? {
        if node.geometry?.firstMaterial != nil {
            return node
        }

        for child in node.childNodes {
            if let textureNode = findTextureNode(node: child) {
                return textureNode
            }
        }

        return nil
    }
    
    func parseAvatar(node: SCNNode) {
        if node.geometry == nil && node.name == "AvatarHead" {
            headNode = node
            headTransform = node.transform
        }
        if node.geometry == nil && node.name == "haircut" {
            haircutNode = node
            haircutTransform = node.transform
        }
        if node.geometry == nil && node.name == "outfit" {
            outfitNode = node
            outfitTransform = node.transform
        }
        if node.morpher != nil {
            morpherNode = node
        }
        if node.geometry?.firstMaterial != nil {
            textureNode = node
        }
        for child in node.childNodes {
            parseAvatar(node: child)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
