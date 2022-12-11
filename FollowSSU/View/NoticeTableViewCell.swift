//
//  NoticeTableViewCell.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/11/08.
//

import Foundation
import UIKit

class NoticeTableViewCell: UITableViewCell {
    @IBOutlet weak var noticeTextLabel: UILabel!
    @IBOutlet weak var dateTextLabel: UILabel!
    @IBOutlet weak var view: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .white
        self.contentView.backgroundColor = .white
    }
}
