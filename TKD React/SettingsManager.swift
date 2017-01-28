//
//  SettingsManager.swift
//  TKD React
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class SettingsManager: NSObject {
    static let instance = SettingsManager()
    
    var numberOfCues = 5
    var minInterval = 5
    var maxInterval = 5
}
