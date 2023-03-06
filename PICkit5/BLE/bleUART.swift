//
//  bleUART.swift
//  BleUARTLib
//
//  Created by WSG Software on 2021/5/6.
//

import Foundation
import CoreBluetooth

public typealias PICkitError = String

public enum PICkit_OpCode: UInt8, CaseIterable {
    case BLE_PTG_INIT = 0x01
    case BLE_PTG_UNINIT = 0x02
    case BLE_PTG_REINIT = 0x03
    case BLE_PTG_BROWSE_SD_CARD = 0x04
    case BLE_PTG_LOAD_IMAGE = 0x05
    case BLE_PTG_GO = 0x06
    case BLE_PTG_STATUS = 0x07
    case BLE_PTG_ACTIVE_IMAGE = 0x08
    case BLE_PTG_GET_IMAGE_STATS = 0x09
    case BLE_PTG_SET_IMAGE_STATS = 0x0A
}

enum PICkit_Response: UInt8, CaseIterable {
    case BLE_PTG_RESP_OK = 0x80
    case BLE_PTG_RESP_FAIL = 0x99
    case BLE_PTG_RESP_DATA = 0xA0
    case BLE_PTG_RESP_UNKNOWN = 0xff
}

struct PICkit_ResponseData_Parser {
    var opcode: UInt8 = 0
    var status: UInt8 = 0
    var dataLength: Int = 0
    
    static func HeaderParsing(dat: Data) -> PICkit_ResponseData_Parser? {
        var header = PICkit_ResponseData_Parser()
        let bytes = [UInt8](dat)
        let len = dat.count
        if(len >= 4){
            let allCommandValuye = PICkit_OpCode.allCases
            if(allCommandValuye.filter({$0.rawValue == bytes[0]}).isEmpty){
                print("command error.\(bytes[0])")
                return nil
            }
            
            header.opcode = bytes[0]
            
            let allResponseValue = PICkit_Response.allCases
            if(allResponseValue.filter({$0.rawValue == bytes[1]}).isEmpty){
                print("Unknown status value!")
                return nil
            }
            
            header.status = bytes[1]
            
            header.dataLength = Int(bytes[2]) + Int(bytes[3] << 8)
            
            return header
        }
        return nil
    }
    
    static func DataComplete(dat: Data) -> Bool?{
        if(dat.count >= 2){
            let RespOk = dat.subdata(in: dat.count-2..<dat.count)
            if(RespOk == Data([PICkit_OpCode.BLE_PTG_BROWSE_SD_CARD.rawValue, PICkit_Response.BLE_PTG_RESP_OK.rawValue])){
                print("RespOk = \(RespOk as NSData)")
                return true
            }
        }
        return nil
    }
}

struct PICkit_Command_Response {
    var opcode: UInt8 = 0
    var status: UInt8 = 0
    var parameters: [UInt8] = []
    
    init() {}
    
    static func parsing(dat: Data) -> PICkit_Command_Response? {
        var PICkit_Resp = PICkit_Command_Response()
        
        let bytes = [UInt8](dat)
        let len = dat.count
        if(len >= 2){
            let allCommandValuye = PICkit_OpCode.allCases
            if(allCommandValuye.filter({$0.rawValue == bytes[0]}).isEmpty){
                print("command error.\(bytes[0])")
                return nil
            }
            
            PICkit_Resp.opcode = bytes[0]
            
            let allResponseValue = PICkit_Response.allCases
            if(allResponseValue.filter({$0.rawValue == bytes[1]}).isEmpty){
                print("Unknown status value!")
                return nil
            }
            
            PICkit_Resp.status = bytes[1]
            
            if(len > 4){
                let dataLen = Int(bytes[2]) + Int(bytes[3] << 8)
                //print("dataLen = \(dataLen)")
                if(len < (dataLen+4)){
                    print("dataLen error!.\(dataLen),\(len)")
                    return nil
                }

                for i in 0..<(len-4){
                    PICkit_Resp.parameters.append(bytes[i+4])
                }
                
            }
            return PICkit_Resp
        }
        return nil
    }
}

public class bleUART: NSObject, BLEAdapterDelegate {
    
    var bleAdapter : BLEAdapter?
    
    private static var mInstance : bleUART?
    
    public var callback : bleUARTCallBack?
    
