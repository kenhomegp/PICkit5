//
//  ButtonTableViewCell.swift
//  MPLAB PTG
//
//  Created by Minglung on 2022/11/7.
//

import UIKit

class ButtonTableViewCell: UITableViewCell {
    @IBOutlet weak var LeftButton: UIButton!
    @IBOutlet weak var RightButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //LeftButton.backgroundColor = UIColor(red: 0.96, green: 0.55, blue: 0.17, alpha: 1.00)//#f68d2c
        
        //RightButton.backgroundColor = UIColor(red: 0.96, green: 0.55, blue: 0.17, alpha: 1.00)//#f68d2c
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
