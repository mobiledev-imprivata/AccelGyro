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
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
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
        
        stopButton.isEnabled = false
        uploadButton.isEnabled = false
        deleteButton.isEnabled = false
        
        motionManager.accelerometerUpdateInterval = 1.0
        motionManager.gyroUpdateInterval = 1.0
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
                Logger.sharedInstance.log("accel error")
                return
            }
            guard let data = data else {
                Logger.sharedInstance.log("accel data is nil")
                return
            }
            Logger.sharedInstance.log("accel: \(data)")
            if fabs(data.acceleration.x) > fabs(self.accelMaxX) {
                self.accelMaxX = data.acceleration.x
            }
            if fabs(data.acceleration.y) > fabs(self.accelMaxY) {
                self.accelMaxY = data.acceleration.y
            }
            if fabs(data.acceleration.z) > fabs(self.accelMaxZ) {
                self.accelMaxZ = data.acceleration.z
            }
            Logger.sharedInstance.log("accelMaxX \(self.accelMaxX), accelMaxY \(self.accelMaxY), accelMaxZ \(self.accelMaxZ)")
        }
    }
    
    private func startGyroUpdates() {
        motionManager.startGyroUpdates(to: OperationQueue.current!) {
            [unowned self] data, error in
            guard error == nil else {
                Logger.sharedInstance.log("gyro error")
                return
            }
            guard let data = data else {
                Logger.sharedInstance.log("gyro data is nil")
                return
            }
            Logger.sharedInstance.log("gyro:  \(data)")
            if fabs(data.rotationRate.x) > fabs(self.gyroMaxX) {
                self.gyroMaxX = data.rotationRate.x
            }
            if fabs(data.rotationRate.y) > fabs(self.gyroMaxY) {
                self.gyroMaxY = data.rotationRate.y
            }
            if fabs(data.rotationRate.z) > fabs(self.gyroMaxZ) {
                self.gyroMaxZ = data.rotationRate.z
            }
            Logger.sharedInstance.log("gyroMaxX \(self.gyroMaxX), gyroMaxY \(self.gyroMaxY), gyroMaxZ \(self.gyroMaxZ)")
        }
    }
    
    private func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }
    
    @IBAction func onBackPocket(_ sender: Any) {
        Logger.sharedInstance.log("*** putting in back pocket ***")
    }
    
    @IBAction func onTurnAway(_ sender: Any) {
        Logger.sharedInstance.log("*** turning away ***")
    }
    
    @IBAction func onWalkAway(_ sender: Any) {
        Logger.sharedInstance.log("*** walking away ***")
    }
    
    // MARK: log file interaction
    
    @IBAction func startLog(_ sender: Any) {
        Logger.sharedInstance.start()
        
        startButton.isEnabled = false
        stopButton.isEnabled = true
        uploadButton.isEnabled = true
        deleteButton.isEnabled = true
    }
    
    @IBAction func stopLog(_ sender: Any) {
        Logger.sharedInstance.stop()
        
        startButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    @IBAction func uploadLog(_ sender: Any) {
        Logger.sharedInstance.upload()
        
        startButton.isEnabled = true
        stopButton.isEnabled = false
        uploadButton.isEnabled = false
        deleteButton.isEnabled = false
    }
    
    @IBAction func deleteLog(_ sender: Any) {
        Logger.sharedInstance.delete()
        
        startButton.isEnabled = true
        stopButton.isEnabled = false
        uploadButton.isEnabled = false
        deleteButton.isEnabled = false
    }
    
}

