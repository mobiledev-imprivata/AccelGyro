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
    func readMotionData(completion: @escaping (String) -> Void)
}

final class BluetoothManager: NSObject {
    
    private let serviceUUID                  = CBUUID(string: "16884184-C1C4-4BD1-A8F1-6ADCB272B18B")
    private let readCharacteristicUUID       = CBUUID(string: "0246FAC2-1145-409B-88C4-F43D4E05A8C5")
    private let subscribedCharacteristicUUID = CBUUID(string: "2031019E-0380-4F27-8B12-E572858FE928")

    private var peripheralManager: CBPeripheralManager!
    private var subscribedCharacteristic: CBMutableCharacteristic!
    
    var delegate:BluetoothManagerDelegate?

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

    func updateMotionData(_ dataString: String) {
        btmgrlog("sendMotionData \(dataString)")
        guard let value = dataString.data(using: .utf8, allowLossyConversion: false) else { return }
        peripheralManager.updateValue(value, for: subscribedCharacteristic, onSubscribedCentrals: nil)
    }
    
    private func addService() {
        btmgrlog("addService")
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        let service = CBMutableService(type: serviceUUID, primary: true)
        let readCharacteristic = CBMutableCharacteristic(type: readCharacteristicUUID, properties: .read, value: nil, permissions: .readable)
        subscribedCharacteristic = CBMutableCharacteristic(type: subscribedCharacteristicUUID, properties: .notify, value: nil, permissions: .readable)
        service.characteristics = [readCharacteristic, subscribedCharacteristic]
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
        delegate?.readMotionData { dataString in
            self.btmgrlog("data: \(dataString)")
            request.value = dataString.data(using: .utf8, allowLossyConversion: false)
            self.peripheralManager.respond(to: request, withResult: .success)
        }
    }
    
}
