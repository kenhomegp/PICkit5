//
//  BLEAdapter.swift
//  TestOTA
//
//  Created by WSG Software on 30/10/2017.
//  Copyright © 2017 WSG Software. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation

public struct Data_Beacon_Information {
    var category: UInt8 = 0xff
    var product_type: UInt8 = 0
    var product_data: [UInt8] = []
    
    static func Parsing_adv_data(advdata: [String : Any]?) -> Data_Beacon_Information?{
        
        if let serviceData = advdata!["kCBAdvDataServiceData"] as? [NSObject:AnyObject] {
            print("service data = \(serviceData)")
            //if let data_beacon = serviceData[CBUUID(string:"FEDA")] as? NSData {
            if let data_beacon = serviceData[CBUUID(string:"FEDA")] as? Data {
                //print("data beacon = \(data_beacon as NSData )")
                
                let bytes = [UInt8](data_beacon)
                
                var beacon = Data_Beacon_Information()
                if(bytes[0] == 0xff && data_beacon.count >= 2){
                    beacon.category = bytes[0]
                    beacon.product_type = bytes[1]
                
                    if(data_beacon.count > 2){
                        for i in 0..<(data_beacon.count-2){
                            beacon.product_data.append(bytes[2+i])
                        }
                    }
                    
                    print("Done,beacon data = \(data_beacon as NSData )")
                    
                    return beacon
                }
                return nil
            }
            return nil
        }
        return nil
    }
}

struct BLE_UART_Command {
    var vendor_op: UInt8 = 0x80
    var group_command: BLE_UART_Group_Command = .default_value
    var sub_command: UInt8 = 0
    var command_parameters: [UInt8] = []
    
    init() {}
    
    static func write_data(format: BLE_UART_Command) -> Data{
        let ble_uart_comd = format
        var dat = Data()
        dat.append(ble_uart_comd.vendor_op)
        dat.append(ble_uart_comd.group_command.rawValue)
        dat.append(ble_uart_comd.sub_command)
        if ble_uart_comd.command_parameters.count != 0{
            dat.append(contentsOf: ble_uart_comd.command_parameters)
        }
        return dat
    }
    
    static func Received_Event(receive: Data) -> BLE_UART_Command?{
        if(receive.count >= 3){
            var event = BLE_UART_Command()
            let bytes = [UInt8](receive)
            
            if(bytes[0] == 0x80){
                print("ble uart parse event = \(receive as NSData)")
                
                event.vendor_op = bytes[0]
                event.group_command = BLE_UART_Group_Command(rawValue: bytes[1])!
                event.sub_command = bytes[2]
            
                if(receive.count > 3){
                    for i in 0..<(receive.count-3){
                        event.command_parameters.append(bytes[i+3])
                    }
                }
                return event
            }
            return nil
        }
        return nil
    }
}

public enum CentralOption {
    case Normal
    case StatePreservation
}

enum BLE_UART_Group_Command: UInt8 {
    case default_value = 0
    case checksum_mode = 0x01
    case loopback_mode = 0x02
    case fixedPattern_mode = 0x03
    case uart_mode = 0x04
    case control = 0x05
    case ble_parameter_update = 0x06
    case changeProfile = 0x07
}

enum BLE_UART_Sub_Command: UInt8 {
    case transmission_end = 0x00
    case transmission_start = 0x01
    case transmission_data_length = 0x02
    case transmission_path = 0x04
}

///BLE UART Command Opcode
public enum BLE_UART_OP_Mode: UInt8 {
    ///APP sends data to the device. After the transmission is completed, checksum value will be sent to the device for data comparison
    case checksum = 1
    ///APP sends data to the device. The device sends the received data back to the APP
    case loopback = 2
    ///Device sends fixed data pattern to the APP
    case fixed_pattern = 3
    ///The device sends the data received from the APP to the UART port, and vice versa
    case go_through_uart = 4
}

enum L2Cap_Operation_Mode {
    case Discovering
    case TextFile
    case RawData
    case Periodic
    case L2CAP_APP_Test
}

enum Peripheral_Capability: UInt8 {
    case GATT = 0x01
    case L2CAP = 0x02
}

public struct Receive_timeout {
    public static let GATT_timeout = 3000
    public static let L2CAP_timeout = 2000
}

public enum ScanConfiguration {
    case ScanContinue
    case Scan
    case ScanTest
    case ScanWithoutFilter
    case ScanWithFilter
}

protocol BLEAdapterDelegate {
    func OnConnected(_ connectionStatus:Bool, message:String)
    func BLEDataIn(_ dataIn:Data)
    func UpdateMTU(_ mtu:Int)
    func ISSC_Peripheral_Device(_ device_found:Bool)
}

public class Microchip_Peripheral {
    public var peripheral: CBPeripheral?
    public var advertisementData: [String : Any]?
    public var rssi: NSNumber?
    public var capability: UInt8?
    public var data_beacon: Data_Beacon_Information?
    public var deviceName: String?
    var rssi_update_time: Int = 0
    
    init(device: CBPeripheral, adv: [String : Any], rssi: NSNumber) {
        self.peripheral = device
        self.advertisementData = adv
        self.rssi = rssi
    }
    
    init(device: CBPeripheral, devName: String){
        self.peripheral = device
        self.deviceName = devName
    }
    
    init(device: CBPeripheral, devName: String, deviceInfo: Data_Beacon_Information, adv: [String : Any], rssi: NSNumber) {
        self.peripheral = device
        self.deviceName = devName
        self.data_beacon = deviceInfo
        self.advertisementData = adv
        self.rssi = rssi
    }
}

class BLEAdapter: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, StreamDelegate, ReliableBurstTransmitDelegate{
    
    var centralManager: CBCentralManager?
    
    var activePeripheral: CBPeripheral?
    var bleAdapterDelegate: BLEAdapterDelegate?
    var WriteCharacteristic: CBCharacteristic?
    var TransparentChar: CBCharacteristic?
    var TransparentControl: CBCharacteristic?
    var canSendData: Bool = false

    var RestoredPeripheral: CBPeripheral?
    
    var LastConnectedPeripheral_udid: String! = ""
    
    var Peripheral_List = NSMutableArray()
    
    var mtu : Int = 0
    
    var ISSC_Peripheral : Bool = false
    
    var TransmitCharacteristic = false
    
    var ReceiveCharacteristic = false
    
    var L2Cap_Role_Central: Bool = true
    
    var BLE_didDiscoverUpdateState: ((Bool) -> Void)?
    
    var BLE_File_Disconnected: (() -> Void)?
    
    var BLE_File_Checksum: (() -> Void)?    //APP send checksum
    var BLE_File_Tx_Start: (() -> Void)?
    var BLE_File_Size: (() -> Void)?
    var BLE_File_Checksum_enable: (() -> Void)? //Checksum_mode
    var BLE_File_Loopback_enable: (() -> Void)? //Loopback_mode
    var BLE_File_UART_enable: (() -> Void)?     //Go_through_UART
    var BLE_File_Set_Data_Path: (() -> Void)?
    var GATT_BLE_UART_File_UpdateState: ((BLE_UART_Group_Command, UInt8) -> Void)?
    var BLE_FixedPattern_Last_Number: ((UInt8, UInt8) -> Void)?
    var BLE_File_WriteCallback: ((Int, Bool, Int) -> Void)?
    var BLE_File_receiveCallback: ((Data) -> Void)?
    var L2Cap_receiveCallback: ((Data,Double,Double) -> Void)?
    var L2Cap_sentDataCallback: ((Int, Double) -> Void)?
    
    //PICkit5
    var BLE_WriteResponseCallback: ((Bool) -> Void)?
    var BLE_DataReceiveCallback: ((Data) -> Void)?
    
    //Connection
    var L2Cap_Connection_Complete: (() -> Void)?
    
    var Connection_Complete: (() -> Void)?
    
    var transmit: ReliableBurstTransmit?
    
    var Write_type: Int?
    
    var bleScanTimer : Timer?
    
    var Data_Transmission_Timer: Timer?
    
    var Transmission_timer_counter: Int = 0
    
    var BLE_UART_Receive_Checksum: UInt8 = 0
    
    var BLE_UART_write_comd = BLE_UART_Command()
    
    var L2Cap_PSM_Value: Data?
    
    var l2capTransparentControl: CBCharacteristic?

    var active_data_path: Peripheral_Capability = .GATT {
        didSet{
            print("active_data_path is changed!")
            self.GATT_BLE_UART_File_UpdateState?(.changeProfile , active_data_path.rawValue)
            
        }
    }
    
