//
//  DeviceSetupVC.swift
//  MPLAB PTG
//
//  Created by Minglung on 2022/11/18.
//

import UIKit

class DeviceSetupVC: UIViewController, UITableViewDelegate, UITableViewDataSource, bleUARTCallBack  {
    
    @IBOutlet weak var BrowseButton: UIButton!
    
    @IBOutlet weak var ProgramButton: UIButton!
    
    @IBOutlet weak var PK5Status: UITableView!
    
    @IBOutlet weak var PK5Control: UITableView!
    
    var bleUart : bleUART?
    
    var SelectedPeripheral : String!
    
    var PTGActiveFile = ""
    
    var PTGStatus = Data()
    
    var PTGMode: UInt8 = 2
    
    var SDCardStatus = ""
    
    var appFwVer = ""
    
    var ToggleSwitch = false
    
    var PTGState: PICkit_OpCode = .BLE_PTG_INIT
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "PICkit5 Status"
        
        PK5Status.delegate = self
        PK5Status.dataSource = self
        PK5Status.separatorStyle = .none
        
        PK5Control.delegate = self
        PK5Control.dataSource = self
        PK5Control.separatorStyle = .none
        
        #if !targetEnvironment(simulator)
            if bleUart == nil{
                bleUart = bleUART.sharedInstace(option: .Normal)
            }
        #endif

        //print("view size = \(self.view.frame.width),\(self.view.frame.height)")
        //self.PK5Status.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        
        if #available(iOS 15.0, *){
            PK5Status.sectionHeaderTopPadding = 0
            PK5Control.sectionHeaderTopPadding = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
        
        PTGState = .BLE_PTG_INIT
    
        #if !targetEnvironment(simulator)
            self.bleUart?.callback = self
            if(appFwVer == ""){
                BLE_PTG_STATUS()
            }
        
