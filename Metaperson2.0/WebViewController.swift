/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 * You may not use this file except in compliance with an authorized license
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 * See the License for the specific language governing permissions and limitations under the License.
 * Written by Itseez3D, Inc. <support@itseez3D.com>, July 2023
 */

import Foundation
import UIKit
import WebKit

class WebViewController: UIViewController, WKScriptMessageHandler {
    var avatarExported: ((String) -> ())?
    
    var webView: WKWebView!
    var urlString: String?
    
    override func loadView() {
        let config = WKWebViewConfiguration()
        let script = WKUserScript(source: mobileSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)
        config.userContentController.add(self, name: "iosListener")
        webView = WKWebView(frame: .zero, configuration: config)
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.allowsBackForwardNavigationGestures = true
    }
        
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let body = message.body as? [String:String] {
            if body["eventName"] == "model_exported", let url = body["url"] {
                avatarExported?(url)
            }
        }
    }
    
    func reloadPage(clearHistory : Bool){
        let url = URL(string: urlString!)!
        if clearHistory {
            WebCacheCleaner.clean()
        }
        webView.load(URLRequest(url: url))
    }
}

fileprivate let mobileSource = """
  const CLIENT_ID = "C8v8Rfy722rNULBrCplaHQrviysuUjWrkyHWr6v4";
  const CLIENT_SECRET = "vErhSkjPkXeyAFnEJsw8DBadbKnP1N4f3bmAiAT7ZlsREFp3nmZpM6hWDK7UpcjtgBomWBnLFkvCOCLbtjGM2NPZIIe9Xvb6wFg4pQCFzjGebj8ttLaM21WEFEXCv987";

  document.addEventListener('DOMContentLoaded', function onDocumentReady() {
      window.addEventListener("message", onWindowMessage);
      window.webkit.messageHandlers.iosListener.postMessage(event.data);
  });

  var iframe = document.querySelector('iframe')
  iframe.setAttribute("id", "editor_iframe");
  iframe.setAttribute("allow", "fullscreen");

  var avatarPreset = document.getElementById('avatar-preset')

  function onWindowMessage(evt) {
      if (evt.type === "message") {
          if (evt.data?.source === "metaperson_creator") {
              let data = evt.data;
              let evtName = data?.eventName;
              if (evtName === "mobile_loaded") {
                  onMobileLoaded(evt, data);
                  window.webkit.messageHandlers.iosListener.postMessage(data);
              } else if (evtName === "model_exported"){
                  window.webkit.messageHandlers.iosListener.postMessage(data);
                  avatarPreset.innerText = "model url: " + data.url
              }
          }
      }
  }

  function onMobileLoaded(evt, data) {
      let authenticationMessage = {
          "eventName": "authenticate",
          "clientId": CLIENT_ID,
          "clientSecret": CLIENT_SECRET,
          "exportTemplateCode" : "",
      };
      evt.source.postMessage(authenticationMessage, "*");

      let exportParametersMessage = {
          "eventName": "set_export_parameters",
          "format" : "glb",
          "lod" : 2,
          "textureProfile" : "1K.png"
      };
      evt.source.postMessage(exportParametersMessage, "*");
    }
"""