    var DIS_Manufacture: String! = "N/A"
    var DIS_Model: String! = "N/A"
    var DIS_SerialNumber: String! = "N/A"
    var DIS_HardwareVersion: String! = "N/A"
    var DIS_FirmwareVersion: String! = "N/A"
    var DIS_SoftwareVersion: String! = "N/A"
    var DIS_SystemID: String! = ""
    
    var ReliableWriteLen: Int = 0
    
    var central_init_option: CentralOption = .Normal
    
    var scanOption : ScanConfiguration = .Scan
    
    var ScanFilterString : String = ""
    
    // MARK: - Coding here
    
    init(option: CentralOption) {
        super.init()
        
        //print("GetUserDefault: L2CAP")
        //let role = UserDefaults.standard.bool(forKey: "L2CAP_Role")
        //print("L2Cap_Role_Central = \(role)")
        
        self.central_init_option = option
        print("Central init option = \(self.central_init_option)")
        
        //#if STATE_PRESERVE
        if option == .StatePreservation {
            if let peripheral_udid_str = UserDefaults.standard.object(forKey: "STATE_PRESERVE_PERIPHERAL_UDID") as? String{
                LastConnectedPeripheral_udid = peripheral_udid_str
                print("[GetUserDefault]Last connected peripheral udid = \(LastConnectedPeripheral_udid ?? "")")
            }
        }
        //#endif
        
        if(L2Cap_Role_Central){
            //#if STATE_PRESERVE
            if option == .StatePreservation {
                print("State preservation and restoration Test")
                let option = [CBCentralManagerOptionRestoreIdentifierKey: "my-central-identifier"]
                self.centralManager = CBCentralManager(delegate: self, queue: nil, options: option)
            //#else
            }
            else{
                self.centralManager = CBCentralManager(delegate: self, queue: nil)
            //#endif
            }
            
            activePeripheral = nil
            RestoredPeripheral = nil
            //LastConnectedPeripheral_udid = ""
        }
    }
    
    /*
    override init() {
        super.init()
        
        print("GetUserDefault: L2CAP")
        let role = UserDefaults.standard.bool(forKey: "L2CAP_Role")
        print("L2Cap_Role_Central = \(role)")
        
        #if STATE_PRESERVE
            if let peripheral_udid_str = UserDefaults.standard.object(forKey: "STATE_PRESERVE_PERIPHERAL_UDID") as? String{
                LastConnectedPeripheral_udid = peripheral_udid_str
                print("[GetUserDefault]Last connected peripheral udid = \(LastConnectedPeripheral_udid ?? "")")
            }
        #endif
        
        if(L2Cap_Role_Central){
            #if STATE_PRESERVE
                print("State preservation and restoration Test")
                let option = [CBCentralManagerOptionRestoreIdentifierKey: "my-central-identifier"]
                self.centralManager = CBCentralManager(delegate: self, queue: nil, options: option)
            #else
                self.centralManager = CBCentralManager(delegate: self, queue: nil)
            #endif
            
            activePeripheral = nil
            RestoredPeripheral = nil
            //LastConnectedPeripheral_udid = ""
        }
        else{
            self.BT_peripheral = L2CapPeripheral(connectionHandler: { (connection) in
                self.connection = connection
                
                self.L2Cap_Connection_Complete?()
                
                print("[Peripheral]L2CAP Connection is created!")
                
                self.connection?.receiveCallback = { (connection, data, time1, time2) in
                    print("[Peripheral]Bytes Receive = \(data.count)")
                    
                    self.L2Cap_receiveCallback?(data,time1,time2)
                }
                
                self.connection?.sentDataCallback = { (connection, write_len, time_interval) in
                    print("[Peripheral]Bytes written = \(write_len)")
                    
                    self.L2Cap_sentDataCallback?(write_len, time_interval)
                }
            })
        }
    }*/
    
    deinit {
        print("BLEAdapter deinit")
    }
    
    private static var mInstance:BLEAdapter?
    
    class func sharedInstace(option : CentralOption) -> BLEAdapter {
        if(mInstance == nil) {
            //mInstance = BLEAdapter()
            print("Create instance. option = \(option)")
            //mInstance = BLEAdapter(option: .StatePreservation)
            mInstance = BLEAdapter(option: option)
            print("New BLEAdapter object")
        }
        return mInstance!
    }
    
    func DestroyInstance(){
        print(#function)
        
        transmit = nil
        
        if self.activePeripheral != nil{
            disconnectPeripheral()
        }
        
        if(self.centralManager!.isScanning){
            self.centralManager?.stopScan()
        }
        
        self.centralManager = nil
        
        if self.bleScanTimer != nil{
            if bleScanTimer!.isValid{
                bleScanTimer?.invalidate()
                bleScanTimer = nil
            }
        }

        BLEAdapter.mInstance = nil
    }
    
    func RetrieveConnectedPeripheral() -> [CBPeripheral] {
        print("RetrieveConnectedPeripheral")
        
        //let aryUUID = ["180A" ,"49535343-FE7D-4AE5-8FA9-9FAFD205E455", "49535343-2120-45FC-BDDB-E8A01AEDEC50"]
        let aryUUID = ["180A", "49535343-FE7D-4AE5-8FA9-9FAFD205E455", "49535343-2120-45FC-BDDB-E8A01AEDEC50"]
        var aryCBUUIDS = [CBUUID]()

        for uuid in aryUUID{
            let uuid = CBUUID(string: uuid)
            aryCBUUIDS.append(uuid)
        }
        //print("Services = \(aryCBUUIDS)")
        
        return centralManager?.retrieveConnectedPeripherals(withServices: aryCBUUIDS) ?? []
    }
    
    func findAllBLEPeripherals(_ timeOut:Double, scanOption: ScanConfiguration){
        if #available(iOS 10.0, *) {
            if(self.centralManager?.state != CBManagerState.poweredOn){
                print("BLE is not avaliable!")
                print("BT state = \(centralManager?.state.rawValue ?? -1)")
                //return -1
            }
        } else {
            // Fallback on earlier versions
        }
        
        if #available(iOS 9.0, *) {
            if(self.centralManager!.isScanning)
            {
                print("Stop Scan")
                self.centralManager?.stopScan()
                sleep(1)
            }
        } else {
            // Fallback on earlier versions
            print("Stop Scan")
            self.centralManager?.stopScan()
            sleep(1)
        }
        
        self.Peripheral_List.removeAllObjects()

        if self.bleScanTimer != nil{
            if bleScanTimer!.isValid{
                bleScanTimer?.invalidate()
                bleScanTimer = nil
            }
        }
        
        bleScanTimer = Timer.scheduledTimer(timeInterval: timeOut, target: self, selector: #selector(BLEAdapter.scanTimer), userInfo: nil, repeats: false)
        
        print("Scan time = \(timeOut)")
        print("Scan ALL device. ")
        
        self.scanOption = scanOption
        
        if scanOption == .ScanContinue{
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
        else{
            centralManager?.scanForPeripherals(withServices: nil, options: nil)   //Scan All Device
        }
        //else if(scanOption == .Scan || scanOption == .ScanWithoutFilter) {
        //    centralManager?.scanForPeripherals(withServices: nil, options: nil)   //Scan All Device
        //}
        //else{
            //CBCentralManagerRestoredStateScanOptionsKey
            
            //print("State preservation and restoration Test")
            //State preservation and restoration
            //let option = [CBCentralManagerOptionRestoreIdentifierKey: "my-central-identifier"]
            //centralManager?.scanForPeripherals(withServices: nil, options: option)
            
            //centralManager?.scanForPeripherals(withServices: [CBUUID(string: UUIDSTR_MCHP_PROPRIETARY_SERVICE)], options: option)
        //}
        
        self.BLE_didDiscoverUpdateState?(centralManager!.isScanning)
        
        //return 0
    }

    func findBLEPeripherals(_ timeOut:Double)->Int {
        if #available(iOS 10.0, *) {
            if(self.centralManager?.state != CBManagerState.poweredOn){
                print("BLE is not avaliable!")
                print("BT state = \(centralManager?.state.rawValue ?? -1)")
                return -1
            }
        } else {
            // Fallback on earlier versions
            print("Stop Scan")
            self.centralManager?.stopScan()
            sleep(1)
        }
        
        self.Peripheral_List.removeAllObjects()
        
        Timer.scheduledTimer(timeInterval: timeOut, target: self, selector: #selector(BLEAdapter.scanTimer), userInfo: nil, repeats: false)
        
        print("Scan ISSC device")
        
        //centralManager?.scanForPeripherals(withServices: [CBUUID(string: UUIDSTR_MCHP_PROPRIETARY_SERVICE)], options: nil)
        centralManager?.scanForPeripherals(withServices: [BLE_Constants.MCHP_PROPRIETARY_SERVICE], options: nil)
        
        //centralManager?.scanForPeripherals(withServices: [CBUUID(string: UUIDSTR_ISSC_AIR_PATCH_SERVICE)], options: nil)
        return 0
    }
    
    /*
    func find_BLE_UART_Peripherals(_ timeOut:Double)->Int {
        
        print("find_BLE_UART_Peripherals")
        
        self.Peripheral_List.removeAllObjects()
        
        centralManager?.scanForPeripherals(withServices: [CBUUID(string: UUIDSTR_kServiceUUID)], options: nil)
        
        Timer.scheduledTimer(timeInterval: timeOut, target: self, selector: #selector(BLEAdapter.scanTimer), userInfo: nil, repeats: false)
        
        return 0
    }*/
    
    func GetISSCDevice() {
        print("GetISSCDevice")
        self.bleAdapterDelegate?.ISSC_Peripheral_Device(ISSC_Peripheral)
    }
    
    func GetMTUSize() {
        //print("GetMTUSize")
        if #available(iOS 9.0, *) {
            mtu = (activePeripheral?.maximumWriteValueLength(for:CBCharacteristicWriteType.withoutResponse))!
        } else {
            // Fallback on earlier versions
        }
        print("GetMTUSize = \(mtu)")
        
        self.bleAdapterDelegate?.UpdateMTU(mtu)
    }
    
