//
//  OperationTableViewCell.swift
//  PICkit5
//
//  Created by TestPC on 2022/5/13.
//

import UIKit

class OperationTableViewCell: UITableViewCell {

    @IBOutlet weak var operation_image: UIImageView!
    @IBOutlet weak var operation_label: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCell(img_name: String, label: String){
        self.operation_image.image = UIImage(named: img_name)
        self.operation_label.text = label
    }

}
