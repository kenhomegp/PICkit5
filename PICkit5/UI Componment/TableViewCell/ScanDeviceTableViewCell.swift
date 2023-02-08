//
//  ScanDeviceTableViewCell.swift
//  MPLAB PTG
//
//  Created by Minglung on 2022/11/15.
//

import UIKit

class ScanDeviceTableViewCell: UITableViewCell {

    @IBOutlet weak var deviceImage: UIImageView!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var deviceRSSI: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
