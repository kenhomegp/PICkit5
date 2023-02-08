//
//  PTGStatsTableViewCell.swift
//  MPLAB PTG
//
//  Created by Minglung on 2022/11/16.
//

import UIKit

class PTGStatsTableViewCell: UITableViewCell {
    @IBOutlet weak var PTGStat: UILabel!
    @IBOutlet weak var totalCount: UILabel!
    @IBOutlet weak var passCount: UILabel!
    @IBOutlet weak var PTGStatResetButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
