//
//  ViewController.swift
//  AccelGyro
//
//  Created by Jay Tucker on 11/2/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    var motionManager = CMMotionManager()
    
    var accelMaxX = 0.0
    var accelMaxY = 0.0
    var accelMaxZ = 0.0

    var gyroMaxX = 0.0
    var gyroMaxY = 0.0
    var gyroMaxZ = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        motionManager.accelerometerUpdateInterval = 0.25
        motionManager.gyroUpdateInterval = 0.25
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        startAccelerometerUpdates()
        startGyroUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopUpdates()
    }
    
    private func startAccelerometerUpdates() {
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) {
            [unowned self] data, error in
            guard error == nil else {
                print("accel error")
                return
            }
            guard let data = data else {
                print("accel data is nil")
                return
            }
            print("accel: \(data)")
            if fabs(data.acceleration.x) > fabs(self.accelMaxX) {
                self.accelMaxX = data.acceleration.x
            }
            if fabs(data.acceleration.y) > fabs(self.accelMaxY) {
                self.accelMaxY = data.acceleration.y
            }
            if fabs(data.acceleration.z) > fabs(self.accelMaxZ) {
                self.accelMaxZ = data.acceleration.z
            }
            print("accelMaxX \(self.accelMaxX), accelMaxY \(self.accelMaxY), accelMaxZ \(self.accelMaxZ)")
        }
    }
    
    private func startGyroUpdates() {
        motionManager.startGyroUpdates(to: OperationQueue.current!) {
            [unowned self] data, error in
            guard error == nil else {
                print("gyro error")
                return
            }
            guard let data = data else {
                print("gyro data is nil")
                return
            }
            print("gyro:  \(data)")
            if fabs(data.rotationRate.x) > fabs(self.gyroMaxX) {
                self.gyroMaxX = data.rotationRate.x
            }
            if fabs(data.rotationRate.y) > fabs(self.gyroMaxY) {
                self.gyroMaxY = data.rotationRate.y
            }
            if fabs(data.rotationRate.z) > fabs(self.gyroMaxZ) {
                self.gyroMaxZ = data.rotationRate.z
            }
            print("gyroMaxX \(self.gyroMaxX), gyroMaxY \(self.gyroMaxY), gyroMaxZ \(self.gyroMaxZ)")
        }
    }
    
    private func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }

}

