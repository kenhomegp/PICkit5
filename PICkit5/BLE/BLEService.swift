//
//  BLEService.swift
//  BleUARTLib
//
//  Created by WSG Software on 2021/7/21.
//

import Foundation
import CoreBluetooth

struct BLE_Constants {
    //Microchip Transparent Service
    static let MCHP_PROPRIETARY_SERVICE = CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455")
    static let MCHP_TRANS_RX = CBUUID(string: "49535343-1E4D-4BD9-BA61-23C647249616")
    static let MCHP_TRANS_TX = CBUUID(string: "49535343-8841-43F4-A8D4-ECBE34729BB3")
    static let MCHP_TRANS_CTRL = CBUUID(string: "49535343-4C8A-39B3-2F49-511CFF073B7E")
    static let MCHP_TRCBP_SERVICE = CBUUID(string: "49535343-2120-45FC-BDDB-E8A01AEDEC50")
    static let MCHP_TRCBP_CTRL = CBUUID(string: "49535343-0284-18AE-1E46-35E91AF7D03C")
    static let MCHP_TRCBP_CHAR = CBUUID(string: "49535343-C2DB-4991-9A9F-68C13B25DD1F")
    
    //Device Information Service
    static let MCHP_UUIDSTR_DEVICE_INFO_SERVICE = CBUUID(string: "180A")
    static let MCHP_UUIDSTR_MANUFACTURE_NAME_CHAR = CBUUID(string: "2A29")
    static let MCHP_UUIDSTR_MODEL_NUMBER_CHAR = CBUUID(string: "2A24")
    static let MCHP_UUIDSTR_SERIAL_NUMBER_CHAR = CBUUID(string: "2A25")
    static let MCHP_UUIDSTR_HARDWARE_REVISION_CHAR = CBUUID(string: "2A27")
    static let MCHP_UUIDSTR_FIRMWARE_REVISION_CHAR = CBUUID(string: "2A26")
    static let MCHP_UUIDSTR_SOFTWARE_REVISION_CHAR = CBUUID(string: "2A28")
    static let MCHP_UUIDSTR_SYSTEM_ID_CHAR = CBUUID(string: "2A23")
    static let MCHP_UUIDSTR_IEEE_11073_20601_CHAR = CBUUID(string: "2A2A")
}
