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
    
    private var messageBuffer = [String]()
    private let messageBufferMaxSize = 10

    private let loggerQueue = DispatchQueue(label: "loggerQueue", attributes: [])

    private let dateFormatter = DateFormatter()

    // singleton
    static let sharedInstance = Logger()
    
    private init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        openFile()
    }
    
    deinit {
        closeFile()
    }
    
    func log(_ message: String) {
        loggerQueue.async { [unowned self] in
            let dateString = self.dateFormatter.string(from: Date())
            let logString = "\(dateString) \(message)"
            print(logString)
            self.messageBuffer.append(logString)
            // print("messageBuffer \(self.messageBuffer.count)")
            if self.messageBuffer.count >= self.messageBufferMaxSize {
                self.writeBufferToFile()
            }
        }
    }
    
    func upload() {
        print(#function)
        loggerQueue.async { [unowned self] in
            // flush any remaining messages in the message buffer,
            // then close the file
            self.writeBufferToFile()
            self.closeFile()
            self.uploadFileToServer()
            self.deleteFile()
            self.openFile()
        }
    }
    
    // MARK: OutputStream/file code
    
    private func openFile() {
        print(#function)
        let pathArray = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if !pathArray.isEmpty {
            let path = pathArray[0]
            let dt = DateFormatter()
            dt.dateFormat = "yyyyMMdd'T'HH-mm-ss"
            let dateString = dt.string(from: Date())
            logFilePath = "\(path)/AccelGyro-\(dateString).log"
            print("logFilePath \(logFilePath!)")
            outputStream = OutputStream(toFileAtPath: logFilePath!, append: false)
            outputStream?.open()
        }
    }
    
    private func closeFile() {
        print(#function)
        outputStream?.close()
    }
    
    private func deleteFile() {
        guard let logFilePath = logFilePath else { return }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: logFilePath) {
            do {
                try fileManager.removeItem(atPath: logFilePath)
                print("delete \(logFilePath) ok")
            } catch let error as NSError {
                print("delete \(logFilePath) failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func writeBufferToFile() {
        print(#function)
        if let outputStream = outputStream {
            let s = messageBuffer.reduce("") { $0 + $1 + "\n" }
            let nBytesWritten = outputStream.write(s, maxLength: s.lengthOfBytes(using: String.Encoding.utf8))
            if nBytesWritten != -1 {
                messageBuffer.removeAll(keepingCapacity: true)
                // rollover()
            } else {
                print("error writing log file")
            }
        } else {
            print("cannot open log file")
        }
    }
    
    private func uploadFileToServer() {
        print(#function)
        
        guard let logFilePath = logFilePath else { return }

        var bodyString: String
        do {
            bodyString = try String(contentsOfFile: logFilePath, encoding: .utf8)
        } catch  let error as NSError {
            print("Failed reading from \(logFilePath), Error: \(error.localizedDescription)")
            return
        }
        
        guard !bodyString.isEmpty else {
            print("File \(logFilePath) is empty")
            return
        }

       // bodyString.characters
        
        
//        let bodyStr = "\r\n--\(boundary)\r\n" + head + fileStr + "\r\n--\(boundary)--\r\n"
//        let loadData = bodyStr.data(using: .utf8)
//        let loadStr = String(data: loadData! , encoding: .utf8)
//        dataToUpload.append(loadData!)
    }
    
}
