//
//  PTGInfoTableViewCell.swift
//  MPLAB PTG
//
//  Created by Minglung on 2022/12/27.
//

import UIKit

class PTGInfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var info: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
