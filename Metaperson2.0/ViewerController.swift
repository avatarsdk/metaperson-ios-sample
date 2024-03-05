/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 *  You may not use this file except in compliance with an authorized license
 *  Unauthorized copying of this file, via any medium is strictly prohibited
 *  Proprietary and confidential
 *  UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 *  CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 *  See the License for the specific language governing permissions and limitations under the License.
 *  Written by Itseez3D, Inc. <support@itseez3D.com>, July 2023
 */

import UIKit
import Combine

class ViewerController: UIViewController {
    var subscriptions = Set<AnyCancellable>()
    @IBOutlet weak var viewer: SCNAvatarViewer!

    var avatarURL: URL?
    var avatarNode: AvatarNode?
    @IBOutlet weak var zoomButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewer.$isZoomed.sink { isZoomed in
            self.zoomButton.setTitle(isZoomed ? "Zoom out" : "Zoom in", for: .normal)
        }.store(in: &subscriptions)

        self.showModel()
    }
    
    func showModel() {
        avatarNode = AvatarNode(avatarURL: avatarURL!)
        viewer.setAvatarNode(avatarNode!)
    }
    
    @IBAction func zoomButtonPressed(_ sender: Any) {
        viewer.zoomModel()
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
}

