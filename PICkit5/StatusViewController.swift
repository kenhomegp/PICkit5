//
//  StatusViewController.swift
//  PICkit5
//
//  Created by TestPC on 2022/5/3.
//

import UIKit

class StatusViewController: UIViewController, bleUARTCallBack, UITableViewDelegate, UITableViewDataSource {
    var bleUart : bleUART?
    
    var SelectedFile : String!
    
    var SelectedPeripheral : String!
    
    var OperationCommand : String!
    
    var ProgramStats = ""
    
    var TotalCount = ""
    
    var PassCount = ""
    
    var PTGRun = false

    @IBOutlet weak var deviceLog: UITextView!
    
    @IBOutlet weak var statusHeader: UITableView!
    
    @IBOutlet weak var PTGRunButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Operation"
        
        statusHeader.delegate = self
        statusHeader.dataSource = self
        
        statusHeader.separatorColor = .white
        
        #if !targetEnvironment(simulator)
            if bleUart == nil{
                bleUart = bleUART.sharedInstace(option: .Normal)
            }
        #endif
        
        let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        deviceLog.layer.borderWidth = 5.0
        deviceLog.layer.borderColor = borderColor.cgColor
        deviceLog.layer.cornerRadius = 10.0
        
        deviceLog.isEditable = false
        
        self.view.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        self.statusHeader.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
    
        #if !targetEnvironment(simulator)
            self.bleUart?.callback = self
            if(SelectedFile != ""){
                BLE_PTG_GET_IMAGE_STATS()
            }
        #endif
        
