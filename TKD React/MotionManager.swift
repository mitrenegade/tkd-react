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
        print("*** MotionManater starting ***")
        motionKit.getAccelerationFromDeviceMotion(0.01){
            (x, y, z) in
            
            //get absolute values
            let absX = abs(x)
            let absY = abs(y)
            let absZ = abs(z)
            
            let magnitude = Double(sqrt(absX*absX + absY*absY + absZ*absZ))
            
            DataManager.sharedInstance.logMotion(magnitude)
        }
    }

    func stop() {
        motionKit.stopAccelerometerUpdates()
        motionKit.stopGyroUpdates()
        motionKit.stopDeviceMotionUpdates()
        motionKit.stopmagnetometerUpdates()
    }
    
    func reset() {
        // doesn't do anything
    }
    
    func resume() {
        self.start()
    }
}
