/* Copyright (C) Itseez3D, Inc. - All Rights Reserved
 * You may not use this file except in compliance with an authorized license
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * UNLESS REQUIRED BY APPLICABLE LAW OR AGREED BY ITSEEZ3D, INC. IN WRITING, SOFTWARE DISTRIBUTED UNDER THE LICENSE IS DISTRIBUTED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED
 * See the License for the specific language governing permissions and limitations under the License.
 * Written by Itseez3D, Inc. <support@itseez3D.com>, May 2017
 */

import Foundation
import UIKit
import Zip
import SwiftUI
import Combine

enum DownloadingState {
    case none
    case downloading(Float)
    case downloaded
    case failed(Error)
}

class MainController: UIViewController {
    private var subscriptions = Set<AnyCancellable>()
    @IBOutlet weak var makePhotoButton: UIButton!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var progressInfoView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    
    var observation: NSKeyValueObservation?
    
    var state = DownloadingState.none {
        didSet {
            switch state {
            case .none:
                progressInfoView.isHidden = true
            case .downloading(let progress):
                progressInfoView.isHidden = false
                progressView.isHidden = false
                progressView.progress = progress
                progressLabel.text = "Downloading"
            case .downloaded:
                progressInfoView.isHidden = false
                progressView.isHidden = true
                progressLabel.text = "Downloaded"
            case .failed:
                progressInfoView.isHidden = false
                progressView.isHidden = true
                progressLabel.text = "Failed"
            }
        }
    }
    
    @AppStorage("avatarZipURL") var avatarZipPath: String = "" {
        didSet {
            state = .none
            updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloadButton.isHidden = true
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelURL = documentsURL.appendingPathComponent("model")

        state = fileManager.fileExists(atPath: modelURL.path) ? .downloaded : .none
        updateUI()
    }
    
    func updateUI() {
        downloadButton.isHidden = avatarZipPath.isEmpty
        urlLabel.isHidden = avatarZipPath.isEmpty
        urlLabel.text = avatarZipPath
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func makePhotoButtonPressed(_ sender: Any) {
        observation?.invalidate()
        
        let webViewController = createWebView(url: "https://mobile.metaperson.avatarsdk.com")
        webViewController.loadViewIfNeeded()
        navigationController?.pushViewController(webViewController, animated: true)
        webViewController.reloadPage(clearHistory: true)
    }
    
    @IBAction func downloadButtonPressed(_ sender: Any) {
        guard let url = URL(string: avatarZipPath) else { return }
        
        self.state = .downloading(0)
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let archiveURL = documentsURL.appendingPathComponent("archive.zip")
        let modelURL = documentsURL.appendingPathComponent("model")
        try? fileManager.removeItem(at: archiveURL)
        try? fileManager.removeItem(at: modelURL)
        downloadFile(from: url, to: archiveURL) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.state = .failed(error)
                } else {
                    try? Zip.unzipFile(archiveURL, destination: modelURL, overwrite: true, password: nil)
                    self.state = .downloaded
                }
            }
        }
    }

    
    func createWebView(url: String) -> WebViewController {
        let webViewController = WebViewController.instantiateFromStoryboard("Main")

        webViewController.avatarExported = { path in
            self.navigationController?.popViewController(animated: true)
            self.avatarZipPath = path
        }
        webViewController.urlString = url
        
        return webViewController
    }
    
    func downloadFile(from url: URL, to destinationURL: URL, completion: @escaping (Error?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (temporaryURL, response, error) in
            if let error = error {
                completion(error)
                return
            }
            
            guard let temporaryURL = temporaryURL else {
                let error = NSError(domain: "com.example.DownloadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create temporary file URL."])
                completion(error)
                return
            }
            
            do {
                let fileManager = FileManager.default
                try fileManager.moveItem(at: temporaryURL, to: destinationURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
        
        observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                self.state = .downloading(Float(progress.fractionCompleted))
            }
        }
        
        task.resume()
    }
}
