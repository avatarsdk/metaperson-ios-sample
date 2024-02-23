/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 * You may not use this file except in compliance with an authorized license
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 * See the License for the specific language governing permissions and limitations under the License.
 * Written by Itseez3D, Inc. <support@itseez3D.com>, July 2023
 */

import UIKit
import WebKit

extension UIViewController {
    class func instantiateFromStoryboard(_ name: String, customVCName: String? = nil) -> Self {
        return instantiateFromStoryboardHelper(name, customVCName: customVCName)
    }

    fileprivate class func instantiateFromStoryboardHelper<T>(_ name: String, customVCName: String? = nil) -> T {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        let identifier = customVCName ?? String(describing: self)
        return storyboard.instantiateViewController(withIdentifier: identifier) as! T
    }
}

final class WebCacheCleaner {
    class func clean() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
}