            if(bleUart?.PTGImage != "" && self.PTGActiveFile != ""){
                let ptg = bleUart?.PTGImage
                if(ptg! != self.PTGActiveFile){
                    self.PTGActiveFile = ptg!
                    print("Update Active PTG image")
                    PK5Status.reloadData()
                }
            }
        #endif

    }
    
    func BLE_PTG_STATUS(){
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_STATUS, commandData: Data(), completion: {(error)in
            print("BLE_PTG_STATUS")
            if error != nil{
                print("Error = \(error ?? "")")
                
            }
            else{
                print("Success")
            }
        })
    }
    
    func BLE_PTG_INIT(){
        
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_INIT, commandData: Data(), completion: {(error)in
            print("BLE PTG INIT ")
            if error != nil{
                print("Error = \(error ?? "")")
                if((error?.contains("/")) != nil){
                    let errors = error?.split(separator: "/")
                    if(errors?.count == 2){
                        self.PICkit_Custom_Alert(title: String(errors![0]), content: String(errors![1]), oneButton: true, image: "error")
                    }
                }
            }
            else{
                print("Success")
                if(self.ToggleSwitch){
                    self.ToggleSwitch = false
                    self.BLE_PTG_STATUS()
                }
            }
        })
    }
    
    func BLE_PTG_UNINIT(){
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_UNINIT, commandData: Data(), completion: {(error)in
            print("BLE_PTG_UNINIT")
            if error != nil{
                print("Error = \(error ?? "")")
            }
            else{
                print("Success")
                
                if(self.ToggleSwitch){
                    self.ToggleSwitch = false
                    self.BLE_PTG_STATUS()
                }
            }
        })
    }
    
    func BLE_PTG_ACTIVE_IMAGE(){
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_ACTIVE_IMAGE, commandData: Data(), completion: {(error)in
            print("BLE_PTG_ACTIVE_IMAGE")
            if error != nil{
                print("Error = \(error ?? "")")
            }
            else{
                print("Success")
            }
        })
    }
    
    func BLE_PTG_LOAD_IMAGE(){
        let data = Data(PTGActiveFile.utf8)
        print("PTG image = \(PTGActiveFile), \(data as NSData)")
        
        if(PTGState != .BLE_PTG_LOAD_IMAGE){
            PTGState = .BLE_PTG_LOAD_IMAGE
            bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_LOAD_IMAGE, commandData: data, completion: {(error)in
                print(#function)
                if error != nil{
                    print("Error = \(error ?? "")")
                    self.PTGState = .BLE_PTG_INIT
                }
                else{
                    print("Success")
                    self.performSegue(withIdentifier: "ProgramSegue", sender: self)
                    
                }
            })
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
        //alertView.view.tintColor = .darkGray
    }
    
    @objc func TogglePTGInitCommand(){
        //print(#function)
        
        #if !targetEnvironment(simulator)
        if(PTGMode == 0){
            //switch is off
            BLE_PTG_INIT()
        }else{
            BLE_PTG_UNINIT()
        }
        
        ToggleSwitch = true
        #endif
    }
    
    @IBAction func TapProgramBtn(_ sender: Any) {
        print(#function)
        #if !targetEnvironment(simulator)
        //print("PK5 opcode = \(bleUart!.PICkitCommand)")
        
        if(PTGActiveFile != ""){
            //print(#function)
            
            BLE_PTG_LOAD_IMAGE()
        }
        #else
        PTGActiveFile = "test.ptg"
        self.performSegue(withIdentifier: "ProgramSegue", sender: self)
        #endif
    }
    
    @IBAction func TapBrowseSDCardBtn(_ sender: Any) {
        print(#function)
        self.performSegue(withIdentifier: "FileManagerSegue", sender: self)
    }
    
    @IBAction func unwindToDeviceSetup(_ unwindSegue: UIStoryboardSegue) {
        //let sourceViewController = unwindSegue.source
        // Use data from the view controller which initiated the unwind segue
        if let sourceVC = unwindSegue.source as? FileManagerViewController{
            print("unwindToDeviceSetup. \(sourceVC.SelectedFile)")
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "ProgramSegue"{
            let vc = segue.destination as! StatusViewController
            vc.SelectedPeripheral = self.SelectedPeripheral
            vc.SelectedFile = self.PTGActiveFile
        }
        else if segue.identifier == "FileManagerSegue"{
            let vc = segue.destination as! FileManagerViewController
            vc.SelectedPeripheral = self.SelectedPeripheral
            vc.PTGActiveFile = self.PTGActiveFile
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        if(tableView == PK5Status){
            return 5
            //return 4
        }
        else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var height = 0.0
        if(tableView == PK5Status){
            if(section == 0){
                height = 80
            }
            else{
                height = 5
            }
        }
        return height
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == PK5Status){
            if(section == 0 || section == 4){
                return 0
            }else{
                return 1
            }
        }
        else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(tableView == PK5Status){
            //let cellColor = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
            if(section == 0){
                /*
                let cell = tableView.dequeueReusableCell(withIdentifier: "SectionLabelCell") as! SectionLabelTableViewCell
                //cell.backgroundColor = cellColor
                cell.backgroundColor = .clear
                 */
                let cell = tableView.dequeueReusableCell(withIdentifier: "PickitInfo") as! PTGInfoTableViewCell
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "SeparatorLine")
                return cell
            }
        }
        else{
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cellColor = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
        if(tableView == PK5Status){
            tableView.isUserInteractionEnabled = false
            let cellColor = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
        
            let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigurationCell") as! ConfigurationTableViewCell
            //cell.backgroundColor = cellColor
            cell.backgroundColor = .clear
            //cell.configLabel.textColor = UIColor.white
            cell.configLabel.textColor = .black
            cell.accessoryType = .none
            
            if(indexPath.section == 1){
                #if !targetEnvironment(simulator)
                cell.configLabel.text = "PICkit5 firmware version: " + appFwVer
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    
                    cell.configLabel.text! += "\nAPP version: v"
                    cell.configLabel.text! += version
                }
                
                if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    
                    //cell.configLabel.text! += "."
                    //cell.configLabel.text! += build
                    print("build number = \(build)")
                }
                
                #else
                cell.configLabel.text = "PICkit5 firmware version: v0.0.0.1" + "\nAPP version: v0.3.4"
                #endif
            }
            else if(indexPath.section == 2){
                #if !targetEnvironment(simulator)
                cell.configLabel.text = "Micro SD card: " + SDCardStatus
                #else
                cell.configLabel.text = "Micro SD card: Detected"
                #endif
            }else{
                #if !targetEnvironment(simulator)
                //cell.configLabel.textColor = UIColor.white
                //cell.configLabel.textColor = .black
                cell.configLabel.text = "Active PTG image: " + PTGActiveFile
                #else
                cell.configLabel.text = "Active PTG image: test.ptg"
                #endif
            }
            
            #if !targetEnvironment(simulator)
            if(SDCardStatus == "Ready to browse"){
                if(PTGMode == 1){
                    BrowseButton.isEnabled = true
                }
                else{
                    BrowseButton.isEnabled = false
                }
            }
            else{
                BrowseButton.isEnabled = false
            }
            #endif

            #if !targetEnvironment(simulator)
            if(PTGMode == 1){
                if(PTGActiveFile != ""){
                    ProgramButton.isEnabled = true
                }
                else{
                    ProgramButton.isEnabled = false
                }
            }
            else{
                ProgramButton.isEnabled = false
            }
            #endif
            
            return cell
        }
        else{
            //let cellColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as! SwitchTableViewCell
            //cell.backgroundColor = cellColor
            cell.backgroundColor = .clear
            //cell.Label.textColor = UIColor.white
            cell.Label.textColor = .black
            
            #if !targetEnvironment(simulator)
            if(PTGMode == 0){
                cell.Switch.isOn = false
            }
            else{
                cell.Switch.isOn = true
            }
            #else
                cell.Switch.isOn = false
            #endif
            cell.Switch.isEnabled = true
            cell.Switch.addTarget(self, action: #selector(DeviceSetupVC.TogglePTGInitCommand), for: .valueChanged)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("[didSelectRowAt]Select device:\(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - bleUARTCallBack delegate
    func bleDidDisconnect(error:String){
        let okHandler: ((UIAlertAction) -> Void)? = { (_) in
            self.performSegue(withIdentifier: "SetupDidDisconnect", sender: self)
        }
        print("bleDidDisconnect, error = \(error)")
        
        self.PICkit_Custom_Alert(title: "BLE disconnected!", content: error, oneButton: true, image: "X-icon", ok_handler: okHandler, cancel_handler: nil)
    }

    func bleProtocolError(title: String, message: String){
        print("bleProtocolError.\(title),\(message)")
        
        if(title == "BLE_PTG_ACTIVE_IMAGE"){
            self.PICkit_Custom_Alert(title: "No active PTG image", content: "Please browse the SD card and load the image", oneButton: true, image: "X-icon")
        }
        else{
            self.PICkit_Custom_Alert(title: title, content: message, oneButton: true, image: "X-icon")
        }
        
        if(title == "BLE_PTG_INIT" || title == "BLE_PTG_STATUS"){
            PTGMode = 0
            PK5Status.reloadData()
            PK5Control.reloadData()
        }
    }
    
    func bleCommandResponseData(command: UInt8, data: Any){
        print("[SetupVC] bleCommandResponseData")
        if(command == PICkit_OpCode.BLE_PTG_STATUS.rawValue){
            if data is Data{
                PTGStatus = data as! Data
                let status = data as! Data
                if status.count == 6{
                    print("PK5 status data = \(PTGStatus as NSData)")
                    appFwVer = String.init(format: "v%02x.%02x.%02x.%02x", status[3],status[2],status[1],status[0])
                    
                    print("appFwVer = " + appFwVer)
                    PTGMode = status[5]
                    if(status[4] == 0){
                        SDCardStatus = "Ready to browse"
                    }
                    else if(status[4] == 2){
                        SDCardStatus = "Not detected"
                    }
                    else if(status[4] == 4){
                        SDCardStatus = "Not accessible"
                    }
                    
                    self.PK5Status.reloadData()
                    self.PK5Control.reloadData()
                    
                    if(PTGMode == 0x01 && PTGActiveFile == ""){
                        if(status[4] == 0){
                            self.BLE_PTG_ACTIVE_IMAGE()
                        }
                    }
                }
            }
        }
        else if(command == PICkit_OpCode.BLE_PTG_ACTIVE_IMAGE.rawValue){
            if data is String{
                PTGActiveFile = data as! String
                print("file data = \(PTGActiveFile)")
                self.PK5Status.reloadData()
            }
        }
    }
}
