//
//  Logging.swift
//  CodeLume
//
//  Created by Lyke on 2025/3/13.
//

import SwiftyBeaver
import Foundation

final class Logger {
    static let shared = Logger()
    
    private let logger = SwiftyBeaver.self
    private let console = ConsoleDestination()
//    private let file = FileDestination()
    private var fileSizeCheckTimer: Timer?
    
    struct Config {
        static let logFileName: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            return "CodeLume_\(formatter.string(from: Date())).log"
        }()
        
        static let logDirectoryName = "Logs"
        static let consoleFormat = "[$Dyyyy-MM-dd HH:mm:ss.SSS] [$L] $N.$F.$l: $M"
        static let fileFormat = "[$Dyyyy-MM-dd HH:mm:ss.SSS] [$L] $N.$F.$l: $M"
        static let maxLogFileSize: UInt64 = 10 * 1024 * 1024
        static let maxLogFiles = 10
    }
    
    private init() {
        setupLogger()
        startFileSizeMonitor()
    }
    
    deinit {
        fileSizeCheckTimer?.invalidate()
    }
    
    func setLogLevel(_ level: SwiftyBeaver.Level) {
        console.minLevel = level
//        file.minLevel = level
    }
    
    
    
    private func setupLogger() {
        logger.addDestination(console)
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let logDirectory = documentsDirectory.appendingPathComponent(Config.logDirectoryName)
            let logFileURL = logDirectory.appendingPathComponent(Config.logFileName)
            do {
                try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
//                file.logFileURL = logFileURL
            } catch {
                print("Error handling log file: \(error)")
            }
        }
        
//        logger.addDestination(file)
        console.format = Config.consoleFormat
//        file.format = Config.fileFormat
        
//        logger.info("Logger initialized successfully. path: \(file.logFileURL?.path ?? "unknown")")
        setLogLevel(SwiftyBeaver.Level.info)
    }
    
    private func getNewFilePath() -> URL {
        let logFileName: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            return "CodeLume_\(formatter.string(from: Date())).log"
        }()
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for:.cachesDirectory, in:.userDomainMask).first!
        let logDirectory = documentsDirectory.appendingPathComponent(Config.logDirectoryName)
        let logFileURL = logDirectory.appendingPathComponent(logFileName)
        return logFileURL
    }
    
    
    private func startFileSizeMonitor() {
        fileSizeCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkAndRotateLogFileIfNeeded()
        }
    }
    
    private func checkAndRotateLogFileIfNeeded() {
//        guard let logFileURL = file.logFileURL else { return }
        
        let fileCounts = getLogFileCount()
        if fileCounts >= Config.maxLogFiles {
            _ = deleteOldestLogFile()
        }
        
//        do {
//            let attributes = try FileManager.default.attributesOfItem(atPath: logFileURL.path)
//            if let fileSize = attributes[.size] as? UInt64, fileSize >= Config.maxLogFileSize {
//                logger.removeDestination(file)
//                file.logFileURL = getNewFilePath()
//                logger.addDestination(file)
//            }
//        } catch {
//            logger.error("Failed to check log file size: \(error)")
//        }
    }
    
    func getLogFileCount() -> Int {
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let logDirectory = documentsDirectory.appendingPathComponent(Config.logDirectoryName)
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: logDirectory.path)
                return contents.filter { $0.hasSuffix(".log") }.count
            } catch {
                logger.error("Failed to get log file count: \(error)")
            }
        }
        return 0
    }
    
    func deleteOldestLogFile() -> Bool {
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let logDirectory = documentsDirectory.appendingPathComponent(Config.logDirectoryName)
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: logDirectory.path)
                let logFiles = contents.filter { $0.hasSuffix(".log") }
                
                if let oldestFile = logFiles.sorted().first {
                    let fileURL = logDirectory.appendingPathComponent(oldestFile)
                    try fileManager.removeItem(at: fileURL)
                    logger.info("Deleted oldest log file: \(oldestFile)")
                    return true
                }
            } catch {
                logger.error("Failed to delete oldest log file: \(error)")
            }
        }
        return false
    }
    
    func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.verbose(message, file: file, function: function, line: line)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.debug(message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.info(message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.warning(message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.error(message, file: file, function: function, line: line)
    }
}

// 添加日志方法别名
extension Logger {
    static func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.verbose(message, file: file, function: function, line: line)
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.debug(message, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.info(message, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.warning(message, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        shared.error(message, file: file, function: function, line: line)
    }
}