    func disconnectPeripheral() {
        if(activePeripheral != nil) {
            print("disconnectPeripheral")
            
            //L2CAP_CloseStream()
            
            centralManager!.cancelPeripheralConnection(activePeripheral!)
            
            activePeripheral = nil
            
            LastConnectedPeripheral_udid = ""
            
            //#if STATE_PRESERVE
            if central_init_option == .StatePreservation{
                UserDefaults.standard.removeObject(forKey: "STATE_PRESERVE_PERIPHERAL_UDID")
            }
            //#endif
        }
    }

    func connectPeripheral(_ Selected:Int) {
    }
    
    @objc func scanTimer() {
        centralManager?.stopScan()
        print("Stopped Scanning")
        
        if bleScanTimer!.isValid{
            bleScanTimer?.invalidate()
            bleScanTimer = nil
        }
        
        self.BLE_didDiscoverUpdateState?(centralManager!.isScanning)
        
        //print("Known Peripherals = \(self.peripherals.count)")
        //print("Known Microchip peripherals = \(self.Peripheral_List.count)")
        
        //printKnownPeripherals()
    }
    
    func printKnownPeripherals() {
        if(self.Peripheral_List.count != 0) {
            print("Prints Microchip Peripherals ")
            
            for i in 0 ..< self.Peripheral_List.count {
                let obj = self.Peripheral_List.object(at: i) as! Microchip_Peripheral
                printPeripheralInfo(obj.peripheral!)
                print("-------------------------------------\r\n");
                print("Microchip peripheral:")
                print("ID = \(obj.peripheral?.identifier.uuidString ?? "")")
                print("ADV = \(String(describing: obj.advertisementData))")
                print("RSSI = \(String(describing: obj.rssi))")
                //print("Services = \(obj.peripheral?.services)")
                //print("ADV = \(obj.advertisementData)")
                //print("RSSI = \(obj.rssi)")
                
                /*
                if let adv = obj.advertisementData{
                    if let test1 = adv["kCBAdvDataServiceData"] as? [NSObject:AnyObject] {
                        if let test2 = test1[CBUUID(string:"FEDA")] as? NSData {
                            print("data beacon = \(test2 )")
                        }
                    }
                }*/
            }
        }
    }
    
    func printPeripheralInfo(_ peripheral: CBPeripheral) {
        print("------------------------------------\r\n");
        print("Peripheral Info :\r\n");
        //print("RSSI : \(peripheral.rssi?.int32Value)");
        if(peripheral.name != nil) {
            print("Peripheral Name : \(peripheral.name!)");
        }
        else {
            print("Name : nil")
        }
        print("isConnected : \(peripheral.state.rawValue)");
        //print("-------------------------------------\r\n");
    }
    
    func PeripheralName() -> String {
        
        if(L2Cap_Role_Central == true){
            if(activePeripheral != nil){
                return (activePeripheral?.name)!
            }
            else {
                return "Disconnected"
            }
        }
        else{
            return "Peripheral"
        }
    }
    
    func DIS_ConvertData(dat: Data) -> String {
        let bytes = [UInt8](dat)
        var str = ""
        for i in 0..<bytes.count{
            if(bytes[i] < 0x10){
                str.append(String(format: "0%x", bytes[i]))
            }
            else{
                str.append(String(format: "%x", bytes[i]))
            }
            //print("str = \(str)")
        }
        
        return str
    }
    
