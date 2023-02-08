//
//  CustomViewController.swift
//  MPLAB PTG
//
//  Created by TestPC on 2022/6/11.
//

import UIKit

class CustomViewController: UIViewController {

    @IBOutlet weak var customImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var titleText = String()
    var messageText = String()
    var alertImage = UIImage()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setValues()
    }
    
    private func setValues() {
        customImage.image = alertImage
        titleLabel.text = titleText
        messageLabel.text = messageText
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize.height = messageLabel.frame.size.height + messageLabel.frame.origin.y + 30
        //print("viewDidLayoutSubviews.\(messageLabel.frame.size.height),\(messageLabel.frame.origin.y)")
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UIAlertController {

    convenience init(style: UIAlertController.Style, title: String? = nil, message: String? = nil) {
        self.init(title: title, message: message, preferredStyle: style)
    }
    
    /*
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        //set this to whatever color you like...
        self.view.tintColor = UIColor.red
    }*/

    func addAlertAction(title: String, style: UIAlertAction.Style = .default, handler: ((UIAlertAction) -> Void)? = nil) {
        let action = UIAlertAction(title: title, style: style, handler: handler)
        let color = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
        action.setValue(color, forKey: "titleTextColor")
        addAction(action)
    }

    func setViewController(image: UIImage, title: String, message: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController =
            storyboard.instantiateViewController(withIdentifier: "CustomVC") as? CustomViewController else {
                return
        }
        viewController.alertImage = image
        viewController.titleText = title
        viewController.messageText = message
        setValue(viewController, forKey: "contentViewController")
    }

}