    var timer : Timer?
    
    var PTGError : Bool = false
    
    var TaskUARTCallback: ((PICkitError?) -> Void)?
    
    var PICkitCommand: PICkit_OpCode = .BLE_PTG_INIT
    
    var SD_card_files = Data()
    
    var GetResponseData = false
    
    var ResponseData = Data()
    
    var ResponseDataHeader: PICkit_ResponseData_Parser?
    
    var DataLog = Data()
    
    var PTGImage = ""
    
    let commandStr : [String] = ["", "BLE_PTG_INIT", "BLE_PTG_UNINIT", "BLE_PTG_REINIT", "BLE_PTG_BROWSE_SD_CARD", "BLE_PTG_LOAD_IMAGE", "BLE_PTG_GO" , "BLE_PTG_STATUS", "BLE_PTG_ACTIVE_IMAGE", "BLE_PTG_GET_IMAGE_STATS" , "BLE_PTG_SET_IMAGE_STATS"]
    
    // MARK: - Public API
    
    public class func sharedInstace(option : CentralOption) -> bleUART {
        if(mInstance == nil) {
            mInstance = bleUART(option: option)
            print("bleUART create instance. option = \(option).\(CFGetRetainCount(self))")
        }
        return mInstance!
    }
    
    public init(option: CentralOption) {
        print("bleUART init.")
        super.init()
        
        if self.bleAdapter == nil{
            print("bleAdapter is nil")

            bleAdapter = BLEAdapter.sharedInstace(option: option)
            
            bleAdapter?.bleAdapterDelegate = self
            
            SetATTConfig(config: .withResponse)
            
            BLE_Scan_Connect_Handler()
            
            GATT_Write_Callback()
            
            GATT_Receive_Callback()
        }
    }
    
    deinit {
        print("bleUART deinit")
    }
        
    public func DestroyInstance(){
        self.bleAdapter?.DestroyInstance()
        bleAdapter = nil
        TaskUARTCallback = nil
        bleUART.mInstance = nil
    }
    
    /**
     Scans for BLE peripheral with a timer. If timeout, stop scanning the peripherals

     - parameter scanTimeout: BLE scan time. default is 60 seconds
     - parameter scanConfig: Peripheral scan option
     - returns: None
    */
    public func bleScan(scanTimeout:Int = 60, scanConfig: ScanConfiguration = .Scan){
        print(#function)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.bleAdapter?.findAllBLEPeripherals(Double(scanTimeout), scanOption: scanConfig)
        }
    }
    
    public func bleScan(scanTimeout:Int = 60, scanConfig: ScanConfiguration = .ScanWithFilter, ScanFilter: String){
        
        print("bleScan , filter string = \(ScanFilter)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.bleAdapter?.ScanFilterString = ScanFilter
            //self.bleAdapter?.findAllBLEPeripherals(Double(scanTimeout), scanOption: scanConfig)
            self.bleAdapter?.findAllBLEPeripherals(Double(scanTimeout), scanOption: .ScanContinue)
        }
    }
    
