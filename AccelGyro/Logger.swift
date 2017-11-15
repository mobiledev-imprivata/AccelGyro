//
//  Logger.swift
//  AccelGyro
//
//  Created by Jay Tucker on 11/2/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import Foundation

public final class Logger {
    private var isLogging = false
    
    private var logFilePath: String?
    private var outputStream: OutputStream?
    
    private var messageBuffer = [String]()
    private let messageBufferMaxSize = 10

    private let loggerQueue = DispatchQueue(label: "com.imprivata.log", attributes: [])
    private let uploadQueue = DispatchQueue(label: "com.imprivata.upload", attributes: [])

    private let dateFormatter = DateFormatter()

    // singleton
    static let sharedInstance = Logger()
    
    private init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    deinit {
        closeFile()
        deleteFile()
    }
    
    func log(_ message: String) {
        loggerQueue.async { [unowned self] in
            let dateString = self.dateFormatter.string(from: Date())
            let logString = "\(dateString) \(message)"
            print(logString)
            
            guard self.isLogging else { return }
            
            self.messageBuffer.append(logString)
            // print("messageBuffer \(self.messageBuffer.count)")
            if self.messageBuffer.count >= self.messageBufferMaxSize {
                self.writeBufferToFile()
            }
        }
    }
    
    func start() {
        print(#function)
        loggerQueue.async { [unowned self] in
            self.isLogging = true
            if self.logFilePath == nil {
                self.openFile()
            }
        }
    }
    
    func stop() {
        print(#function)
        loggerQueue.async { [unowned self] in
            self.isLogging = false
        }
    }
    
    func upload() {
        print(#function)
        loggerQueue.async { [unowned self] in
            guard self.logFilePath != nil else { return }
            
            // flush any remaining messages in the message buffer,
            // then close the file
            self.isLogging = false
            self.writeBufferToFile()
            self.closeFile()
            self.uploadFileToServer()
            self.deleteFile()
        }
    }

    func delete() {
        print(#function)
        loggerQueue.async { [unowned self] in
            self.deleteFile()
            self.messageBuffer.removeAll()
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
            print("opening logFilePath \(logFilePath!)")
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
        self.logFilePath = nil
    }
    
    private func writeBufferToFile() {
        print(#function)
        if let outputStream = outputStream {
            let s = messageBuffer.reduce("") { $0 + $1 + "\\n" }
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

        var contentString: String
        do {
            contentString = try String(contentsOfFile: logFilePath, encoding: .utf8)
        } catch  let error as NSError {
            print("Failed reading from \(logFilePath), Error: \(error.localizedDescription)")
            return
        }
        
        guard !contentString.isEmpty else {
            print("File \(logFilePath) is empty")
            return
        }
        
        print("content character count: \(contentString.count)")
        
        let jsonString = "{ \"text\": \"\(contentString)\" }"

        guard let jsonData = jsonString.data(using: .utf8) else {
            print("error converting JSON string to data")
            return
        }
        
        print("JSON data count: \(jsonData.count)")
        
        uploadQueue.async {
            print("uploading...")
            let urlString = "http://10.112.11.114:5000/upload"
            let url = URL(string: urlString)!
            let request = NSMutableURLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                guard error == nil else {
                    print("error: \(error!.localizedDescription)")
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {
                    print("got bad response")
                    return
                }
                
                print("response status code \(response.statusCode)")
            }
            task.resume()
        }
    }
    
}
