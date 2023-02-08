//
//  LaunchViewController.swift
//  MPLAB PTG
//
//  Created by TestPC on 2022/9/2.
//

import UIKit

class LaunchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        print("LaunchViewController.viewDidLoad")
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
            
        leftSwipe.direction = .left
        rightSwipe.direction = .right

        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("LaunchViewController.viewWillAppear")
        
        self.navigationController?.isNavigationBarHidden = true
        
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.AppLaunched != nil){
            if let appLaunch = appDelegate.AppLaunched{
                if(appLaunch){
                    appDelegate.AppLaunched = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if((self.navigationController?.visibleViewController?.isKind(of: LaunchViewController.self)) == true){
                            print("Perform PICkit5Start segue.")
                            self.performSegue(withIdentifier: "PK5Start", sender: self)
                        }
                    }
                }
            }
        }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer){
        print(#function)
        self.performSegue(withIdentifier: "PK5Start", sender: self)
    }
    
    @objc func handleSwipes(_ sender: UISwipeGestureRecognizer)
    {
        if sender.direction == .left
        {
           print("Swipe left")
           // show the view from the right side
            self.performSegue(withIdentifier: "PK5Start", sender: self)
        }

        if sender.direction == .right
        {
           print("Swipe right")
           // show the view from the left side
            self.performSegue(withIdentifier: "PK5Start", sender: self)
        }
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
