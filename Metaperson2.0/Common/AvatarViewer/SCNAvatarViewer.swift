/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 *  You may not use this file except in compliance with an authorized license
 *  Unauthorized copying of this file, via any medium is strictly prohibited
 *  Proprietary and confidential
 *  UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 *  CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 *  See the License for the specific language governing permissions and limitations under the License.
 *  Written by Itseez3D, Inc. <support@itseez3D.com>, October 2018
 */

import SceneKit
import CoreImage
import Combine

#if os(iOS)
typealias SceneKitFloat = Float
#elseif os(macOS)
typealias SceneKitFloat = CGFloat
#endif

class SCNAvatarViewer: AvatarViewer {
    var cameraNode: SCNNode = SCNNode()
    private var directionalLightNode: SCNNode = SCNNode()
    private var directionalLight2Node: SCNNode = SCNNode()

    weak var avatarNode: AvatarNode?
    @Published var isZoomed = true

    var avatarTransform = SCNMatrix4Identity {
        didSet {
            avatarNode?.transform = avatarTransform
        }
    }

    lazy var sceneView: SCNView = {
        let view = SCNView()
        view.antialiasingMode = .multisampling4X
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupScene()

        sceneView.frame = frame
        sceneView.scene?.lightingEnvironment.contents = UIImage(named: "lightingEnvironmentMap.jpg")?.cgImage

        self.addSubview(sceneView)
    }

#if os(iOS)
    override func layoutSubviews() {
        super.layoutSubviews()
        sceneView.frame = frame
    }
#endif

    func setAvatarNode(_ node: AvatarNode) {
        avatarNode?.removeFromParentNode()
        sceneView.scene?.rootNode.addChildNode(node)

        SCNTransaction.begin()
        SCNTransaction.commit()

        avatarNode = node
                
        withAvatar = true
        let bbox = avatarNode!.boundingSphere
        avatarNode!.pivot = SCNMatrix4MakeTranslation(bbox.center.x, bbox.center.y, bbox.center.z)
        
        zoomModel()
    }
    
    func zoomModel() {
        if isZoomed {
            cameraNode.position = SCNVector3(x: 0, y: 0.25, z: 2.2)
        } else {
            cameraNode.position = SCNVector3(x: 0, y: 0.75, z: 0.7)
        }
        self.isZoomed.toggle()
    }

    override func deinitialize() {
        super.deinitialize()
    }
}

extension SCNAvatarViewer {
    override func rotateModel(_ point:CGPoint) {
        avatarTransform = SCNMatrix4Rotate(avatarTransform, DegreeToRadians(point.x / 3), 0, 1, 0)
    }

    override func resetModelPosition() {
        avatarTransform = SCNMatrix4Identity
    }

    func setupScene() {
        let scene = SCNScene()
        cameraNode.camera = SCNCamera()
        cameraNode.name = "camera"
        cameraNode.camera?.zNear = 0.001
        cameraNode.camera?.zFar = 100
        cameraNode.position = SCNVector3(x: 0, y: 0.0, z: 1.5)
        cameraNode.camera?.saturation = 1.2
        scene.rootNode.addChildNode(cameraNode)
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene = scene
    }
}
