//
//  ContentViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/11/09.
//

import Foundation
import UIKit
import SwiftSoup
import SwiftUI

class ContentViewController: UIViewController {
    @IBOutlet weak var myTextField: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    var contents = ""
    var noticeTitle = ""
    var noticeDate = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let font = UIFont(name: "AppleSDGothicNeo-Regular", size: 15)!
        myTextField.attributedText = contents.htmlEscaped(font: font, colorHex: "#ff6347", lineSpacing: 1.5)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 공지사항 제목과 날짜 설정
        titleLabel.text = noticeTitle
        titleLabel.numberOfLines = 10
        dateLabel.text = noticeDate
    }
}

extension String {
    var HtmlToString: String? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil).string
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
    }
}

extension String {
    func htmlEscaped(font: UIFont, colorHex: String, lineSpacing: CGFloat) -> NSAttributedString {
        let style = """
                    <style>
                    img{
                        width: \(UIScreen.main.bounds.size.width);
                        object-fit: contain;
                        }
                    </style>
        """
        let modified = String(format:"\(style)<p class=normal>%@</p>", self)
        do {
            guard let data = modified.data(using: .unicode) else {
                return NSAttributedString(string: self)
            }
            let attributed = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            return attributed
        } catch {
            return NSAttributedString(string: self)
        }
    }
}
