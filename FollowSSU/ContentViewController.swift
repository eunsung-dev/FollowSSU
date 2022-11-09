//
//  ContentViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/11/09.
//

import Foundation
import UIKit
import SwiftSoup

class ContentViewController: UIViewController {
    @IBOutlet weak var contentLabel: UILabel!
    var contents = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        contentLabel.numberOfLines = 0
        contentLabel.text = contents
        print(contents)
    }
    
    // MARK: - 내용 가져오기
    func fetchContent(_ url: URL?) {
        if let url = url {
            do {
                let webString = try String(contentsOf: url)
                let document = try SwiftSoup.parse(webString)
                print("########## 가져온 내용 ##########")
                let contents = try document.getElementsByClass("content").select("p").array()
                for c in contents {
                    print(try c.text())
                }
            } catch let error {
                print(error)
            }
        }
    }
}
