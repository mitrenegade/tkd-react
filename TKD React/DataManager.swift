//
//  DataManager.swift
//  TKD React
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 RenderApps, LLC. All rights reserved.
//

import UIKit

class DataManager: NSObject {
    static let sharedInstance = DataManager()
    
    var csvString: String = ""
    var filenameBase: String = ""
    
    let df = DateFormatter()
    var filepath: URL?
    
    func start() {
        df.dateFormat = "y-MM-dd H:m"
        filenameBase = df.string(from: Date())
        csvString = "Time,Motion,Beep\n"

        let fileName = "\(filenameBase).csv"
        self.filepath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        if let path = self.filepath {
            print("*** RecordingManager starting with url \(path) ***")
        }
        else {
            print("*** RecordingManager starting with invalid url ***")
        }
    }
    
    func logMotion(_ value: Double) {
        df.dateFormat = "y-MM-dd H:m:ss.SSSS"
        self.write("\(df.string(from: Date())),\(value)\n")
    }
    
    func logCue() {
        df.dateFormat = "y-MM-dd H:m:ss.SSSS"
        self.write("\(df.string(from: Date())),,1\n")
    }

    private func write(_ data: String) {
        self.csvString.append(data)
    }
    
    func stop() {
        guard let path = self.filepath else { return }
        do {
            try csvString.write(to: path, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
    }
}
