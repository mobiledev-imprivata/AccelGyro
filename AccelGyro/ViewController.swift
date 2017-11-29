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
    
    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    
    private var uiBackgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    private var bluetoothManager: BluetoothManager!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        print(#function)

        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        stopButton.isEnabled = false
        uploadButton.isEnabled = false
        deleteButton.isEnabled = false
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.gyroUpdateInterval = 0.1
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)
        
        bluetoothManager = BluetoothManager()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func didBecomeActive() {
        print(#function)
    }
    
    @objc func willResignActive() {
        print(#function)
    }
    
    private func startUpdates() {
        print(#function)
        
        // startAccelerometerUpdates()
        // startGyroUpdates()
        startPedometerUpdates()
        startPedometerEventUpdates()
    }
    
    private func stopUpdates() {
        print(#function)

        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        pedometer.stopUpdates()
        pedometer.stopEventUpdates()
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
        guard CMPedometer.isDistanceAvailable() else { return }
        
        pedometer.startUpdates(from: Date()) { [unowned self] data, error in
            guard error == nil else {
                Logger.sharedInstance.log(.pedom, "error")
                return
            }
            guard let data = data else {
                Logger.sharedInstance.log(.pedom, "data is nil")
                return
            }
            Logger.sharedInstance.log(.pedom, "\(data.numberOfSteps),\(String(format: "%.4f",data.distance!.doubleValue))")
            self.bluetoothManager.sendMotionData("\(data.numberOfSteps)")
        }
    }
    
    private func startPedometerEventUpdates() {
        guard CMPedometer.isPedometerEventTrackingAvailable() else { return }
        
        pedometer.startEventUpdates { event, error in
            guard error == nil else {
                Logger.sharedInstance.log(.pedom_event, "event error")
                return
            }
            guard let event = event else {
                Logger.sharedInstance.log(.pedom_event, "event is nil")
                return
            }
            let typeString: String
            switch event.type {
            case .pause: typeString = "pause"
            case .resume: typeString = "resume"
            }
            Logger.sharedInstance.log(.pedom_event, typeString)
        }
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
    
    // We assume that all of these @IBAction methods will be called only when the app is in the foreground,
    // so we don't have to be overly concerned about when to call endBackgroundTask().
    
    @IBAction func startLog(_ sender: Any) {
        let headers: [EventType:String] = [
            .accel : "time,x,y,z",
            .gyro : "time,x,y,z",
            .pedom : "time,steps,distance",
            .pedom_event : "time,type",
        ]
        
        beginBackgroundTask()
        
        Logger.sharedInstance.start(headers: headers)
        
        startButton.isEnabled = false
        stopButton.isEnabled = true
        uploadButton.isEnabled = true
        deleteButton.isEnabled = true
        
        startUpdates()
    }
    
    @IBAction func stopLog(_ sender: Any) {
        stopUpdates()
        
        Logger.sharedInstance.stop()
        
        startButton.isEnabled = true
        stopButton.isEnabled = false

        endBackgroundTask()
    }
    
    @IBAction func uploadLog(_ sender: Any) {
        stopUpdates()
        
        Logger.sharedInstance.upload()
        
        startButton.isEnabled = true
        stopButton.isEnabled = false
        uploadButton.isEnabled = false
        deleteButton.isEnabled = false
        
        endBackgroundTask()
    }
    
    @IBAction func deleteLog(_ sender: Any) {
        stopUpdates()
        
        Logger.sharedInstance.delete()
        
        startButton.isEnabled = true
        stopButton.isEnabled = false
        uploadButton.isEnabled = false
        deleteButton.isEnabled = false
        
        endBackgroundTask()
    }
    
    // MARK: background task
    
    private func beginBackgroundTask() {
        print(#function)
        uiBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            [unowned self] in
            print("uiBackgroundTaskIdentifier \(self.uiBackgroundTaskIdentifier) expired")
            UIApplication.shared.endBackgroundTask(self.uiBackgroundTaskIdentifier)
            self.uiBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        })
        print("uiBackgroundTaskIdentifier \(uiBackgroundTaskIdentifier)")
    }
    
    private func endBackgroundTask() {
        print(#function)
        print("uiBackgroundTaskIdentifier \(uiBackgroundTaskIdentifier)")
        UIApplication.shared.endBackgroundTask(uiBackgroundTaskIdentifier)
        uiBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    }
    
}