    func Connect_Peripheral(peripheral_uuid: String) {
        print(#function)
        
        if self.centralManager!.isScanning{
            print("Stop Scan")
            self.centralManager?.stopScan()
            
            if self.bleScanTimer != nil{
                if bleScanTimer!.isValid{
                    bleScanTimer?.invalidate()
                    bleScanTimer = nil
                }
            }
        }
        
        for i in 0 ..< self.Peripheral_List.count {
            let obj = self.Peripheral_List.object(at: i) as! Microchip_Peripheral
            let p = obj.peripheral
            if(p?.identifier.uuidString == peripheral_uuid) {
                activePeripheral = obj.peripheral
                break
            }
        }
        
        centralManager?.connect(activePeripheral!, options: nil)
        activePeripheral?.delegate = self
        
    }
    
    // MARK: - CoreBluetooth delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 10.0, *) {
            switch (central.state) {
            case CBManagerState.poweredOff:
                print("Status of CoreBluetooth Central Manager = Power Off")
                break
            case CBManagerState.unauthorized:
                print("Status of CoreBluetooth Central Manager = Does Not Support BLE")
                break
            case CBManagerState.unknown:
                print("Status of CoreBluetooth Central Manager = Unknown Wait for Another Event")
                break
            case CBManagerState.poweredOn:
                print("Status of CoreBluetooth Central Manager = Powered On")
                if central_init_option == .StatePreservation{
                    if self.RestoredPeripheral != nil{
                        centralManager?.connect(self.RestoredPeripheral!, options: nil)
                        self.activePeripheral = self.RestoredPeripheral
                    }
                }
                break
            case CBManagerState.resetting:
                print("Status of CoreBluetooth Central Manager = Resetting Mode")
                break
            case CBManagerState.unsupported:
                print("Status of CoreBluetooth Central Manager = Un Supported")
                break
            @unknown default:
                print("CoreBluetooth Central:Unknown state")
            }
        } else {
            // Fallback on earlier versions
            switch (central.state.rawValue) {
                case 3: //CBCentralManagerState.unauthorized
                    print("This app is not authorized to use Bluetooth low energy")
                    break
                case 4:
                    print("Bluetooth is currently powered off")
                    break
                case 5:
                    print("Bluetooth is currently powered on and available to use")
                    break
                default:break
            }
        }
    }
    
    //#if STATE_PRESERVE
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("centralManager, willRestoreState")
        
        if self.central_init_option != .StatePreservation{
            return
        }
        
        //let sound: SystemSoundID = 1321
        //AudioServicesPlaySystemSound(sound)
        
        //if let peripherals = dict[CBCentralManagerOptionRestoreIdentifierKey] as? [CBPeripheral]{
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral]{
            print("\(peripherals)")
            
            let sound: SystemSoundID = 1321
            //let sound: SystemSoundID = 1304
            AudioServicesPlaySystemSound(sound)
            
            print("Last connected peripheral udid = \(LastConnectedPeripheral_udid)")
            
            if LastConnectedPeripheral_udid != ""{
                for pp in peripherals{
                    //if pp.name == "BLE_UART_BC66"{
                    if pp.identifier.uuidString == LastConnectedPeripheral_udid{
                        print("Connect to \(pp.name ?? "")")
                        self.RestoredPeripheral = pp
                        self.RestoredPeripheral?.delegate = self
                        //print("\(dict[CBCentralManagerRestoredStateScanOptionsKey])")
                        break
                    }
                }
            }
        }
    }
    //#endif
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //print("ADV = \(advertisementData)")
        //print("ID = \(peripheral.identifier)")
        //print("-------->");

        for i in 0 ..< self.Peripheral_List.count {
            let obj = self.Peripheral_List.object(at: i) as! Microchip_Peripheral
            
            if(obj.peripheral?.identifier == peripheral.identifier) {
                //self.Peripheral_List.replaceObject(at: i, with: Microchip_Peripheral(device: peripheral, adv: advertisementData, rssi: RSSI))
                //print("[Microchip peripheral] Duplicate UUID")
                
                if(RSSI != obj.rssi){
                    let time = Date()
                    let time_stamp = Int(floor(time.timeIntervalSince1970 * 1000))%1000000

                    if obj.rssi_update_time == 0{
                        obj.rssi_update_time = time_stamp
                        obj.rssi = RSSI
                        print("RSSI init. \(RSSI)")
                        self.Peripheral_List.replaceObject(at: i, with: obj)
                        self.BLE_didDiscoverUpdateState?(centralManager!.isScanning)
                    }
                    else{
                        if(time_stamp - obj.rssi_update_time) > 2000{
                            obj.rssi_update_time = time_stamp
                            print("Update RSSI , old value = \(obj.rssi!), new = \(RSSI)")
                            obj.rssi = RSSI
                            self.Peripheral_List.replaceObject(at: i, with: obj)
                            self.BLE_didDiscoverUpdateState?(centralManager!.isScanning)
                        }
                    }
                }
                return
            }
        }
        
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            //print("didDiscoverPeripheral,loacl name = \(name) ")
            if scanOption == .ScanWithoutFilter{
                self.Peripheral_List.add(Microchip_Peripheral(device: peripheral, adv: advertisementData, rssi: RSSI))
                print("ScanWithoutFilter .Add peripheral,local name = \(name)")
                self.BLE_didDiscoverUpdateState?(centralManager!.isScanning)
            }
            else{
                if(ScanFilterString == ""){
                    //Filter by MCHP beacon data
                    print("\(name): Parsing beacon data..")
                    let beacondata = Data_Beacon_Information.Parsing_adv_data(advdata: advertisementData)
                    print("\(beacondata)")
                    if(beacondata != nil){
                        self.Peripheral_List.add(Microchip_Peripheral(device: peripheral, devName: name, deviceInfo: beacondata!, adv: advertisementData, rssi: RSSI))
                        print("[Microchip peripheral] Add peripheral,local name = \(name)")
                        self.BLE_didDiscoverUpdateState?(centralManager!.isScanning)
                    }
                    else{
                    }
                }
                else{
                    //print("[ScanFilter]didDiscoverPeripheral,loacl name = \(name) ")
                    let nameLowercase = name.lowercased()
                    if nameLowercase.contains(ScanFilterString){
                        //self.Peripheral_List.add(Microchip_Peripheral(device: peripheral, adv: advertisementData, rssi: RSSI))
                        self.Peripheral_List.add(Microchip_Peripheral(device: peripheral, devName: name))
                        print("ScanWithFilter .Add peripheral,local name = \(name)")
                        self.BLE_didDiscoverUpdateState?(centralManager!.isScanning)
                    }
                }
            }
        }
        else{
            /*
            //Debug for WILC Linux
            if peripheral.identifier.uuidString == "8B341857-9F40-5561-6174-B69E9D90DC21" || peripheral.identifier.uuidString == "3DF43A7B-89D1-FAE0-A85F-DCC62EEC0AA2" {
                self.Peripheral_List.add(Microchip_Peripheral(device: peripheral, devName: "Unnamed", deviceInfo:Data_Beacon_Information(), adv: advertisementData, rssi: RSSI))
                print("[Debug]Unnamed device")
                self.BLE_didDiscoverUpdateState?(centralManager!.isScanning)
            }
             */
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[centralManager] didConnect")
        activePeripheral = peripheral
        print("Peripheral ID = " + activePeripheral!.identifier.uuidString)
        LastConnectedPeripheral_udid = activePeripheral!.identifier.uuidString
        
        if central_init_option == .StatePreservation{
            UserDefaults.standard.set(LastConnectedPeripheral_udid, forKey: "STATE_PRESERVE_PERIPHERAL_UDID")
        }
        
        if #available(iOS 9.0, *) {
            if(central.isScanning)
            {
                print("Stop Scan")
                central.stopScan()
            }
        } else {
            // Fallback on earlier versions
        }
        
        //let sound: SystemSoundID = 1013
        //let sound: SystemSoundID = 1321
        //AudioServicesPlaySystemSound(sound)

        print("DiscoverServices. count = \(activePeripheral?.services?.count)")
        activePeripheral?.discoverServices(nil)
                
        if #available(iOS 9.0, *) {
            mtu = (activePeripheral?.maximumWriteValueLength(for:CBCharacteristicWriteType.withoutResponse))!
            
        } else {
            // Fallback on earlier versions
        }
        
        if #available(iOS 11.0, *){
            canSendData = (activePeripheral?.canSendWriteWithoutResponse)!
            if(canSendData){
                print("canSendWriteWithoutResponse = True")
            }
            else{
                print("canSendWriteWithoutResponse = False")
            }
        }else {
        }
        
        if #available(iOS 13.0, *){
            let extendedScan = CBCentralManager.supports(.extendedScanAndConnect)
            print("extendedScan = \(extendedScan)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[centralManager] didFailToConnect")
        
        var msg : String = ""
        
        if error != nil{
            print(error.debugDescription)
            msg = error!.localizedDescription
        }
        
        if(self.bleAdapterDelegate != nil) {
            self.bleAdapterDelegate?.OnConnected(false, message: msg)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[centralManager] didDisconnectPeripheral")
        
        var error_str: String = ""
        
        if(error != nil){
            print("error = \(error!),\(error!.localizedDescription)")
            error_str = error!.localizedDescription
        }
        
        if(self.bleAdapterDelegate != nil ) {
            /*
            let ver_str = UIDevice.current.systemVersion.components(separatedBy: ".")
            let ver = ver_str[0]
            if(Int(ver)! < 13){
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(Pairing_fail_handling), object: nil)
            }*/
            
            self.bleAdapterDelegate?.OnConnected(false, message: error_str)
        }
        
        ISSC_Peripheral = false
        
        activePeripheral = nil
        
        RestoredPeripheral = nil
        
        transmit = nil
        
        self.bleAdapterDelegate?.ISSC_Peripheral_Device(ISSC_Peripheral)
        
        self.BLE_File_Disconnected?()
    }
    
    //=======================================================================================================
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error == nil) {
            print("Peripheral UUID : \(peripheral.identifier.uuidString.utf8) found\r\n" );
            
            for service in peripheral.services! {
                let thisService = service as CBService
                print("Service uuid = \(thisService.uuid.uuidString)")
                
                activePeripheral?.discoverCharacteristics(nil, for: thisService)
            }
        } else {
            print("Service discovery was unsuccessfull");
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if(error == nil) {
            print("didDiscoverCharacteristics");
            
            for Char in service.characteristics! {
                let thisChar = Char as CBCharacteristic
                print("Characteristic uuid = \(thisChar.uuid.uuidString)")
                /*
                if(thisChar.uuid.uuidString == BLE_OTA_Characteristic1_uuid) {
                    print("SetNotify")
                }
                else if(thisChar.uuid.uuidString == BLE_OTA_Characteristic2_uuid) {
                    print("OTA Write Characteristic found!")
                }
                else if(thisChar.uuid.uuidString == UUIDSTR_ISSC_SPCP_CHAR) {
                    print("ISSC_SPCP_CHAR found")
                }
                else if(thisChar.uuid.uuidString == UUIDSTR_ISSC_AIR_PATCH_CONTROL) {
                    print("UUIDSTR_ISSC_AIR_PATCH_CONTROL ,setNotify")
                }
                else if(thisChar.uuid.uuidString == UUIDSTR_ISSC_AIR_PATCH_CHAR) {
                    print("UUIDSTR_ISSC_AIR_PATCH_CHAR")
                }*/
                
                //if(service.uuid.uuidString == UUIDSTR_MCHP_PROPRIETARY_SERVICE) {
                if(service.uuid == BLE_Constants.MCHP_PROPRIETARY_SERVICE) {
                    print("ISSC_PROPRIETARY_SERVICE")
                    
                    //if(thisChar.uuid.uuidString == UUIDSTR_MCHP_TRANS_RX) {
                    if(thisChar.uuid == BLE_Constants.MCHP_TRANS_TX) {
                        //print("ISSC_TRANS_RX")
                        print("MCHP_TRANS_TX")
                        
                        if Char.properties.contains(.write){
                            print("MCHP_TRANS_TX Char property : Write")
                            //print("write test data")
                        }
                        
                        WriteCharacteristic = Char
                    }
                    //else if(thisChar.uuid.uuidString == UUIDSTR_MCHP_TRANS_TX) {
                    else if(thisChar.uuid == BLE_Constants.MCHP_TRANS_RX) {
                        //print("ISSC_TRANS_TX")
                        print("MCHP_TRANS_RX. \(Char.properties)")
                        /*
                        print("\(CBCharacteristicProperties.broadcast.rawValue)")
                        print("\(CBCharacteristicProperties.read.rawValue)")
                        print("\(CBCharacteristicProperties.writeWithoutResponse.rawValue)")
                        print("\(CBCharacteristicProperties.write.rawValue)")
                        print("\(CBCharacteristicProperties.notify.rawValue)")
                        print("\(CBCharacteristicProperties.indicate.rawValue)")
                        print("\(CBCharacteristicProperties.authenticatedSignedWrites.rawValue)")
                        print("\(CBCharacteristicProperties.notifyEncryptionRequired.rawValue)")
                        print("\(CBCharacteristicProperties.indicateEncryptionRequired.rawValue)")
                            */
                        
                        TransparentChar = Char
                        
                        //Set Notify
                        peripheral.setNotifyValue(true, for: thisChar)
                        
                        //perform(#selector(Pairing_fail_handling), with: nil, afterDelay: 35)
                    }
                    //else if(thisChar.uuid.uuidString == UUIDSTR_ISSC_TRANS_CTRL) {
                    else if(thisChar.uuid == BLE_Constants.MCHP_TRANS_CTRL) {
                        //print("ISSC_TRANS_CTRL")
                        print("MCHP_TRANS_CTRL")
                                                
                        TransparentControl = Char
                        /*
                        transmit = ReliableBurstTransmit()
                        print("[ReliableBurstTransmit]init")
                        transmit?.delegate = self
                        transmit?.switchLibrary(false)
                        self.Write_type = CBCharacteristicWriteType.withoutResponse.rawValue
                        transmit?.enableReliableBurstTransmit(peripheral: peripheral, airPatchCharacteristic: TransparentControl!)
                        */
                    }
                }
                
                if(service.uuid == BLE_Constants.MCHP_PROPRIETARY_SERVICE) {
                    print("Device Capability : GATT protocol")
                }
                
                //if(Char.uuid == BLE_Constants.PSMID) {
                //}
                
                if(service.uuid == BLE_Constants.MCHP_TRCBP_SERVICE) {
                    if(Char.uuid == BLE_Constants.MCHP_TRCBP_CHAR) {
                        print("Device Capability : L2CAP")
                        
                        //if(activePeripheral == peripheral){
                        //    self.SetPeripheralCapability(p: activePeripheral!)
                        //}
                        
                        peripheral.setNotifyValue(true, for: Char)
                        peripheral.readValue(for: Char)
                    }
                }
                
                if(service.uuid == BLE_Constants.MCHP_UUIDSTR_DEVICE_INFO_SERVICE) {
                    if(Char.uuid == BLE_Constants.MCHP_UUIDSTR_MANUFACTURE_NAME_CHAR) {
                        print("[DIS]MANUFACTURE_NAME_CHAR")
                        self.activePeripheral?.readValue(for: thisChar)
                    }
                    else if(Char.uuid == BLE_Constants.MCHP_UUIDSTR_MODEL_NUMBER_CHAR) {
                        print("[DIS]MODEL_NUMBER_CHAR")
                        self.activePeripheral?.readValue(for: thisChar)
                    }
                    else if(Char.uuid == BLE_Constants.MCHP_UUIDSTR_SERIAL_NUMBER_CHAR) {
                        print("[DIS]SERIAL_NUMBER_CHAR")
                        self.activePeripheral?.readValue(for: thisChar)
                    }
                    else if(Char.uuid == BLE_Constants.MCHP_UUIDSTR_HARDWARE_REVISION_CHAR) {
                        print("[DIS]HARDWARE_REVISION_CHAR")
                        self.activePeripheral?.readValue(for: thisChar)
                    }
                    else if(Char.uuid == BLE_Constants.MCHP_UUIDSTR_FIRMWARE_REVISION_CHAR) {
                        print("[DIS]FIRMWARE_REVISION_CHAR")
                        self.activePeripheral?.readValue(for: thisChar)
                    }
                    else if(Char.uuid == BLE_Constants.MCHP_UUIDSTR_SOFTWARE_REVISION_CHAR) {
                        print("[DIS]SOFTWARE_REVISION_CHAR")
                        self.activePeripheral?.readValue(for: thisChar)
                    }
                    else if(Char.uuid == BLE_Constants.MCHP_UUIDSTR_SYSTEM_ID_CHAR) {
                        print("[DIS]SYSTEM_ID_CHAR")
                        self.activePeripheral?.readValue(for: thisChar)
                    }
                    else if(Char.uuid == BLE_Constants.MCHP_UUIDSTR_IEEE_11073_20601_CHAR) {
                        print("[DIS]IEEE_11073_20601_CHAR")
                        self.activePeripheral?.readValue(for: thisChar)
                    }
                }
            }
        }
        else {
            print("Characteristics discovery was unsuccessfull");
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if(error == nil) {
            print("didWriteValueForCharacteristic");
            print("Characteristic uuid = \(characteristic.uuid.uuidString)")
            
            //if(characteristic.uuid == BLE_Constants.MCHP_TRANS_TX) {
            if(characteristic.uuid == BLE_Constants.MCHP_TRANS_RX) {
                //self.BLE_File_WriteCallback?(self.Write_type!, true, ReliableWriteLen)
                self.BLE_WriteResponseCallback?(true)
            }
            else if(characteristic.uuid == BLE_Constants.MCHP_TRANS_CTRL || characteristic.uuid == BLE_Constants.MCHP_TRCBP_CTRL ) {
                
                let group_id = self.BLE_UART_write_comd.group_command
                let sub_id = self.BLE_UART_write_comd.sub_command
                
                print("BLE UART Command = \(group_id.rawValue),\(sub_id)")
                
                if(group_id != .default_value){
                    
                    BLE_UART_write_comd = BLE_UART_Command()
                    print("Clear group_command")
                    
                    self.GATT_BLE_UART_File_UpdateState?(group_id , sub_id)
                }
            }
        }
        else {
            if(characteristic.uuid == BLE_Constants.MCHP_TRANS_TX) {
                //self.BLE_File_WriteCallback?(self.Write_type!, false, 0)
                self.BLE_WriteResponseCallback?(false)
            }
            
            print("didWriteValueForCharacteristic,Error = \(error!.localizedDescription)")
            
            if(self.bleAdapterDelegate != nil) {
                self.bleAdapterDelegate?.OnConnected(false, message: error!.localizedDescription)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if(error == nil) {
            //print("didUpdateValueForCharacteristic");
            //print("Characteristic uuid = \(characteristic.uuid.uuidString)")
            
            /*
            if((characteristic.uuid == BLE_Constants.PSMID) || (characteristic.uuid == BLE_Constants.MCHP_TRCBP_CHAR)) {
                
                peripheral.setNotifyValue(false, for: characteristic)
                
                self.L2Cap_PSM_Value = characteristic.value
                print("L2Cap_PSM_Value = \(self.L2Cap_PSM_Value! as NSData),\(self.L2Cap_PSM_Value?.count)")
                
                if active_data_path == .L2CAP{
                    if(self.connection == nil) {
                        self.Connect_L2CAP_PSM()
                    }
                }
            }*/
        
            if(characteristic.uuid == BLE_Constants.MCHP_TRANS_RX) {
                print("MCHP_TRANS_RX")
                /*
                if(self.Data_Transmission_Timer == nil){
                    self.Data_Transmission_Timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(BLEAdapter.Data_Transmission_Timer_Selector), userInfo: nil, repeats: true)
                    
                    self.Transmission_timer_counter = Receive_timeout.GATT_timeout/500
 
                    print("Data_Transmission_Timer start!,\(self.Transmission_timer_counter)")
                }
                else{
                    if(characteristic.value != nil){
                        self.Transmission_timer_counter = Receive_timeout.GATT_timeout/500
                    }
                }*/
                
                if(characteristic.value != nil) {
                    //self.BLE_File_receiveCallback?(characteristic.value!)
                    self.BLE_DataReceiveCallback?(characteristic.value!)
                }
            }
            else if(characteristic.uuid == BLE_Constants.MCHP_TRANS_CTRL || characteristic.uuid == BLE_Constants.MCHP_TRCBP_CTRL) {
                //print("Control point characteristic")
                print("MCHP_TRANS_Control")
                //print("Characteristic value = \(characteristic.value! as NSData)")
                
                if let data = characteristic.value{
                    let ble_uart_event = BLE_UART_Command.Received_Event(receive: data)
                    
                    if(ble_uart_event != nil){
                        let group_id = ble_uart_event!.group_command
                        let sub_id = ble_uart_event!.sub_command
                        var result: UInt8 = 0x00
                        
                        if(group_id == .checksum_mode && sub_id == 0x02){
                            self.BLE_UART_Receive_Checksum = ble_uart_event!.command_parameters[0]
                            print("Receive checksum = \(self.BLE_UART_Receive_Checksum)")
                            //self.BLE_File_Receive_Checksum?()
                        }
                        else if(group_id == .fixedPattern_mode && sub_id == 0x02){
                            let last_number_h = ble_uart_event!.command_parameters[0]
                            let last_number_l = ble_uart_event!.command_parameters[1]
                            self.BLE_FixedPattern_Last_Number?(last_number_h, last_number_l)
                            print("[Fixed data pattern]Last number = \(last_number_h),\(last_number_l)")
                        }
                        else if(group_id == .ble_parameter_update){
                            if(ble_uart_event?.command_parameters != nil && ble_uart_event?.command_parameters.count == 1){
                                let notify_value = ble_uart_event?.command_parameters[0]
                                result = UInt8(sub_id) + UInt8(notify_value!)
                                print("[ble connction parameter update] result = \(result)")
                            }
                        }
                        
                        if(group_id != .ble_parameter_update){
                            self.GATT_BLE_UART_File_UpdateState?(group_id , sub_id)
                        }
                        else{
                            self.GATT_BLE_UART_File_UpdateState?(group_id , result)
                        }
                    }
                    else{
                        print("DecodeReliableBurstTransmitEvent. \(characteristic.value!)")
                        transmit?.decodeReliableBurstTransmitEvent(eventData: characteristic.value! as NSData)
                    }
                }
            }
            else if(characteristic.uuid == BLE_Constants.MCHP_UUIDSTR_MANUFACTURE_NAME_CHAR) {
                print("\nDIS_MANUFACTURE_NAME = \(String(data: characteristic.value!, encoding: .utf8) ?? "N/A")")
                self.DIS_Manufacture = String(data: characteristic.value!, encoding: .utf8)
            }
            else if(characteristic.uuid == BLE_Constants.MCHP_UUIDSTR_MODEL_NUMBER_CHAR) {
                print("\nDIS_MODEL_NUMBER = \(String(data: characteristic.value!, encoding: .utf8) ?? "N/A")")
                self.DIS_Model = String(data: characteristic.value!, encoding: .utf8)
            }
            else if(characteristic.uuid == BLE_Constants.MCHP_UUIDSTR_SERIAL_NUMBER_CHAR) {
                print("\ncharacteristic value = \(characteristic.value! as NSData)")
                print("\nDIS_SERIAL_NUMBER = \(String(data: characteristic.value!, encoding: .utf8) ?? "N/A")")
                self.DIS_SerialNumber = String(data: characteristic.value!, encoding: .utf8)
            }
            else if(characteristic.uuid == BLE_Constants.MCHP_UUIDSTR_HARDWARE_REVISION_CHAR) {
                print("\nDIS_HARDWARE_REVISION = \(String(data: characteristic.value!, encoding: .utf8) ?? "N/A")")
                self.DIS_HardwareVersion = String(data: characteristic.value!, encoding: .utf8)
            }
            else if(characteristic.uuid == BLE_Constants.MCHP_UUIDSTR_FIRMWARE_REVISION_CHAR) {
                print("\nDIS_FIRMWARE_REVISION = \(String(data: characteristic.value!, encoding: .utf8) ?? "N/A")")
                self.DIS_FirmwareVersion = String(data: characteristic.value!, encoding: .utf8)
            }
            else if(characteristic.uuid == BLE_Constants.MCHP_UUIDSTR_SOFTWARE_REVISION_CHAR) {
                print("\nDIS_SOFTWARE_REVISION = \(String(data: characteristic.value!, encoding: .utf8) ?? "N/A")")
                self.DIS_SoftwareVersion = String(data: characteristic.value!, encoding: .utf8)
            }
            else if(characteristic.uuid == BLE_Constants.MCHP_UUIDSTR_SYSTEM_ID_CHAR) {
                print("\nDIS_SYSTEM_ID = \(characteristic.value! as NSData))")
                
                if characteristic.value != nil{
                    self.DIS_SystemID = DIS_ConvertData(dat: characteristic.value!)
                }
            }
            else if(characteristic.uuid == BLE_Constants.MCHP_UUIDSTR_IEEE_11073_20601_CHAR) {
                print("DIS_IEEE_11073_20601 = \(characteristic.value! as NSData))")
                
            }
            else {
                if(self.bleAdapterDelegate != nil) {
                    self.bleAdapterDelegate?.BLEDataIn(characteristic.value!)
                }
            }
        }
        else {
            print("didUpdateValueForCharacteristic,Error")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if(error == nil) {
            print("didUpdateNotificationStateForCharacteristic");
            print("Characteristic uuid = \(characteristic.uuid.uuidString)")
            if(characteristic.isNotifying) {
                print("Notification has started")
                /*
                if(characteristic.uuid.uuidString == UUIDSTR_kCharacteristicUUID){
                    
                    peripheral.readValue(for: characteristic)
                }
                else if(characteristic.uuid.uuidString == UUIDSTR_CBUUIDL2CAppSMCharacteristicString) {
                    print("Read CBUUIDL2CAppSMCharacteristic(PSM)")
                    peripheral.readValue(for: characteristic)
                }*/
                
                if(characteristic.uuid == BLE_Constants.MCHP_TRANS_RX) {
                    print("Transparent CCCD is enabled!,uuid = \(BLE_Constants.MCHP_TRANS_RX)")
                    
                    /*
                    let ver_str = UIDevice.current.systemVersion.components(separatedBy: ".")
                    let ver = ver_str[0]
                    if(Int(ver)! < 13){
                        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(Pairing_fail_handling), object: nil)
                    }*/
                    
                    if(self.activePeripheral?.state == CBPeripheralState.connected){

                        if let filterServices = self.activePeripheral?.services?.filter({$0.uuid == BLE_Constants.MCHP_PROPRIETARY_SERVICE}){
                            print("\(filterServices)")
                        }
                        else{
                            print("Service not support")
                        }
                        self.Connection_Complete?()
                    }
                }
                
                if(self.bleAdapterDelegate != nil) {
                    
                    if(TransmitCharacteristic && ReceiveCharacteristic) {
                        ISSC_Peripheral = true
                    }
                    else {
                        ISSC_Peripheral = false
                    }
                    
                    print("ISSC_Peripheral = \(ISSC_Peripheral)")
                    
                    self.bleAdapterDelegate?.UpdateMTU(mtu)
                    
                    self.bleAdapterDelegate?.ISSC_Peripheral_Device(ISSC_Peripheral)
                }
            }
        }
        else {
            print("didUpdateNotificationStateForCharacteristic,Error")
            
            var error_str: String = ""
            
            //print("error = \(error),\(error!.localizedDescription)")
            error_str = error!.localizedDescription
            
            if let e1 = error as? CBError {
                print("CBError: \(e1)")
            }
            
            if let e2 = error as? CBATTError {
                print("CBATTError: \(e2)")
            }
            
            if error_str.contains("not supported"){
                print("error = \(error_str)")
            }
            else{
                print("error = \(error_str)")
                if(self.bleAdapterDelegate != nil) {
                    self.bleAdapterDelegate?.OnConnected(false, message: error_str)
                }
            }
        }
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        if #available(iOS 11.0, *) {
            canSendData = peripheral.canSendWriteWithoutResponse
            //print("[BLEAdapter]canSendData = \(canSendData)")
        } else {
            // Fallback on earlier versions
        }
    }
    
    // MARK: - L2CAP
    /*
    func SetPeripheralCapability(p: CBPeripheral) {
        if(Peripheral_List.count != 0) {
            print(#function)
            
            for i in 0 ..< self.Peripheral_List.count {
                let obj = self.Peripheral_List.object(at: i) as! Microchip_Peripheral
                let peripheral = obj.peripheral
                if(peripheral?.identifier.uuidString == p.identifier.uuidString) {
                    obj.capability = Peripheral_Capability.L2CAP.rawValue
                    print("Microchip peripheral = \(obj)")
                    break
                }
            }
        }
    }
    
    func GetPeripheralCapability() -> UInt8 {
        print(#function)
        
        if(L2Cap_Role_Central == true){
            
            var capability: UInt8 = Peripheral_Capability.GATT.rawValue
            
            for i in 0 ..< self.Peripheral_List.count {
                let obj = self.Peripheral_List.object(at: i) as! Microchip_Peripheral
                let p = obj.peripheral
                if(p?.identifier.uuidString == activePeripheral?.identifier.uuidString) {
                    if(obj.capability != nil){
                        capability = obj.capability!
                        print("Device found!,capability = \(capability)")
                    }
                    break
                }
            }
        
            if(capability == Peripheral_Capability.GATT.rawValue) {
                if(Write_type == nil) {
                    self.Write_type = CBCharacteristicWriteType.withoutResponse.rawValue
                    print("GATT WriteType = \(self.Write_type ?? -1)")
                }
            }
            
            return capability
        }
        else {
            return Peripheral_Capability.L2CAP.rawValue
        }
    }
    
    //Peripheral
    func PublishL2Cap() {
        self.BT_peripheral.publish = true
        
        print(#function)
    }
    
    //Central
    func L2CAP_Connect_Peripheral(peripheral_uuid: String) {
        print(#function)
        
        if self.centralManager!.isScanning{
            self.centralManager?.stopScan()
            
            if self.bleScanTimer != nil{
                if bleScanTimer!.isValid{
                    bleScanTimer?.invalidate()
                    bleScanTimer = nil
                }
            }
        }
        
        for i in 0 ..< self.Peripheral_List.count {
            let obj = self.Peripheral_List.object(at: i) as! Microchip_Peripheral
            let p = obj.peripheral
            if(p?.identifier.uuidString == peripheral_uuid) {
                activePeripheral = obj.peripheral
                break
            }
        }
        
        centralManager?.connect(activePeripheral!, options: nil)
        activePeripheral?.delegate = self
        
    }
    
    func Connect_L2CAP_PSM() {
        if self.L2Cap_PSM_Value == nil{
            print("PSM value is invalid")
            return
        }
        
        let dat = self.L2Cap_PSM_Value!
        
        let len = dat.count
        print("Connect_L2CAP_PSM")
        print("data len = \(len),\(dat as NSData) ")
        
        if(len == 2){
            let bytes = [UInt8](dat)
            
            var tmp_psm: UInt16 = 0
            tmp_psm = UInt16(bytes[1])
            
            self.Open_L2CAP(psm: tmp_psm)
        }
        else if(len == 4){
            
        }
        else{
            //psm = 0xC0
            if let string = String(data: dat, encoding: .utf8), let psm = UInt16(string) {
                print("L2CAP channel,psm = \(psm)")
                
                self.Open_L2CAP(psm: psm)
            } else {
                print("Problem decoding PSM")
            }
        }
    }
    
    func Enable_L2CAP_Control() {
        print(#function)
        
        self.l2capTransparentControl = nil
        
        if let filterServices = self.activePeripheral?.services?.filter({$0.uuid == BLE_Constants.MCHP_TRCBP_SERVICE}){
            if let filter_ctrl_chars = filterServices[0].characteristics?.filter({$0.uuid == BLE_Constants.MCHP_TRCBP_CTRL }){
                print("TRCBP_Control_Char is found. \(filter_ctrl_chars[0])")
                self.l2capTransparentControl = filter_ctrl_chars[0]
            }
            
            if let filter_data_chars = filterServices[0].characteristics?.filter({$0.uuid == BLE_Constants.MCHP_TRCBP_CHAR }){
                print("TRCBP_Data_Char is found. \(filter_data_chars[0])")
            }
        }
        
        /*
        if let services = self.activePeripheral?.services{
            for ble_service in services{
                if ble_service.uuid == BLE_Constants.MCHP_TRCBP_SERVICE{
                    if let char = ble_service.characteristics{
                        for ble_char in char{
                            if ble_char.uuid == BLE_Constants.MCHP_TRCBP_CTRL{
                                print("L2CAP Control characterisitc found!\(ble_char)")
                                self.l2capTransparentControl = ble_char
                                break
                            }
                        }
                    }
                }
            }
        }*/
        
        if(self.l2capTransparentControl != nil){
            self.activePeripheral?.setNotifyValue(true, for: l2capTransparentControl!)
        }
    }
    
    func L2CAP_connect(peripheral: CBPeripheral, psm: UInt16, connectionHandler:  @escaping L2CapConnectionCallback)  {
        let l2Connection = L2CapCentralConnection(peripheral: peripheral, psm: psm, connectionCallback: connectionHandler)

        self.connections[peripheral.identifier] = l2Connection
    }
    
    func Open_L2CAP(psm: UInt16) {
        print("Open L2CAP channel = \(psm)")
        
        self.connection = nil
        
        L2CAP_connect(peripheral: activePeripheral!, psm: psm){ connection in
            self.connection = connection
            print("L2CAP_connect")
            
            self.activePeripheral?.delegate = self
            
            self.Enable_L2CAP_Control()
            
            self.L2Cap_Connection_Complete?()
            
            self.connection?.receiveCallback = { (connection,data,time1,time2) in
                self.L2Cap_receiveCallback?(data,time1,time2)
            }
            
            self.connection?.sentDataCallback = { (connection, write_len, time_interval) in
                self.L2Cap_sentDataCallback?(write_len, time_interval)
            }
        }
    }
    
    func L2CAP_send_with_channel(data: Data, ch: UInt8) {
        print("L2CAP_send_with_channel")
        
        if ch == 0x01 {
            self.connection?.send(data: data)
        }
        else{
            self.second_connection?.send(data: data)
        }
    }
    
    func L2CAP_send(data: Data) {
        guard self.connection != nil else {
            print("L2CAP is disconnected!")
            return
        }
        
        if self.L2Cap_PSM_Value?.count != 4{
            self.connection?.send(data: data)
        }
        else{
            L2CAP_send_with_channel(data: data, ch: 0x02)
        }
    }
    
    func L2CAP_CloseStream() {
        if let connection = self.connection {
            print(#function)
            
            if(connection.CloseStream()) {
                print("Close stream success")
                self.connection = nil
                self.connections = [:]
            }
            
            if(self.L2Cap_PSM_Value != nil){
                if self.L2Cap_PSM_Value?.count == 4{
                    self.second_connection = nil
                }
            }
        }
    }
    
    func L2CAP_ConnectionState() -> Bool{
        if(self.connection != nil) {
            return true
        }
        else{
            return false
        }
    }
    
    func L2CAP_Termination(){
        if let connection = self.connection {
            connection.L2Cap_terminate()
        }
    }
     */
    // MARK: - ReliableBurstDataTransmit
    func ReliableBurstInit() {
        ReliableWriteLen = 0
    }
    
    func SetWriteType(new_value: Int) {
        self.Write_type = new_value
        
        print(#function)
    }
    
    func GetWriteType() -> Int{
        if(self.WriteCharacteristic == nil) {
            print("Error!")
            return -1
        }
        else{
            if(self.Write_type == nil){
                //print("WriteChar properties = \(self.WriteCharacteristic?.properties)")
                print("WriteChar properties = \(String(describing: self.WriteCharacteristic?.properties))")
                self.Write_type = CBCharacteristicWriteType.withoutResponse.rawValue
                print("writeType = \(self.Write_type)")
            }
        }
        //print(#function)
        
        return self.Write_type!
        
    }
    
    func GetTransmitSize() -> Int {
        let write_length = transmit?.getTransmitSize()
        if(write_length != nil){
            print("[ReliableBurstTransmit] maximumWriteValueLength = \(write_length!)")
        }
        
        //What's the MTU length for Write Command and Write without response ???
        if(Write_type == CBCharacteristicWriteType.withResponse.rawValue){
            let length = activePeripheral?.maximumWriteValueLength(for: CBCharacteristicWriteType.withResponse)
            print("[WriteWithResponse] maximumWriteValueLength = \(length!)")
            //write_length = length
        }
        
        if(write_length != nil){
            return write_length!
        }
        else{
            return 0
        }
    }
    
    func sendPICkitCommand(data: Data){
        print("sendPICkitCommand. data = \(data as NSData)")
        activePeripheral?.writeValue(data, for: TransparentChar!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func sendTransparentData(data: Data) {
        
        if(self.activePeripheral == nil || self.WriteCharacteristic == nil) {
            return
        }
        
        //print("WriteChar uuid = \(WriteCharacteristic?.uuid.uuidString)")
        //print("\(WriteCharacteristic?.properties.rawValue),\(CBCharacteristicProperties.writeWithoutResponse.rawValue),\(CBCharacteristicProperties.write.rawValue)")
        
        if(Write_type == CBCharacteristicWriteType.withoutResponse.rawValue){
            if(transmit == nil) {
                return
            }
            
            if((transmit?.canSendReliableBurstTransmit())! && (transmit?.isReliableBurstTransmitSupport())!) {
                print("Can't send reliableburstdata, Not support!")
                return
            }
            
            //print("[ReliableBurstTransmit]sendTransparentData")
               
            transmit?.reliableBurstTransmit(data: data, transparentDataWriteChar: WriteCharacteristic!)
        }
        else {
            print("sendTransparentData")
            
            activePeripheral?.writeValue(data, for: WriteCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    //reliableBurstData Delegate
    
    func didWriteDataLength(_ len:Int) {
        ReliableWriteLen += len
        //print("[ReliableBurst]didWriteDataLength = \(len), \(ReliableWriteLen)")
    }
    
    func didSendDataWithCharacteristic(_ transparentDataWriteChar: CBCharacteristic) {
        //print("[ReliableBurstTransmit]didSendDataWithCharacteristic, uuid = \(transparentDataWriteChar.uuid.uuidString)")

        self.BLE_File_WriteCallback?(self.Write_type!, true, ReliableWriteLen)
    }
    
    // MARK: - BLE UART
    
    @objc func Pairing_fail_handling() {
        let ver_str = UIDevice.current.systemVersion.components(separatedBy: ".")
        //print(ver_str, ver_str[0])
        //print(ver_str[0])
        let ver = ver_str[0]
        
        if(Int(ver)! <= 13){
            print("\n Pairing fail error handling")
        
            if self.TransparentChar?.isNotifying == false{
                print("Notification is not enabled(35 seconds timeout error)")
            
                if(self.bleAdapterDelegate != nil) {
                    if(self.activePeripheral != nil && self.activePeripheral?.state == CBPeripheralState.connected){
                        self.disconnectPeripheral()
                    }
                    self.bleAdapterDelegate?.OnConnected(false, message: "Notification is not enabled")
                }
            }
        }
    }
    
    @objc func Data_Transmission_Timer_Selector() {
        self.Transmission_timer_counter -= 1
        
        if(self.Transmission_timer_counter == 0){
            print("[GATT Receive data]Timeout!!")
            
            self.Data_Transmission_Timer?.invalidate()
            self.Data_Transmission_Timer = nil

            self.BLE_File_receiveCallback?(Data())
        }
    }
    
    func BLE_UART_Data_Checksum(dat: Data) -> UInt8{
        var sum : UInt32 = 0
        
        let bytes : NSData = dat as NSData
        var buf = [UInt8](repeating:0, count:bytes.length)
        bytes.getBytes(&buf, length: bytes.length)
        
        print(#function)
        //print("dat = \(dat as NSData)")
        print("data length = \(dat.count)")
        
        for i in 0..<dat.count {
            sum += UInt32(buf[i])
        }
        print("sum = \(sum)")
        
        var bigEndian = sum.bigEndian
        let count = MemoryLayout<UInt32>.size
        print("UInt32.size = \(count)")
        let bytePtr = withUnsafePointer(to: &bigEndian){
            $0.withMemoryRebound(to: UInt8.self, capacity: count){
                       UnsafeBufferPointer(start: $0, count: count)
                
            }
        }
        let byteArray = Array(bytePtr)

        print("BLE_UART_Data_Checksum = \(byteArray[3])")
        
        return byteArray[3]
    }
    
    func BLE_Connection_Parameter_Update(data: Data) {
        print(#function)
        
        var param = Data()
        param.append(0x80)
        param.append(BLE_UART_Group_Command.ble_parameter_update.rawValue)
        param.append(0x01)
        param.append(data)
        
        print("ble_connection_param = \(param as NSData)")
        
        activePeripheral?.writeValue(param, for: TransparentControl!, type: .withResponse)
    }
    
    func BLE_Data_Transmission_Checksum(Checksum: UInt8) {
        
        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .checksum_mode
        self.BLE_UART_write_comd.sub_command = 0x02
        self.BLE_UART_write_comd.command_parameters = [Checksum]
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        print("BLE_Data_Transmission_Checksum,write value = \(dat as NSData)")

        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        self.BLE_UART_write_comd.group_command = .default_value
        self.BLE_UART_write_comd.sub_command = 0
    }
    
    func Transmission_Data_Size(size: UInt32) {
        let byte1 = UInt8(size & 0x000000FF)
        let byte2 = UInt8((size & 0x0000FF00) >> 8)
        let byte3 = UInt8((size & 0x00FF0000) >> 16)
        let byte4 = UInt8((size & 0xFF000000) >> 24)

        var len = [UInt8](repeating: 0, count: 4)
        len[0] = byte4
        len[1] = byte3
        len[2] = byte2
        len[3] = byte1
        
        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .control
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_data_length.rawValue
        self.BLE_UART_write_comd.command_parameters = len
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
 
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print("Transmission_Data_Size = \(dat as NSData)")
    }
    
    func BLE_UART_DataPath(datapath: Peripheral_Capability) {
        //print(#function)
        self.active_data_path = datapath
        
        print("active_data_path = \(self.active_data_path)")
    }
    
    func Query_BLE_UART_DataPath() -> Peripheral_Capability {
        print(#function)
        return self.active_data_path
    }
    
    func BLE_UART_SetDataPath(datapath: Peripheral_Capability) {

        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .control
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_path.rawValue
        self.BLE_UART_write_comd.command_parameters.append(datapath.rawValue)
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print("BLE_UART_SetDataPath, command = \(dat as NSData)")
    }
    
    func Enable_checksum_function() {
        
        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .checksum_mode
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_start.rawValue
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)

        print(#function)
        
        if active_data_path == .GATT{
            print("active_data_path = GATT")
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
            
            ReliableBurstInit()
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
    }
    
    func Disable_checksum_function() {
            
        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .checksum_mode
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_end.rawValue
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print(#function)
    }
    
    func Enable_Go_through_UART_Mode() {
        
        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .uart_mode
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_start.rawValue
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)

        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            print("l2capTransparentControl = \(String(describing: l2capTransparentControl))")
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print(#function)
    }
    
    func Disable_Go_through_UART_Mode() {

        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .uart_mode
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_end.rawValue
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print(#function)
    }
    
    func Enable_Loopback_Mode() {
        
        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .loopback_mode
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_start.rawValue
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
            
            ReliableBurstInit()
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print(#function)
    }
    
    func Disable_Loopback_Mode() {
        
        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .loopback_mode
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_end.rawValue
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print(#function)
    }
    
    func Enable_fixed_data_pattern() {
        
        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .fixedPattern_mode
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_start.rawValue
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print(#function)
    }
    
    func Disable_fixed_data_pattern() {

        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .fixedPattern_mode
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_end.rawValue
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print(#function)
    }
    
    func Reply_fixed_data_last_number(high_byte: UInt8, Low_byte: UInt8) {
        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .fixedPattern_mode
        self.BLE_UART_write_comd.sub_command = 0x02
        self.BLE_UART_write_comd.command_parameters.append(high_byte)
        self.BLE_UART_write_comd.command_parameters.append(Low_byte)
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print("Reply_fixed_data_last_number, command = \(dat as NSData)")
    }
    
    func BLE_Data_Transmission_Start() {

        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .control
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_start.rawValue
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print(#function)
    }
    
    func BLE_Data_Transmission_End() {
        
        self.BLE_UART_write_comd = BLE_UART_Command()
        self.BLE_UART_write_comd.group_command = .control
        self.BLE_UART_write_comd.sub_command = BLE_UART_Sub_Command.transmission_end.rawValue
        
        let dat = BLE_UART_Command.write_data(format: self.BLE_UART_write_comd)
        
        if active_data_path == .GATT{
            activePeripheral?.writeValue(dat, for: TransparentControl!, type: .withResponse)
        }
        else{
            activePeripheral?.writeValue(dat, for: l2capTransparentControl!, type: .withResponse)
        }
        
        print(#function)
    }
}
