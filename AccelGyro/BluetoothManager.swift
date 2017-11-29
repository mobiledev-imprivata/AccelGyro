//
//  BluetoothManager.swift
//  AccelGyro
//
//  Created by Jay Tucker on 11/29/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BluetoothManager: NSObject {
    
    private let serviceUUID        = CBUUID(string: "16884184-C1C4-4BD1-A8F1-6ADCB272B18B")
    private let characteristicUUID = CBUUID(string: "2031019E-0380-4F27-8B12-E572858FE928")
    
    private var peripheralManager: CBPeripheralManager!
    private var characteristic: CBMutableCharacteristic!
    
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
    
    func sendMotionData(_ dataString: String) {
        btmgrlog("sendMotionData \(dataString)")
        guard let value = dataString.data(using: .utf8, allowLossyConversion: false) else { return }
        peripheralManager.updateValue(value, for: characteristic, onSubscribedCentrals: nil)
    }
    
    private func addService() {
        btmgrlog("addService")
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        let service = CBMutableService(type: serviceUUID, primary: true)
        characteristic = CBMutableCharacteristic(type: characteristicUUID, properties: .notify, value: nil, permissions: .readable)
        service.characteristics = [characteristic]
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
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        btmgrlog("peripheralManager didSubscribeTo characteristic")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        btmgrlog("peripheralManager didUnsubscribeFrom characteristic")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        btmgrlog("peripheralManager didReceiveRead request")
        let response = "Polo!"
        request.value = response.data(using: String.Encoding.utf8, allowLossyConversion: false)
        peripheralManager.respond(to: request, withResult: .success)
    }
    
}
