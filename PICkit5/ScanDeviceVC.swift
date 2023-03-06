//
//  ScanDeviceVC.swift
//  MPLAB PTG
//
//  Created by Minglung on 2022/11/15.
//

import UIKit

class ScanDeviceVC: UIViewController, UITableViewDelegate, UITableViewDataSource, bleUARTCallBack{
    @IBOutlet weak var deviceList: UITableView!
    
    var bleUart : bleUART?
    var peripherals: NSMutableArray = []
    
    var SelectedPeripheral : String!
    
    var activityIndicator : UIActivityIndicatorView?
    
    var ScanFilterString = "pickit5"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        print("[ScanDeviceVC] viewDidLoad")
        
        self.title = "Available Devices"
        
        deviceList.delegate = self
        deviceList.dataSource = self
        
        deviceList.separatorStyle = .none
        
        if #available(iOS 13.0, *){
            let barAppearance = UINavigationBarAppearance()
            
            barAppearance.configureWithOpaqueBackground()
            barAppearance.backgroundColor = UIColor(red: 0.07, green: 0.31, blue: 0.57, alpha: 1.00)//#115091
            
            navigationController?.navigationBar.scrollEdgeAppearance = barAppearance
            navigationController?.navigationBar.standardAppearance = barAppearance
            
            //navigationController?.navigationBar.backItem?.backBarButtonItem?.tintColor = .white
            
            /*
            let imageView = UIImageView()
            imageView.image = UIImage(named: "PTG_Logo")
            imageView.contentMode = .scaleAspectFit
            navigationItem.titleView = imageView
            */
            
            self.deviceList.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        }
        
        
        self.title = "Available devices"
        
        #if targetEnvironment(simulator)
            peripherals.add("SN: 000000119")
            self.deviceList.reloadData()
        #else
            if bleUart == nil{
                bleUart = bleUART.sharedInstace(option: .Normal)
            }
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
        
        #if !targetEnvironment(simulator)
        print("Peripherals = \(peripherals.count)")

            if(self.peripherals.count != 0){
                self.peripherals.removeAllObjects()
                self.deviceList.reloadData()
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
            self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
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
                    let ScanButton = UIBarButtonItem(image: UIImage(named: "rszScan"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(ScanDeviceVC.ScanbuttonTapped(_:)))
                    ScanButton.tintColor = .white
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

        #if !targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.bleUart?.bleScan(ScanFilter: self.ScanFilterString)
        }
        #endif
    }

    @IBAction func StatusDisconnect(_ segue: UIStoryboardSegue) {
        print("Unwind segue: StatusDisconnect")
    }
        
    @IBAction func SetupDisconnect(_ segue: UIStoryboardSegue) {
        print("Unwind segue: SetupDisconnect")
    }
    
    @IBAction func FileManagerDisconnect(_ segue: UIStoryboardSegue) {
        print("Unwind segue: FileManagerDisconnect")
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        print("[ScanViewController]segue id = \(segue.identifier ?? "")")
        print(self.SelectedPeripheral)
        
        let vc = segue.destination as! DeviceSetupVC
        vc.SelectedPeripheral = self.SelectedPeripheral
    }

    // MARK: - TableView delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanDeviceCell", for: indexPath) as! ScanDeviceTableViewCell
        
        //cell.backgroundColor = UIColor(red: 0.75, green: 0.38, blue: 0.38, alpha: 1.00)
        cell.backgroundColor = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
        cell.deviceImage.image = UIImage(named: "Device-icon")
        
        let separatorHeight = CGFloat(5.0)
        let additionalSeparator = UIView.init(frame: CGRect(x: 0, y: cell.contentView.frame.size.height-separatorHeight, width: cell.contentView.frame.width, height: separatorHeight))
        additionalSeparator.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        cell.addSubview(additionalSeparator)
        
        #if targetEnvironment(simulator)
            //cell.deviceName.text = "Serial number: 0000000" + String(indexPath.row)
            cell.deviceName.text = "SN: 000000119"
            cell.detailTextLabel?.text = "RSSI: -69 dBm"
        #else
            let dev = peripherals.object(at: indexPath.row) as! Microchip_Peripheral
            print("PICkit5 device name = \(dev.deviceName ?? "")")
            //print("dev RSSI = \(dev.rssi)")
            if let name = dev.deviceName{
                let strArray = name.split(separator: "_")
                if(strArray.count == 2){
                    cell.deviceName.text = "SN: " + strArray[1]
                }
                else{
                    cell.textLabel?.text = "SN: 12345678"
                    cell.detailTextLabel?.text = dev.peripheral?.name
                }
            }
        
            if(dev.rssi != nil){
                cell.deviceRSSI.text = "RSSI: " + String(dev.rssi!.intValue) + " dBm"
            }
            else{
                cell.deviceRSSI.text = ""
            }
        #endif
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("[didSelectRowAt]Select device:\(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath) as! ScanDeviceTableViewCell
        print("[didSelectRowAt]Select device = \(cell.deviceName.text)")
        self.SelectedPeripheral = cell.deviceName.text

        #if targetEnvironment(simulator)
            self.performSegue(withIdentifier: "SetupSegue", sender: self)
        #else
            let peripheral = peripherals.object(at: indexPath.row) as! Microchip_Peripheral
            let device_id = peripheral.peripheral?.identifier.uuidString
            bleUart?.bleConnect(device_id: device_id!)
        #endif
    }
    
    // MARK: - bleUARTCallBack delegate
    func bleDidConnect(peripheralName: String) {
        print("callback:bleDidConnect.\(peripheralName)")
        self.performSegue(withIdentifier: "SetupSegue", sender: self)
    }
    
    func bleConnecting(bleScan: Bool, discoveredPeripherals: NSMutableArray) {
        print("callback:connecting. isScanning=\(bleScan)")
        
        if bleScan{
            if discoveredPeripherals.count != 0{
                self.peripherals.removeAllObjects()
            
                self.peripherals = NSMutableArray(array: discoveredPeripherals)
                
                self.deviceList.reloadData()
            }
        }
        else{
            //let pickitDevices = NSMutableArray(array: discoveredPeripherals)
            print("Scan stop.")
            
            if(self.peripherals.count != 0){
                self.peripherals.removeAllObjects()
                self.deviceList.reloadData()
            }
            bleUart?.DestroyInstance()
            bleUart = nil
        }
        
        BLEScanIndicatorUpdate(ScanState: bleScan)
    }
}
