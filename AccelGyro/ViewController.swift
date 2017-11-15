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
    let pedometer = CMPedometer()
    
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
        startPedometerUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopUpdates()
    }
    
    private func startAccelerometerUpdates() {
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, error in
            guard error == nil else {
                Logger.sharedInstance.log("accel error")
                return
            }
            guard let data = data else {
                Logger.sharedInstance.log("accel data is nil")
                return
            }
            Logger.sharedInstance.log("accel: \(data.acceleration.x) \(data.acceleration.y) \(data.acceleration.z)")
        }
    }
    
    private func startGyroUpdates() {
        motionManager.startGyroUpdates(to: OperationQueue.current!) { data, error in
            guard error == nil else {
                Logger.sharedInstance.log("gyro error")
                return
            }
            guard let data = data else {
                Logger.sharedInstance.log("gyro data is nil")
                return
            }
            Logger.sharedInstance.log("gyro: \(data.rotationRate.x) \(data.rotationRate.y) \(data.rotationRate.z)")
        }
    }
    
    private func startPedometerUpdates() {
        guard CMPedometer.isPedometerEventTrackingAvailable() && CMPedometer.isDistanceAvailable() else { return }
        
        pedometer.startEventUpdates { event, error in
            guard error == nil else {
                Logger.sharedInstance.log("pedometer event error")
                return
            }
            guard let event = event else {
                Logger.sharedInstance.log("pedometer event is nil")
                return
            }
            var typeString: String
            switch event.type {
            case .pause: typeString = "pause"
            case .resume: typeString = "resume"
            }
            Logger.sharedInstance.log("pedom_event: \(typeString)")
        }
        
        pedometer.startUpdates(from: Date()) { data, error in
            guard error == nil else {
                Logger.sharedInstance.log("pedometer error")
                return
            }
            guard let data = data else {
                Logger.sharedInstance.log("pedometer data is nil")
                return
            }
            Logger.sharedInstance.log("pedom: \(data.numberOfSteps) \(data.distance!)")
        }
    }
    
    private func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        pedometer.stopUpdates()
        pedometer.stopEventUpdates()
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

