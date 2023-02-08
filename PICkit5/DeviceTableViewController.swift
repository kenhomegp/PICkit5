//
//  DeviceTableViewController.swift
//  PICkit5
//
//  Created by TestPC on 2022/4/29.
//

import UIKit

class DeviceTableViewController: UITableViewController, bleUARTCallBack {
    
    var bleUart : bleUART?
    var peripherals: NSMutableArray = []
    
    var SelectedPeripheral : String!
    
    var activityIndicator : UIActivityIndicatorView?
    
    var ScanFilterString = "pickit5"
    //var ScanFilterString = "ble_uart"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *){
            let barAppearance = UINavigationBarAppearance()
            /*
             let navigationBarAppearance = UINavigationBarAppearance()      navigationBarAppearance.configureWithOpaqueBackground()
                     navigationBarAppearance.backgroundColor = .systemYellow
                   navigationController?.navigationBar.standardAppearance = navigationBarAppearance
             navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
             */
            
            barAppearance.configureWithOpaqueBackground()
            barAppearance.backgroundColor = UIColor(red: 0.07, green: 0.31, blue: 0.57, alpha: 1.00)//#115091
            //barAppearance.backgroundColor = .gray
            //UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = barAppearance
            navigationController?.navigationBar.standardAppearance = barAppearance
            
            ///*
            let imageView = UIImageView()
            //imageView.image = UIImage(named: "Logo")
            imageView.image = UIImage(named: "PTG_Logo")
            imageView.contentMode = .scaleAspectFit
            navigationItem.titleView = imageView
            //*/
            
            self.tableView.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.title = "Available Devices"
        //self.title = "PICkit5 Devices"
        
        #if targetEnvironment(simulator)
            peripherals.add("PICkit5_001")
            peripherals.add("PICkit5_002")
            peripherals.add("PICkit5_003")
            self.tableView.reloadData()
        #else
            if bleUart == nil{
                bleUart = bleUART.sharedInstace(option: .Normal)
            }
        #endif
        
        //self.tableView.separatorColor = .red

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
        
        print("[DeviceTableViewController]viewWillAppear")
        
        #if !targetEnvironment(simulator)
        print("Peripherals = \(peripherals.count)")
        
            if(self.peripherals.count != 0){
                self.peripherals.removeAllObjects()
                self.tableView.reloadData()
            }
        
            bleUart?.callback = self

