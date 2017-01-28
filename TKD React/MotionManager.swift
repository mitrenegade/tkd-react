//
//  MotionManager.swift
//  TKD React
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 RenderApps, LLC. All rights reserved.
//

import UIKit

class MotionManager: NSObject {
    let motionKit = MotionKit()

    func start() {
        motionKit.getAccelerationFromDeviceMotion(0.01){
            (x, y, z) in
            
            //get absolute values
            let absX = abs(x)
            let absY = abs(y)
            let absZ = abs(z)
            
            let average = Double((absX + absY + absZ) / 3)
            
            DataManager.sharedInstance.logMotion(average)
        }
    }

    func stop() {
        motionKit.stopAccelerometerUpdates()
        motionKit.stopGyroUpdates()
        motionKit.stopDeviceMotionUpdates()
        motionKit.stopmagnetometerUpdates()
    }
}