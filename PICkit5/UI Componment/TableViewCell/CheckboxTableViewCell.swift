//
//  CheckboxTableViewCell.swift
//  PICkit5
//
//  Created by TestPC on 2022/5/20.
//

import UIKit

class CheckboxTableViewCell: UITableViewCell {
    @IBOutlet weak var Check: VKCheckbox!
    @IBOutlet weak var BlankCheck: VKCheckbox!
    @IBOutlet weak var Erase: VKCheckbox!
    @IBOutlet weak var Verify: VKCheckbox!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
