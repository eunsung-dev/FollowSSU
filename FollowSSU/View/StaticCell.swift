//
//  StaticCell.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/12/04.
//

import Foundation
import UIKit

class StaticCell: UITableViewCell {
    @IBOutlet weak var staticLabel: UILabel!
    @IBOutlet weak var view: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .white
        self.contentView.backgroundColor = .white
    }
}
