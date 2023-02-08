//
//  DeviceSetupTableViewController.swift
//  PICkit5
//
//  Created by TestPC on 2022/5/16.
//

import UIKit

class DeviceSetupTableViewController: UITableViewController, bleUARTCallBack {
    
    var bleUart : bleUART?
    
    //var SelectedFile : String!
    
    var SelectedPeripheral : String!
    
    var PTGActiveFile = ""
    
    var PTGStatus = Data()
    
    var PTGMode: UInt8 = 2
    
    var SDCardStatus = ""
    
    var appFwVer = ""
    
    var ToggleSwitch = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        print("[DeviceSetupTableViewController]viewDidLoad")
        
        /*
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Logo")
        imageView.contentMode = .scaleAspectFit
        navigationItem.titleView = imageView
        */
        navigationItem.title = "PICkit5 Status"
        
        //print("Selected file = \(self.SelectedFile ?? "")")
        
        #if !targetEnvironment(simulator)
            if bleUart == nil{
                bleUart = bleUART.sharedInstace(option: .Normal)
            }
        #endif
        
        print("view size = \(self.view.frame.width),\(self.view.frame.height)")
        self.tableView.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
    
        #if !targetEnvironment(simulator)
            self.bleUart?.callback = self
            if(appFwVer == ""){
                BLE_PTG_STATUS()
            }
            //BLE_PTG_UNINIT()
        #endif
        