            bleUart?.bleDisconnect()
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                //self.bleUart?.bleScan(scanTimeout: 60, scanConfig: .ScanWithoutFilter)
                self.bleUart?.bleScan(ScanFilter: self.ScanFilterString)
                //self.bleUart?.bleScan(scanTimeout: 60, scanConfig: .ScanWithFilter, ScanFilter: self.ScanFilterString)
            }
        #endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        
        if(isMovingFromParent){
            print("Back button detected!")
            print("\(activityIndicator?.isAnimating)")
        }
    }
    
    func BLEScanIndicatorUpdate(ScanState : Bool){
        print("BLE Scan indicator = \(ScanState)")
        
        if(self.activityIndicator == nil && ScanState == true){
            self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            self.activityIndicator!.color = .white
            let barButton = UIBarButtonItem(customView: self.activityIndicator!)
            self.navigationItem.setRightBarButton(barButton, animated: true)
            activityIndicator!.startAnimating()
        }
        else{
            if(self.navigationItem.rightBarButtonItem?.title == "SCAN"){
                let barButton = UIBarButtonItem(customView: self.activityIndicator!)
                self.navigationItem.setRightBarButton(barButton, animated: true)
                activityIndicator!.startAnimating()
            }
            
            if(ScanState){
                if self.activityIndicator?.isAnimating == false{
                    activityIndicator!.startAnimating()
                }
            }
            else{
                if self.activityIndicator?.isAnimating == true{
                    activityIndicator?.stopAnimating()
                    
                    let ScanButton = UIBarButtonItem(title: "SCAN", style: UIBarButtonItem.Style.plain, target: self, action: #selector(DeviceTableViewController.ScanbuttonTapped(_:)))
                    
                    self.navigationItem.rightBarButtonItem = ScanButton
                }
            }
        }
    }
    
    @objc func ScanbuttonTapped(_ sender:UIBarButtonItem!) {
        print(#function)
        
    #if !targetEnvironment(simulator)
        if bleUart == nil{
            bleUart = bleUART.sharedInstace(option: .Normal)
            bleUart?.callback = self
        }
    #endif
        
        if(self.activityIndicator != nil){
            let barButton = UIBarButtonItem(customView: self.activityIndicator!)
            self.navigationItem.setRightBarButton(barButton, animated: true)
            activityIndicator!.startAnimating()
        }
        
        //self.peripherals.removeAllObjects()
        //self.tableView.reloadData()
    
    #if !targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            //self.bleUart?.bleScan(scanTimeout: 60, scanConfig: .ScanWithoutFilter)
            self.bleUart?.bleScan(ScanFilter: self.ScanFilterString)
        }
    #endif
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        //return 0
        return peripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanDeviceCell", for: indexPath) as! ScanDeviceTableViewCell
        
        cell.backgroundColor = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
        //cell.deviceImage.image = UIImage(named: "MPLAB_PTG")
        cell.deviceImage.image = UIImage(named: "Device-icon")
        
        //let screenSize = UIScreen.main.bounds
        let separatorHeight = CGFloat(5.0)
        let additionalSeparator = UIView.init(frame: CGRect(x: 0, y: cell.contentView.frame.size.height-separatorHeight, width: cell.contentView.frame.width, height: separatorHeight))
        additionalSeparator.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        cell.addSubview(additionalSeparator)
        
        #if targetEnvironment(simulator)
            cell.deviceName.text = "Serial number: xxxxxxxx"
        #else
            let dev = peripherals.object(at: indexPath.row) as! Microchip_Peripheral
            print("PICkit5 device name = \(dev.deviceName ?? "")")
            if let name = dev.deviceName{
                let strArray = name.split(separator: "_")
                if(strArray.count == 2){
                    //cell.textLabel?.text = "SN: " + strArray[1]
                    cell.deviceName.text = "SN: " + strArray[1]
                }
                else{
                    cell.textLabel?.text = "SN: 12345678"
                    cell.detailTextLabel?.text = dev.peripheral?.name
                }
            }
        #endif
        
        /*
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        
        cell.imageView?.translatesAutoresizingMaskIntoConstraints = false

        let marginguide = cell.contentView.layoutMarginsGuide

        cell.imageView?.topAnchor.constraint(equalTo: marginguide.topAnchor).isActive = true
        cell.imageView?.leadingAnchor.constraint(equalTo: marginguide.leadingAnchor).isActive = true
        cell.imageView?.heightAnchor.constraint(equalToConstant: 50).isActive = true
        cell.imageView?.widthAnchor.constraint(equalToConstant: 65).isActive = true

        cell.imageView?.contentMode = .scaleAspectFill
        
        let iconImage = UIImage(named: "MPLAB_PTG")
        cell.imageView?.image = iconImage
        
        cell.accessoryType = .none
        
        cell.backgroundColor = UIColor(red: 0.75, green: 0.38, blue: 0.38, alpha: 1.00)
        
        #if targetEnvironment(simulator)
            cell.textLabel?.text = peripherals.object(at: indexPath.row) as? String
            cell.detailTextLabel?.text = "Serial number: xxxxxxxx"
        #else
            let dev = peripherals.object(at: indexPath.row) as! Microchip_Peripheral
            print("PICkit5 device name = \(dev.deviceName ?? "")")
            if let name = dev.deviceName{
                let strArray = name.split(separator: "_")
                if(strArray.count == 2){
                    cell.textLabel?.text = "SN: " + strArray[1]
                    //cell.detailTextLabel?.text = String(strArray[0])
                    cell.detailTextLabel?.text = ""
                }
                else{
                    cell.textLabel?.text = "SN: 12345678"
                    cell.detailTextLabel?.text = dev.peripheral?.name
                }
            }
            //cell.textLabel?.text = dev.peripheral?.name
            //cell.detailTextLabel?.text = "PICkit"
        #endif
        */
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("[didSelectRowAt]Select device:\(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath) as! ScanDeviceTableViewCell
        print("[didSelectRowAt]Select device = \(cell.deviceName.text)")
        self.SelectedPeripheral = cell.deviceName.text
        /*
        if let cell = tableView.cellForRow(at: indexPath){
            self.SelectedPeripheral = cell.textLabel?.text
            //print("[didSelectRowAt]Select device:\(indexPath.row). \(self.SelectedPeripheral)")
            if cell.accessoryType == .none{
                cell.accessoryType = .checkmark
            }
        }*/
        #if targetEnvironment(simulator)
            //self.performSegue(withIdentifier: "FileManagerTestSegue", sender: self)
            self.performSegue(withIdentifier: "SetupSegue", sender: self)
        #else
            let peripheral = peripherals.object(at: indexPath.row) as! Microchip_Peripheral
            let device_id = peripheral.peripheral?.identifier.uuidString
            bleUart?.bleConnect(device_id: device_id!)
        #endif
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
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
        
        print("[DeviceTableViewController]segue id = \(segue.identifier ?? "")")
        print(self.SelectedPeripheral)
        
        let vc = segue.destination as! DeviceSetupTableViewController
        vc.SelectedPeripheral = self.SelectedPeripheral
    }
    
    @IBAction func StatusDisconnect(_ segue: UIStoryboardSegue) {
        print("Unwind segue: StatusDisconnect")
    }
    
    @IBAction func OperationDisconnect(_ segue: UIStoryboardSegue) {
        print("Unwind segue: StatusDisconnect")
    }
    
    @IBAction func SetupDisconnect(_ segue: UIStoryboardSegue) {
        print("Unwind segue: SetupDisconnect")
    }
    
    @IBAction func FileManagerDisconnect(_ segue: UIStoryboardSegue) {
        print("Unwind segue: FileManagerDisconnect")
    }

    // MARK: - bleUARTCallBack delegate
    func bleDidConnect(peripheralName: String) {
        print("callback:bleDidConnect.\(peripheralName)")
        //self.performSegue(withIdentifier: "FileManagerSegue", sender: self)
        self.performSegue(withIdentifier: "SetupSegue", sender: self)
    }
    
    func bleConnecting(bleScan: Bool, discoveredPeripherals: NSMutableArray) {
        print("callback:connecting. isScanning=\(bleScan)")
        
        if bleScan{
            if discoveredPeripherals.count != 0{
                self.peripherals.removeAllObjects()
            
                self.peripherals = NSMutableArray(array: discoveredPeripherals)
                
                self.tableView.reloadData()
            }
        }
        else{
            //let pickitDevices = NSMutableArray(array: discoveredPeripherals)
            print("Scan stop.")
            
            if(self.peripherals.count != 0){
                self.peripherals.removeAllObjects()
                self.tableView.reloadData()
            }
            bleUart?.DestroyInstance()
            bleUart = nil
        }
        
        BLEScanIndicatorUpdate(ScanState: bleScan)
    }
}
