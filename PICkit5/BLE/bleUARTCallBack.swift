//
//  bleUARTCallBack.swift
//  BleUARTLib
//
//  Created by WSG Software on 2021/5/11.
//

import Foundation

@objc public protocol bleUARTCallBack{
    @objc optional func bleConnecting(bleScan:Bool, discoveredPeripherals:NSMutableArray)
    @objc optional func bleDidConnect(peripheralName:String)
    @objc optional func bleDidDisconnect(error:String)
    @objc optional func bleProtocolError(title: String, message: String)
    @objc optional func bleCommandResponse(command: UInt8, data: Data)
    //@objc optional func bleCommandResponseData(command: UInt8, data: [String])
    @objc optional func bleCommandResponseData(command: UInt8, data: Any)
}

