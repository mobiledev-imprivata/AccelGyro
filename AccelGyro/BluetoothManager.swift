//
//  BluetoothManager.swift
//  AccelGyro
//
//  Created by Jay Tucker on 11/29/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothManagerDelegate {
    func readMotionData(interval: TimeInterval, completion: @escaping (String) -> Void)
}

final class BluetoothManager: NSObject {
    
    private let serviceUUID                     = CBUUID(string: "16884184-C1C4-4BD1-A8F1-6ADCB272B18B")
    private let setIntervalCharacteristicUUID   = CBUUID(string: "81426A40-F761-4F45-A58B-D27A780AAEF9")
    private let getMotionDataCharacteristicUUID = CBUUID(string: "0246FAC2-1145-409B-88C4-F43D4E05A8C5")

    private var peripheralManager: CBPeripheralManager!
    
    var delegate:BluetoothManagerDelegate?
    
    var interval: TimeInterval = 10.0

    private var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS"
        return df
    }()
    
    private func btmgrlog(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] BTMgr \(message)")
    }
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    private func addService() {
        btmgrlog("addService")
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        let service = CBMutableService(type: serviceUUID, primary: true)
        let setIntervalCharacteristic = CBMutableCharacteristic(type: setIntervalCharacteristicUUID, properties: .write, value: nil, permissions: .writeable)
        let getMotionDataCharacteristic = CBMutableCharacteristic(type: getMotionDataCharacteristicUUID, properties: .read, value: nil, permissions: .readable)
        service.characteristics = [setIntervalCharacteristic, getMotionDataCharacteristic]
        peripheralManager.add(service)
    }
    
    private func startAdvertising() {
        btmgrlog("startAdvertising")
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
    }
    
}

extension BluetoothManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        var caseString: String!
        switch peripheral.state {
        case .unknown:
            caseString = "unknown"
        case .resetting:
            caseString = "resetting"
        case .unsupported:
            caseString = "unsupported"
        case .unauthorized:
            caseString = "unauthorized"
        case .poweredOff:
            caseString = "poweredOff"
        case .poweredOn:
            caseString = "poweredOn"
        }
        btmgrlog("peripheralManagerDidUpdateState \(caseString!)")
        if peripheral.state == .poweredOn {
            addService()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        let message = "peripheralManager didAddService " + (error == nil ? "ok" :  ("error " + error!.localizedDescription))
        btmgrlog(message)
        if error == nil {
            startAdvertising()
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        let message = "peripheralManagerDidStartAdvertising " + (error == nil ? "ok" :  ("error " + error!.localizedDescription))
        btmgrlog(message)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        btmgrlog("didReceiveWriteRequests \(requests.count)")
        for request in requests {
            // let characteristic = request.characteristic
            guard let value = request.value else {
                btmgrlog("request.value is nil")
                return
            }
            btmgrlog("received \(value.count) bytes:\(value.reduce("") { $0 + String(format: " %02x", $1) })")
            guard let intervalString = String(data: value, encoding: .utf8), let interval = TimeInterval(intervalString) else {
                btmgrlog("couldn't parse interval")
                return
            }
            btmgrlog("setting interval to \(interval)")
            self.interval = interval
            peripheralManager.respond(to: request, withResult: .success)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        btmgrlog("peripheralManager didReceiveRead request \(request.characteristic.uuid.uuidString)")
        delegate?.readMotionData(interval: interval) { dataString in
            self.btmgrlog("data: \(dataString)")
            request.value = dataString.data(using: .utf8, allowLossyConversion: false)
            self.peripheralManager.respond(to: request, withResult: .success)
        }
    }
    
}
