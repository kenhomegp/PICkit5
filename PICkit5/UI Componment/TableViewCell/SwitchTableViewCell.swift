//
//  SwitchTableViewCell.swift
//  MPLAB PTG
//
//  Created by Minglung on 2022/11/5.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    @IBOutlet weak var Label: UILabel!
    
    @IBOutlet weak var Switch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
