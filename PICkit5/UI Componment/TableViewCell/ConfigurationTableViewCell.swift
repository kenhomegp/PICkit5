//
//  ConfigurationTableViewCell.swift
//  PICkit5
//
//  Created by TestPC on 2022/5/19.
//

import UIKit

class ConfigurationTableViewCell: UITableViewCell {
    @IBOutlet weak var configLabel: UILabel!
    @IBOutlet weak var configView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
