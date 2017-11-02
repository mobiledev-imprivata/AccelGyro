//
//  Logger.swift
//  AccelGyro
//
//  Created by Jay Tucker on 11/2/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import Foundation

public final class Logger {
    private var logFilePath: String?
    private var outputStream: OutputStream?
    private let filename = "/Imprivata.txt"
    
    private var messageBuffer = [String]()
    private let messageBufferMaxSize = 10
    
    // singleton
    static let sharedInstance = Logger()
    
    private let loggerQueue = DispatchQueue(label: "loggerQueue", attributes: [])
    
    private let dateFormatter = DateFormatter()
    private let timeFormatter = DateFormatter()
    
    private init() {
        let pathArray = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if !pathArray.isEmpty {
            let path = pathArray[0]
            logFilePath = path + filename
            logFilePath = logFilePath?.replacingOccurrences(of: " ", with: "-", options: [], range: nil)
            outputStream = OutputStream(toFileAtPath: logFilePath!, append: true)
            outputStream!.open()
            print("logFilePath \(logFilePath!)")
        }
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        timeFormatter.dateFormat = "HH:mm:ss.SSS"
    }
    
    deinit {
        outputStream?.close()
    }
    
    public func log(_ message: String) {
        loggerQueue.async { [unowned self] in
            self.logHelper(message)
        }
    }
    
    private func logHelper(_ message: String) {
        let dateString = dateFormatter.string(from: Date())
        print(dateString, message)
    }
    
}
