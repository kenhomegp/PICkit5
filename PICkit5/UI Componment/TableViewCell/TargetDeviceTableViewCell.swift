//
//  TargetDeviceTableViewCell.swift
//  PICkit5
//
//  Created by TestPC on 2022/5/16.
//

import UIKit

class TargetDeviceTableViewCell: UITableViewCell {
    @IBOutlet weak var imageFile: UIImageView!
    
    @IBOutlet weak var deviceName: UILabel!
    
    @IBOutlet weak var selectedFile: UILabel!
    
    @IBOutlet weak var startButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
