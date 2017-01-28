//
//  SettingsManager.swift
//  TKD React
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 RenderApps, LLC. All rights reserved.
//

import UIKit

class SettingsManager: NSObject {
    static let instance = SettingsManager()
    
    var numberOfCues = -1
    var minInterval = 1
    var maxInterval = 5
}
