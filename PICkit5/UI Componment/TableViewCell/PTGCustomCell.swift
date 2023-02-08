//
//  PTGCustomCell.swift
//  MPLAB PTG
//
//  Created by TestPC on 2022/8/26.
//

import UIKit

class PTGCustomCell: UITableViewCell {
    @IBOutlet weak var BackButton: UIButton!
    
    @IBOutlet weak var Path: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
