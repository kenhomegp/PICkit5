//
//  PTGFileTableViewCell.swift
//  MPLAB PTG
//
//  Created by TestPC on 2022/6/10.
//

import UIKit

class PTGFileTableViewCell: UITableViewCell {

    @IBOutlet weak var PTGFileName: UILabel!
    
    @IBOutlet weak var PTGImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
