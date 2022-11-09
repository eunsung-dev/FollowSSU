//
//  WebViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/11/06.
//

import Foundation
import WebKit

class WebViewController: UIViewController, WKUIDelegate {
    let major: Major = Major()
    let defaults = UserDefaults.standard
    var selectedMajor = ""

    
    var webView: WKWebView!
        
        override func loadView() {
            let webConfiguration = WKWebViewConfiguration()
            webView = WKWebView(frame: .zero, configuration: webConfiguration)
            webView.uiDelegate = self
            view = webView
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            
            if let savedPerson = defaults.object(forKey: "Info") as? Data {
                let decoder = JSONDecoder()
                if let loadedPerson = try? decoder.decode(Student.self, from: savedPerson) {
                    print("불러온 정보: \(loadedPerson)")
                    selectedMajor = loadedPerson.major
                }
            }
            // 저장되어 있는 학과를 토대로 해당 학과 공지사항을 불러온다.
            if let firstIndex = major.allMajors.firstIndex(of: selectedMajor) {
                let myURL = major.allUrls[firstIndex]
                print(major.allUrls[firstIndex])
                let myRequest = URLRequest(url: myURL!)
    //            webView.load(myRequest)
                // 여전히 purple warning
                DispatchQueue.main.async {
                    self.webView.load(myRequest)
                    self.webView.scrollView.isScrollEnabled = false
                }
            }
        }
}
