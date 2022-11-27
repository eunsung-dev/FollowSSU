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
    @IBOutlet weak var myTextField: UITextView!
    var contents = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let font = UIFont(name: "AppleSDGothicNeo-Regular", size: 15)!
        myTextField.attributedText = contents.htmlEscaped(font: font,
                                                                   colorHex: "#ff6347",
                                                                   lineSpacing: 1.5)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        contentLabel.text = contents
//        print(contents)
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
        //        img{ max-height: 100%; max-width: \(UIScreen.main.bounds.size.width) !important; width: auto; height: auto;}
        let modified = String(format:"\(style)<p class=normal>%@</p>", self)
        do {
            guard let data = modified.data(using: .unicode) else {
                return NSAttributedString(string: self)
            }
            let attributed = try NSAttributedString(data: data,
                                                    options: [.documentType: NSAttributedString.DocumentType.html],
                                                    documentAttributes: nil)
            return attributed
        } catch {
            return NSAttributedString(string: self)
        }
    }
}
