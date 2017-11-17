//
//  ViewController.swift
//  AccelGyro
//
//  Created by Jay Tucker on 11/2/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import UIKit
import CoreMotion

enum EventType: String { case accel, gyro, pedom, pedom_event, user  }

class ViewController: UIViewController {
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    let motionManager = CMMotionManager()
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
                Logger.sharedInstance.log(.accel, "error")
                return
            }
            guard let data = data else {
                Logger.sharedInstance.log(.accel, "data is nil")
                return
            }
            let format = "%.4f"
            let x = String(format: format, data.acceleration.x)
            let y = String(format: format, data.acceleration.y)
            let z = String(format: format, data.acceleration.z)
            Logger.sharedInstance.log(.accel, "\(x),\(y),\(z)")
        }
    }
    
    private func startGyroUpdates() {
        motionManager.startGyroUpdates(to: OperationQueue.current!) { data, error in
            guard error == nil else {
                Logger.sharedInstance.log(.gyro, "error")
                return
            }
            guard let data = data else {
                Logger.sharedInstance.log(.gyro, "data is nil")
                return
            }
            let format = "%.4f"
            let x = String(format: format, data.rotationRate.x)
            let y = String(format: format, data.rotationRate.y)
            let z = String(format: format, data.rotationRate.z)
            Logger.sharedInstance.log(.gyro, "\(x),\(y),\(z)")
        }
    }
    
    private func startPedometerUpdates() {
        guard CMPedometer.isPedometerEventTrackingAvailable() && CMPedometer.isDistanceAvailable() else { return }
        
        pedometer.startEventUpdates { event, error in
            guard error == nil else {
                Logger.sharedInstance.log(.pedom, "event error")
                return
            }
            guard let event = event else {
                Logger.sharedInstance.log(.pedom, "event is nil")
                return
            }
            let typeString: String
            switch event.type {
            case .pause: typeString = "pause"
            case .resume: typeString = "resume"
            }
            Logger.sharedInstance.log(.pedom_event, typeString)
        }
        
        pedometer.startUpdates(from: Date()) { data, error in
            guard error == nil else {
                Logger.sharedInstance.log(.pedom, "error")
                return
            }
            guard let data = data else {
                Logger.sharedInstance.log(.pedom, "data is nil")
                return
            }
            Logger.sharedInstance.log(.pedom, "\(data.numberOfSteps),\(String(format: "%.4f",data.distance!.doubleValue))")
        }
    }
    
    private func stopUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        pedometer.stopUpdates()
        pedometer.stopEventUpdates()
    }
    
    @IBAction func onBackPocket(_ sender: Any) {
        Logger.sharedInstance.log(.user, "*** putting in back pocket ***")
    }
    
    @IBAction func onTurnAway(_ sender: Any) {
        Logger.sharedInstance.log(.user, "*** turning away ***")
    }
    
    @IBAction func onWalkAway(_ sender: Any) {
        Logger.sharedInstance.log(.user, "*** walking away ***")
    }
    
    // MARK: log file interaction
    
    @IBAction func startLog(_ sender: Any) {
        let headers: [EventType:String] = [
            .accel : "time,x,y,z",
            .gyro : "time,x,y,z",
            .pedom : "time,steps,distance",
            .pedom_event : "time,type",
        ]
        
        Logger.sharedInstance.start(headers: headers)
        
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