        print("[StatusVC]Selected peripheral = \(self.SelectedPeripheral ?? "")")
    }
    
    func BLE_PTG_GO(){
        PTGRunButton.isEnabled = false
        
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_GO, commandData: Data(), completion: {(error)in
            print(#function)
            self.PTGRun = false
            if error != nil{
                self.PTGRunButton.isEnabled = true
                print("Failed!")
                self.BLE_PTG_REINIT()
            }
            else{
                self.PTGRunButton.isEnabled = true
                print("PTG_GO Success")
                self.BLE_PTG_GET_IMAGE_STATS()
                self.PICkit_Custom_Alert(title: "PTG", content: "Programming success", oneButton: true, image: "Logo")
            }
        })
    }
    
    func BLE_PTG_REINIT(){
        //print(#function)
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_REINIT, commandData: Data(), completion: {(error)in
            print("BLE_PTG_REINIT")
            if error != nil{
                print("Error = \(error ?? "")")
                if((error?.contains("/")) != nil){
                    let errors = error?.split(separator: "/")
                    if(errors?.count == 2){
                        let okHandler: ((UIAlertAction) -> Void)? = { (_) in
                            self.performSegue(withIdentifier: "StatusDidDisconnect", sender: self)
                        }
                        self.PICkit_Custom_Alert(title: String(errors![0]), content: String(errors![1]), oneButton: true, image: "X-icon", ok_handler: okHandler, cancel_handler: nil)
                    }
                }
            }
            else{
                print("Success")
                self.BLE_PTG_GET_IMAGE_STATS()
            }
            //self.BLE_PTG_GET_IMAGE_STATS()
        })
    }
    
    func BLE_PTG_GET_IMAGE_STATS(){
        let data = Data(SelectedFile.utf8)
        print("PTG image = \(SelectedFile), \(data as NSData)")
        
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_GET_IMAGE_STATS, commandData: data, completion: {(error)in
            print(#function)
            if error != nil{
                print("Error = \(error ?? "")")
            }
            else{
                print("Success")
            }
        })
    }
    
    func BLE_PTG_SET_IMAGE_STATS(){
        var dat = Data()
        for _ in 0..<8{
            dat.append(0x00)
        }
        let file = Data(SelectedFile.utf8)
        dat.append(file)
        print("BLE_PTG_SET_IMAGE_STATS. data = \(dat as NSData)")
        
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_SET_IMAGE_STATS, commandData: dat, completion: {(error)in
            print(#function)
            if error != nil{
                print("Error = \(error ?? "")")
            }
            else{
                print("Success")
            }
            self.BLE_PTG_GET_IMAGE_STATS()
        })
    }
    
    func ShowToast(message: String){
        
        let alertView = UIAlertController(style: .alert)
        
        alertView.setViewController(image: UIImage(named: "Logo")!, title: message, message: "")
        
        present(alertView, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                alertView.dismiss(animated: true, completion: nil)
                if(!self.deviceLog.text.isEmpty){
                    self.deviceLog.text.removeAll()
                }
                self.PTGRun = true
                self.statusHeader.reloadData()
                self.BLE_PTG_GO()
            }
        }
    }
    
    func PICkit_Custom_Alert(title:String, content: String, oneButton:Bool, image: String, ok_handler: ((UIAlertAction) -> Void)? = nil, cancel_handler: ((UIAlertAction) -> Void)? = nil){
        let alertView = UIAlertController(style: .alert)
        
        alertView.setViewController(image: UIImage(named: image)!, title: title, message: content)
        
        if oneButton{
            alertView.addAlertAction(title: "Ok", style: .default, handler: ok_handler)
        }
        else{
            alertView.addAlertAction(title: "Ok", style: .default, handler: ok_handler)
            alertView.addAlertAction(title: "Cancel", style: .default, handler: cancel_handler)
        }
        present(alertView, animated: true, completion: nil)
    }
    
    @IBAction func RunButtonTapped(_ sender: Any) {
        #if !targetEnvironment(simulator)
            ShowToast(message: "Programming started!")
            /*
            if(!self.deviceLog.text.isEmpty){
                self.deviceLog.text.removeAll()
            }
            PTGRun = true
            statusHeader.reloadData()
            BLE_PTG_GO()
             */
            /*
            let okHandler: ((UIAlertAction) -> Void)? = { (_) in
                if(!self.deviceLog.text.isEmpty){
                    self.deviceLog.text.removeAll()
                }
                self.PTGRun = true
                self.statusHeader.reloadData()
                self.BLE_PTG_GO()
            }
            self.PICkit_Custom_Alert(title: "Programming started!", content: "", oneButton: true, image: "Logo", ok_handler: okHandler, cancel_handler: nil)
             */
        #else
            PTGRun = !PTGRun
            statusHeader.reloadData()
        #endif
    }
    
    @objc func ClickOperationButton() {
        #if !targetEnvironment(simulator)
        if(!PTGRun){
            print(#function)
        
            self.TotalCount = ""
            self.PassCount = ""
        
            BLE_PTG_SET_IMAGE_STATS()
        }
        #endif
    }
    
    @IBAction func NextStep(_ sender: Any) {
        self.performSegue(withIdentifier: "StatusDidDisconnect", sender: self)
    }
    
    // MARK: - TableView delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    /*
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        if(section == 0){
            //return 80
            return 50
        }
        else{
            return 5
        }
    }*/
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //return 70
        if(indexPath.row == 2){
            return 110
        }
        else{
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PTGInfo") as! PTGFileTableViewCell
        
        cell.backgroundColor = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
        
        if indexPath.row == 0{
            cell.PTGImage.image = UIImage(named: "Device-icon")
            cell.PTGFileName.text = self.SelectedPeripheral
            cell.isUserInteractionEnabled = false
            return cell
        }
        else if indexPath.row == 1{
            cell.PTGImage.image = UIImage(named: "File-icon")
            cell.isUserInteractionEnabled = false
            cell.PTGFileName.text = self.SelectedFile
            return cell
        }
        else{
            let ptgStatCell = tableView.dequeueReusableCell(withIdentifier: "PTGStats") as! PTGStatsTableViewCell
            
            ptgStatCell.totalCount.text = TotalCount
            ptgStatCell.passCount.text = PassCount
            
            ptgStatCell.backgroundColor = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
            
            if(self.ProgramStats == ""){
                ptgStatCell.PTGStatResetButton.backgroundColor = UIColor(red: 0.96, green: 0.55, blue: 0.17, alpha: 1.00)//#f68d2c
                
                ptgStatCell.PTGStatResetButton.addTarget(self, action: #selector(StatusViewController.ClickOperationButton), for: .touchUpInside)
                ptgStatCell.PTGStat.text = "Programming statistics"
            }
            
            if PTGRun{
                ptgStatCell.PTGStatResetButton.isEnabled = false
                ptgStatCell.PTGStatResetButton.setTitleColor(.gray, for: .normal)
            }
            else{
                ptgStatCell.PTGStatResetButton.isEnabled = true
                ptgStatCell.PTGStatResetButton.setTitleColor(.white, for: .normal)
            }
            return ptgStatCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if let cell = tableView.cellForRow(at: indexPath){
            if(cell.reuseIdentifier == "PTGStats"){
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        print("[StatusViewController]segue id = \(segue.identifier ?? "")")
    }
    
    // MARK: - bleUARTCallBack delegate
    func bleDidDisconnect(error:String){
        let okHandler: ((UIAlertAction) -> Void)? = { (_) in
            self.performSegue(withIdentifier: "StatusDidDisconnect", sender: self)
        }
        print("bleDidDisconnect, error = \(error)")
        
        self.PICkit_Custom_Alert(title: "BLE disconnected!", content: error, oneButton: true, image: "X-icon", ok_handler: okHandler, cancel_handler: nil)
    }

    func bleProtocolError(title: String, message: String){
        print("[bleUARTCallBack] bleProtocolError")
        self.PICkit_Custom_Alert(title: title, content: message, oneButton: true, image: "X-icon")
    }
    
    func bleCommandResponse(command: UInt8, data: Data){
        //print("[bleUARTCallBack] bleCommandResponse")
        
        if(command == PICkit_OpCode.BLE_PTG_GO.rawValue){
            print("[bleUARTCallBack] BLE_PTG_GO_Response")
            
            deviceLog.insertText(String(decoding: data, as: UTF8.self))
            
            if let log = deviceLog.text{
                if(log.lowercased().contains("fail")){
                    print("Programming failed")
                    //bleUart?.CancelTimer()
                    bleUart?.PICkit_WriteCommandResponse(result: false)
                }
                else if((log.lowercased().contains("pass")) || (log.lowercased().contains("success"))){
                    //bleUart?.CancelTimer()
                    print("Programming success")
                }
            }
        }
    }
    
    func bleCommandResponseData(command: UInt8, data: Any){
        if(command == PICkit_OpCode.BLE_PTG_GET_IMAGE_STATS.rawValue){
            if data is Data{
                print("[bleUARTCallBack] BLE_PTG_GET_IMAGE_STATS_Response")

                let dat = data as! Data
                
                let array1 : [UInt8] = [dat[3], dat[2], dat[1], dat[0]]
                var value1 : UInt32 = 0
                let data1 = NSData(bytes: array1, length: 4)
                data1.getBytes(&value1, length: 4)
                value1 = UInt32(bigEndian: value1)
                print("total_count = \(value1)")
                
                let array2 : [UInt8] = [dat[7], dat[6], dat[5], dat[4]]
                var value2 : UInt32 = 0
                let data2 = NSData(bytes: array2, length: 4)
                data2.getBytes(&value2, length: 4)
                value2 = UInt32(bigEndian: value2)
                print("pass_count = \(value2)")
                
                //ProgramStats = "Program stats(Total/Pass): " + String(value1) + "/" + String(value2)
                
                if(value1 >= value2){
                    TotalCount = "Total count: " + String(value1)
                    PassCount = "Pass count: " + String(value2)
                    self.statusHeader.reloadData()
                }
            }
        }
    }
}