    /**
     Connect to a peripheral

     - parameter device_id: The uuid string of peripheral to which the central is attempting to connect
     - returns: None
    */
    public func bleConnect(device_id: String){
        print(#function)
        
        bleAdapter?.Connect_Peripheral(peripheral_uuid: device_id)
    }
    
    /**
     Cancel  an  active connection to a peripheral

     - returns: None
    */
    public func bleDisconnect(){
        print(#function)
        
        bleAdapter?.disconnectPeripheral()
    }
    
    public func PICkit_WriteCommand(commandID: PICkit_OpCode, commandData: Data, completion: @escaping (PICkitError?)-> Void){
        self.TaskUARTCallback = completion
        
        //var AckTime = 2.0
        
        if(commandID == .BLE_PTG_INIT || commandID == .BLE_PTG_UNINIT){
            PTGError = false
        }
        
        if(PTGError){
            let error = self.commandStr[Int(self.PICkitCommand.rawValue)] + "/PTG Error"
            self.PICkit_WriteCommandResponse(result: false, resultData: error)
            return
        }
        
        /*
        if(timer == nil){
            if(commandID == .BLE_PTG_LOAD_IMAGE || commandID == .BLE_PTG_REINIT){
                AckTime = 5.0
            }

            if(commandID != .BLE_PTG_GO){
                timer = Timer.scheduledTimer(timeInterval: AckTime, target: self, selector: #selector(bleUART.TimerSelector), userInfo: nil, repeats: false)
            }
        }*/
        
        print("PICkit_WriteCommand. comdID = \(commandID),data = \(String(decoding: commandData, as: UTF8.self))")
        
        var dat: [UInt8] = []
        //Command ID
        dat.append(commandID.rawValue)
        if(commandData.count == 0){
            //Length
            dat.append(0x00)
            dat.append(0x00)
        }
        else{
            var tmp: UInt8 = 0
            let len = commandData.count
            tmp = UInt8(len & 0x00ff)
            dat.append(tmp)
            tmp = UInt8((len&0x0000ff00) >> 8)
            dat.append(tmp)
                
            let bytes = [UInt8](commandData)
            for i in 0..<commandData.count{
                //dat[i+3] = bytes[i]
                dat.append(bytes[i])
            }
        }

        GetResponseData = false
        SD_card_files.removeAll()
        ResponseData.removeAll()
        DataLog.removeAll()
        
        print("BLE raw dat = \(dat)")
        
        PICkitCommand = commandID
        
        if PICkitCommand == .BLE_PTG_LOAD_IMAGE{
            let ptg = String(data: commandData, encoding: .utf8)
            if(ptg != nil){
                self.PTGImage = ptg!
            }
        }
        
        self.bleAdapter?.sendPICkitCommand(data: Data(dat))
    }
    
    func PICkit_WriteCommandResponse(result: Bool, resultData: String = ""){
        //print("\(TaskUARTCallback)")
        if self.TaskUARTCallback != nil{
            print("PTG command complete!")
            if(result){
                self.TaskUARTCallback?(nil)
            }
            else{
                self.TaskUARTCallback?(resultData)
            }
        }
    }
    
    public func GetDeviceName() -> String{
        return (self.bleAdapter?.PeripheralName() ?? "No name")
    }
    
    public func SetATTConfig(config: CBCharacteristicWriteType){
        bleAdapter?.SetWriteType(new_value: config.rawValue)
    }
    
    public func DIS_Info() -> (String, String, String, String, String, String){
        return ((bleAdapter?.DIS_Manufacture)!, (bleAdapter?.DIS_Model)!, (bleAdapter?.DIS_SerialNumber)!, (bleAdapter?.DIS_HardwareVersion)!, (bleAdapter?.DIS_FirmwareVersion)!, (bleAdapter?.DIS_SoftwareVersion)!)
    }
    
    func getCurrentTime() -> String {
        let now = Date()
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        let timeString = outputFormatter.string(from: now)
        return timeString
    }
    
    func BLE_Scan_Connect_Handler(){

        bleAdapter?.Connection_Complete = { [weak self] () in
            guard let self = self else { return}
            print("Establish BLE connection complete!.\(CFGetRetainCount(self))")
            self.callback?.bleDidConnect?(peripheralName: self.bleAdapter?.PeripheralName() ?? "")
        }
        
        bleAdapter?.BLE_didDiscoverUpdateState = { [weak self] (BleScanning) in
            guard let self = self else { return}
            
            self.callback?.bleConnecting?(bleScan:BleScanning, discoveredPeripherals: self.bleAdapter!.Peripheral_List)
            
            if(self.bleAdapter?.Peripheral_List.count != 0){
                print("MCHP peripherals found!\(self.bleAdapter?.Peripheral_List.count ?? 0).\(CFGetRetainCount(self))")
            }
        }
    }

    func OnConnected(_ connectionStatus: Bool, message: String) {
        PTGError = false
        if(connectionStatus) {
            print("[connectionStatus] Connected")
        }
        else {
            print("[connectionStatus] Disconnect. msg = \(message)")
            callback?.bleDidDisconnect?(error: message)
        }
    }
    
    func GATT_Write_Callback() {
        bleAdapter?.BLE_WriteResponseCallback = { [weak self](success) in
            guard let self = self else { return}
            if(success){
                print("Write command success. \(self.PICkitCommand)")
            }
            else{
                self.CancelTimer()
                let error = self.commandStr[Int(self.PICkitCommand.rawValue)] + "/Error: Write command fail"
                self.PICkit_WriteCommandResponse(result: false, resultData: error)
                print("Write command fail. PICkit command ID = \(self.PICkitCommand)")
                
                if self.PICkitCommand == .BLE_PTG_LOAD_IMAGE{
                    self.PTGImage = ""
                }
            }
        }
    }
    
    func GATT_Receive_Callback() {
        bleAdapter?.BLE_DataReceiveCallback = { [weak self] (data) in
            guard let self = self else { return}
            
            print("Process PICkit response data. \(data as NSData)")
            
            if(self.PICkitCommand == .BLE_PTG_STATUS || self.PICkitCommand == .BLE_PTG_ACTIVE_IMAGE || self.PICkitCommand == .BLE_PTG_GET_IMAGE_STATS){
                self.PTG_STATUS_IMAGE_Command(data: data)
                return
            }
            
            if((self.PICkitCommand != .BLE_PTG_BROWSE_SD_CARD) && (self.PICkitCommand != .BLE_PTG_GO)){
                if let PICkitResp = PICkit_Command_Response.parsing(dat: data){
                    if PICkitResp.opcode != self.PICkitCommand.rawValue{
                        print("Invalid state")
                        
                        self.PTGCommandErrorHandler(title: self.commandStr[Int(self.PICkitCommand.rawValue)], message: "Invalid state, resp data = " + data.hexEncodedString())
                    }
                    else{//Success
                        if (PICkitResp.status == PICkit_Response.BLE_PTG_RESP_OK.rawValue){//0x80
                            print("Process command success. cmd = \(self.PICkitCommand)")
                            self.CancelTimer()
                            self.PICkit_WriteCommandResponse(result: true)
                        }
                        else{
                            self.PTGCommandErrorHandler(title: self.commandStr[Int(self.PICkitCommand.rawValue)], message: String(format: "Error: Response data = %x", PICkitResp.status))
                            
                            print("[Error]PICkit response data, status = \(PICkitResp.status)")
                            print("PICkit command ID = \(self.PICkitCommand)")
                        }
                    }
                }
                else{
                    print("Can't parse responsed data. \(data as NSData)")
                    self.PTGCommandErrorHandler(title: "Can't parse responsed data", message: data.hexEncodedString())
                }
            }
            else{
                if(self.PICkitCommand == .BLE_PTG_BROWSE_SD_CARD){
                    print("[Browse SD]Get data.\(self.GetResponseData).\(data.count)")
                    //print(data.hexEncodedString())    //For debug
                    var DataComplete: Bool?
                    
                    if(!self.GetResponseData){
                        self.GetResponseData = true
                        self.CancelTimer()
                        self.ResponseDataHeader = PICkit_ResponseData_Parser.HeaderParsing(dat: data.subdata(in: 0..<4))
                        if(self.ResponseDataHeader != nil){
                            DataComplete = PICkit_ResponseData_Parser.DataComplete(dat: data)
                            if(DataComplete == nil){
                                self.ResponseData.append(data.subdata(in: 4..<data.count))
                            }
                            else{
                                self.ResponseData.append(data.subdata(in: 4..<data.count-2))
                            }
                        }
                    }
                    else{
                        DataComplete = PICkit_ResponseData_Parser.DataComplete(dat: data)
                        
                        if(DataComplete == nil){
                            self.ResponseData.append(data)
                            if(self.ResponseData.count == (self.ResponseDataHeader!.dataLength+2)){
                                DataComplete = PICkit_ResponseData_Parser.DataComplete(dat:self.ResponseData)
                            }
                        }
                        else{
                            self.ResponseData.append(data.subdata(in: 0..<data.count-2))
                        }
                    }
                    
                    if(DataComplete != nil){
                        
                        print("\(self.ResponseData.count),\(self.ResponseDataHeader?.dataLength)")
                        print(self.ResponseData.hexEncodedString())
                        
                        var sdFiles: [String] = []
                        
                        if(self.ResponseData.count == (self.ResponseDataHeader!.dataLength)){
                            sdFiles = self.SD_card_split_files(sd_data: self.ResponseData)
                        }
                        else{
                            sdFiles = self.SD_card_split_files(sd_data: self.ResponseData.subdata(in: 0..<self.ResponseData.count-2))
                        }
                        
                        if sdFiles.isEmpty{
                            self.callback?.bleCommandResponse?(command: self.PICkitCommand.rawValue, data: Data())
                        }else{
                            print(sdFiles)
                            self.callback?.bleCommandResponseData?(command: self.PICkitCommand.rawValue, data: sdFiles)
                        }
                    }
                }
                else if(self.PICkitCommand == .BLE_PTG_GO){
                    //print("[PTG GO]Get data.\(self.GetResponseData)")
                    print("[PTG GO]Get data. len = \(data.count)")
                    print(data.hexEncodedString())    //For debug
                    
                    if(self.DataLog.isEmpty){
                        self.CancelTimer()
                    }
                    self.DataLog.append(data)
                    
                    if(self.DataLog.count > 4){
                        let opCode = self.DataLog[0]
                        if(opCode != self.PICkitCommand.rawValue){
                            //print("opCode error")
                            self.PTGCommandErrorHandler(title: self.commandStr[Int(self.PICkitCommand.rawValue)], message: "Invalid state, resp data = " + data.hexEncodedString())
                            return
                        }
                        let respData = self.DataLog[1]
                        if(respData == PICkit_Response.BLE_PTG_RESP_DATA.rawValue){
                            if(self.DataLog.count > 4){
                                let dataLen = Int(self.DataLog[2]) + Int(self.DataLog[3] << 8)
                                print("BLE_PTG_GO, data response, dataLen = \(dataLen)")
                                
                                if(self.DataLog.count >= (dataLen+4)){
                                    let dataLog = self.DataLog[4..<(dataLen+4)]
                                    let len = self.DataLog.count
                                    let result = self.DataLog[dataLen+4..<len]
                                    
                                    self.callback?.bleCommandResponse?(command: self.PICkitCommand.rawValue, data: dataLog)
                                    
                                    //print("result = \(result as NSData)")
                                    if(result.count == 2){
                                        if (result == Data([0x06,0x80])){
                                            print("pass packet")
                                            self.PICkit_WriteCommandResponse(result: true)
                                        }
                                        else if (result == Data([0x06,0x99])){
                                            //print("fail packet")
                                            self.PICkit_WriteCommandResponse(result: false)
                                        }
                                    }
                                }
                                else{
                                    print("Data not complete_1!")
                                }
                            }
                            else{
                                print("Data not complete_2!")
                            }
                        }
                        else{
                            if(respData == PICkit_Response.BLE_PTG_RESP_OK.rawValue){
                                print("Response OK!")
                            }
                            else{
                                print("Response error")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func CancelTimer(){
        if(timer != nil){
            print(#function)
            timer?.invalidate()
            timer = nil
        }
    }
    
    @objc func TimerSelector() {
        if(timer != nil){
            timer?.invalidate()
            timer = nil
            
            if self.TaskUARTCallback != nil{
                print("Timeout error")
                self.PTGCommandErrorHandler(title: commandStr[Int(self.PICkitCommand.rawValue)], message: "Device no response")
            }
        }
    }
    
    func PTGCommandErrorHandler(title: String, message: String){
        PICkit_WriteCommandResponse(result: false)
        
        if(PICkitCommand == .BLE_PTG_BROWSE_SD_CARD || PICkitCommand == .BLE_PTG_GO){
            PTGError = true
        }
        
        callback?.bleProtocolError?(title: title, message: message)
    }
    
    func SD_card_split_files(sd_data: Data) -> [String]{
        if(sd_data.count == 1 && sd_data[0] == 0x00){
            //Empty data
            print("[Browse folder] data is empty")
            return []
        }
        
        print(#function)
        
        var files: [String] = []
        let sdFiles = sd_data.split(separator: 0x0a)
        for file in sdFiles{
            print("dat = \(file as NSData)")
            let bytes = [UInt8](file)
            if(bytes.count >= 2){
                if(bytes[0] != PICkit_OpCode.BLE_PTG_BROWSE_SD_CARD.rawValue && bytes[1] != PICkit_Response.BLE_PTG_RESP_DATA.rawValue){
                    let file_str = String(decoding: file, as: UTF8.self)
                    print("file_str = \(file_str)")
                    if(file_str != "System Volume Information"){
                        files.append(String(decoding: file, as: UTF8.self))
                    }
                }
                else{
                    //Multiple packet
                    var newBytes = [UInt8]()
                    for i in 4..<bytes.count{
                        newBytes.append(bytes[i])
                        //print("appendIndex = \(i), data = \(bytes[i])")
                    }
                    let newData = Data(bytes: newBytes, count: newBytes.count)
                    print("_file_str = \(newData as NSData),\(String(decoding: newData, as: UTF8.self))")
                    files.append(String(decoding: newData, as: UTF8.self))
                }
            }
        }
        
        return files
    }
    
    func PTG_STATUS_IMAGE_Command(data: Data){
        if let PICkitResp = PICkit_Command_Response.parsing(dat: data){
            if ResponseData.isEmpty{
                self.CancelTimer()
            }
            
            if PICkitResp.opcode != self.PICkitCommand.rawValue{
                print("Invalid state.opcode = \(self.PICkitCommand)")
                PTGCommandErrorHandler(title: self.commandStr[Int(self.PICkitCommand.rawValue)], message: "Invalid state, resp data = " + data.hexEncodedString())
                return
            }
            
            if(PICkitResp.status == PICkit_Response.BLE_PTG_RESP_DATA.rawValue){
                self.ResponseData.append(Data(PICkitResp.parameters))
                print("Append response data")
            }
            else if(PICkitResp.status == PICkit_Response.BLE_PTG_RESP_OK.rawValue){
                self.ResponseData.append(data)
                print("Append response OK")
            }
            else{
                print("[Error]PICkit response data, status = \(PICkitResp.status)")
                print("PICkit command ID = \(self.PICkitCommand)")
                
                PTGCommandErrorHandler(title: self.commandStr[Int(self.PICkitCommand.rawValue)], message: String(format: "Error: Command reponse = 0x%x", PICkitResp.status))
                
                return
            }
            
            if(!self.ResponseData.isEmpty){
                let RespOk = (self.ResponseData as NSData).subdata(with: NSMakeRange(self.ResponseData.count-2, 2))
                print("Response ok? = \(RespOk as NSData)")
                
                if(RespOk == Data([PICkitCommand.rawValue, PICkit_Response.BLE_PTG_RESP_OK.rawValue])){
                    print("Command complete.\(PICkitCommand)")
                    
                    let data = (self.ResponseData as NSData).subdata(with:NSMakeRange(0, self.ResponseData.count-2))
                    
                    if PICkitCommand == .BLE_PTG_STATUS{
                        print("PK5 Status. data = \(data as NSData)")
                        
                        PICkit_WriteCommandResponse(result: true)
                        
                        self.callback?.bleCommandResponseData?(command: self.PICkitCommand.rawValue, data: data)
                    }
                    else if PICkitCommand == .BLE_PTG_ACTIVE_IMAGE{
                        PICkit_WriteCommandResponse(result: true)
                        
                        self.callback?.bleCommandResponseData?(command: self.PICkitCommand.rawValue, data: String(decoding: data, as: UTF8.self))
                    }
                    else{
                        print("PK5 IMAGE STATS = \(data as NSData)")
                        
                        PICkit_WriteCommandResponse(result: true)
                        
                        if data.count == 8{
                            self.callback?.bleCommandResponseData?(command: self.PICkitCommand.rawValue, data: data)
                        }
                    }
                }
            }
        }
        else{
            print("Can't parse responsed data. \(data as NSData)")
            PTGCommandErrorHandler(title: "Can't parse responsed data", message: data.hexEncodedString())
        }
    }
    
    // MARK: - BLEAdapterDelegate
    func BLEDataIn(_ dataIn: Data) {}
    
    func UpdateMTU(_ mtu: Int) {}
    
    func ISSC_Peripheral_Device(_ device_found: Bool) {}
}

extension Data {
    func split(separator: Data) -> [Data] {
        var chunks: [Data] = []
        var pos = startIndex
        // Find next occurrence of separator after current position:
        while let r = self[pos...].range(of: separator) {
            // Append if non-empty:
            if r.lowerBound > pos {
                chunks.append(self[pos..<r.lowerBound])
            }
            // Update current position:
            pos = r.upperBound
        }
        // Append final chunk, if non-empty:
        if pos < endIndex {
            chunks.append(self[pos..<endIndex])
        }
        return chunks
    }
    
    func hexEncodedString() -> String {
        return map { String(format: "%02hhX ", $0) }.joined()
    }
}

