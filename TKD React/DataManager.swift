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
    
    var csvString = "Time,Motion,Beep\n"

    func start() {
    }
    
    func write(_ data: String) {
        self.csvString.append(data)
    }
}