        print("[SetupVC]Selected peripheral = \(self.SelectedPeripheral ?? "")")
    }
    
    func BLE_PTG_STATUS(){
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_STATUS, commandData: Data(), completion: {(error)in
            print("BLE_PTG_STATUS")
            if error != nil{
                print("Error = \(error ?? "")")
                
            }
            else{
                print("Success")
                
                //self.GetPTGImage()
                //print("PTG_INIT")
                //self.BLE_PTG_INIT()
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
                        /*
                        let okHandler: ((UIAlertAction) -> Void)? = { (_) in
                            self.navigationController?.popViewController(animated: true)
                        }
                        self.PICkit_Custom_Alert(title: String(errors![0]), content: String(errors![1]), oneButton: true, image: "error", ok_handler: okHandler, cancel_handler: nil)
                         */
                    }
                }
            }
            else{
                print("Success")
                //self.PTGState = .BLE_PTG_INIT
                //self.GetPTGImage()
                
                //sleep(1)
                //self.BLE_PTG_BROWSE_SD_CARD()
                
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
        
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_LOAD_IMAGE, commandData: data, completion: {(error)in
            print(#function)
            if error != nil{
                print("Error = \(error ?? "")")
            }
            else{
                print("Success")
                self.performSegue(withIdentifier: "ProgramSegue", sender: self)
            }
        })
    }

    /*
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let headerView = tableView.tableHeaderView else {return}
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
            tableView.layoutIfNeeded()
        }
    }*/
    
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
    
    @objc func ClickStartButton() {
        print(#function)
        self.performSegue(withIdentifier: "OperationSegue", sender: self)
    }
    
    @objc func TapBrowseSDCardButton(){
        print(#function)
        //FileManagerSegue
        self.performSegue(withIdentifier: "FileManagerSegue", sender: self)
    }
    
    @objc func TapProgramButton(){
        #if !targetEnvironment(simulator)
        if(PTGActiveFile != ""){
            print(#function)
            
            BLE_PTG_LOAD_IMAGE()

        }
        #else
        //SelectedFile = "test.ptg"
        PTGActiveFile = "test.ptg"
        self.performSegue(withIdentifier: "ProgramSegue", sender: self)
        #endif
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
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 10
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
        /*
        if(indexPath.row == 2){
            return 60
        }
        return 40*/
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(section == 0){
            //return 115
            return 100
        }
        else if(section == 1 || section == 3 || section == 5){
            return 5
        }
        else if(section == 7 || section == 9){
            return 5
        }
        else{
            return 50
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        if(section == 9){
            return 1
        }
        return 0
        
        /*
        if(section == 2){
            return 3
        }
        else{
            return 0
        }*/
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let cellColor = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
        //let cellColor = UIColor.white
        
        //let seperatorColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        
        //let rect = tableView.rect(forSection: section)
        //print("section=\(section), origin = \(rect.origin)")
        
        //print("section = \(section)")
        if(section == 0){
            let cell = tableView.dequeueReusableCell(withIdentifier: "SectionLabelCell") as! SectionLabelTableViewCell
            cell.backgroundColor = cellColor
            return cell
        }
        else if(section == 2){
            let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigurationCell") as! ConfigurationTableViewCell
            cell.backgroundColor = cellColor
            cell.configLabel.textColor = UIColor.white
            
            #if !targetEnvironment(simulator)
            cell.configLabel.text = "PICkit5 firmware version: " + appFwVer
            #else
            cell.configLabel.text = "PICkit5 firmware version: v0.0.0.1"
            #endif
            cell.accessoryType = .none
            return cell
        }
        else if(section == 4){
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as! SwitchTableViewCell
            cell.backgroundColor = cellColor
            cell.Label.textColor = UIColor.white
            
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
            cell.Switch.addTarget(self, action: #selector(DeviceSetupTableViewController.TogglePTGInitCommand), for: .valueChanged)
            return cell
        }
        else if(section == 6 || section == 8){
            let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigurationCell") as! ConfigurationTableViewCell
            cell.backgroundColor = cellColor
            cell.configLabel.textColor = UIColor.white
            
            if(section == 6){
                #if !targetEnvironment(simulator)
                /*
                if(PTGStatus.count == 6){
                    let status = PTGStatus[4]
                    print("SD card status = \(status)")
                    cell.configLabel.text = "Micro SD card: "
                }*/
                cell.configLabel.text = "Micro SD card: " + SDCardStatus
                #else
                cell.configLabel.text = "Micro SD card: Detected"
                #endif
            }
            else{
                #if !targetEnvironment(simulator)
                cell.configLabel.textColor = UIColor.white
                cell.configLabel.text = "Active PTG image: " + PTGActiveFile
                #else
                cell.configLabel.text = "Active PTG image: test.ptg"
                #endif
            }
            cell.accessoryType = .none
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "SeparatorLine")
            //cell?.backgroundColor = seperatorColor
            return cell
        }
        //return cell
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigurationCell", for: indexPath) as! ConfigurationTableViewCell
        
        let buttonCell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell") as! ButtonTableViewCell

        tableView.separatorStyle = .none
        
        //let cellColor = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
        let cellColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        buttonCell.backgroundColor = cellColor
        
        //let rect = tableView.rectForRow(at: indexPath)
        //print("Row=\(indexPath.row),origin = \(rect.origin)")
        buttonCell.LeftButton.addTarget(self, action:#selector(DeviceSetupTableViewController.TapBrowseSDCardButton) , for: .touchUpInside)
                
        #if !targetEnvironment(simulator)
        if(SDCardStatus == "Ready to browse"){
            if(PTGMode == 1){
                buttonCell.LeftButton.isEnabled = true
            }
            else{
                buttonCell.LeftButton.isEnabled = false
            }
        }
        else{
            buttonCell.LeftButton.isEnabled = false
        }
        #endif
        
        buttonCell.RightButton.addTarget(self, action: #selector(DeviceSetupTableViewController.TapProgramButton), for: .touchUpInside)
        #if !targetEnvironment(simulator)
        if(PTGMode == 1){
            if(PTGActiveFile != ""){
                buttonCell.RightButton.isEnabled = true
            }
            else{
                buttonCell.RightButton.isEnabled = false
            }
        }
        else{
            buttonCell.RightButton.isEnabled = false
        }
        #endif
        return buttonCell
        
        /*
        if(indexPath.row == 2){
            buttonCell.LeftButton.addTarget(self, action:#selector(DeviceSetupTableViewController.TapBrowseSDCardButton) , for: .touchUpInside)
            #if !targetEnvironment(simulator)
            if(SDCardStatus == "Ready to browse"){
                if(PTGMode == 1){
                    buttonCell.LeftButton.isEnabled = true
                }
                else{
                    buttonCell.LeftButton.isEnabled = false
                }
            }
            else{
                buttonCell.LeftButton.isEnabled = false
            }
            #endif
            
            buttonCell.RightButton.addTarget(self, action: #selector(DeviceSetupTableViewController.TapProgramButton), for: .touchUpInside)
            #if !targetEnvironment(simulator)
            if(PTGMode == 1){
                if(PTGActiveFile != ""){
                    buttonCell.RightButton.isEnabled = true
                }
                else{
                    buttonCell.RightButton.isEnabled = false
                }
            }
            else{
                buttonCell.RightButton.isEnabled = false
            }
            #endif
            return buttonCell
        }
        else{
            cell.configLabel.text = ""
            cell.accessoryType = .none
            return cell
        }
        */
    }
    /*
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Select device:\(indexPath.row)")
        
        if(indexPath.section == 2){
            if let cell = tableView.cellForRow(at: indexPath){
                if cell.accessoryType == .none{
                    cell.accessoryType = .checkmark
                }
                else{
                    cell.accessoryType = .none
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }*/

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        print("[DeviceSetupTableViewController]segue id = \(segue.identifier ?? "")")
        
        if segue.identifier == "ProgramSegue"{
            let vc = segue.destination as! StatusViewController
            vc.SelectedPeripheral = self.SelectedPeripheral
            vc.SelectedFile = self.PTGActiveFile
        }
        else if segue.identifier == "FileManagerSegue"{
            let vc = segue.destination as! FileManagerViewController
            vc.SelectedPeripheral = self.SelectedPeripheral
        }
        
        //let vc = segue.destination as! OperationTableViewController
        
        //vc.SelectedPeripheral = self.SelectedPeripheral
        //vc.SelectedFile = self.SelectedFile
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
        print("bleProtocolError.")
        self.PICkit_Custom_Alert(title: title, content: message, oneButton: true, image: "X-icon")
    }
    
    func bleCommandResponseData(command: UInt8, data: Any){
        print("[SetupVC] bleCommandResponseData")
        if(command == PICkit_OpCode.BLE_PTG_STATUS.rawValue){
            if data is Data{
                PTGStatus = data as! Data
                let status = data as! Data
                if status.count == 6{
                    appFwVer = String.init(format: "v%d.%d.%d.%d", status[3],status[2],status[1],status[0])
                    print("appFwVer = " + appFwVer)
                    PTGMode = status[5]
                    //SDCardStatus = status[4]
                    if(status[4] == 0){
                        SDCardStatus = "Ready to browse"
                    }
                    else if(status[4] == 2){
                        SDCardStatus = "Not detected"
                    }
                    else if(status[4] == 4){
                        SDCardStatus = "Not accessible"
                    }
                    
                    self.tableView.reloadData()
                    
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
                self.tableView.reloadData()
            }
        }
    }
}
