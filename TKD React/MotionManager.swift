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

    func startMotion() {
        motionKit.getAccelerationFromDeviceMotion(0.01){
            (x, y, z) in
            
            //get absolute values
            let absX = abs(x)
            let absY = abs(y)
            let absZ = abs(z)
            
            let average = Double((absX + absY + absZ) / 3)
            
            let d = Date()
            let df = DateFormatter()
            df.dateFormat = "y-MM-dd H:m:ss.SSSS"
            let data = "\(df.string(from: d)),\(average)\n"
            DataManager.sharedInstance.write(data)
        }
    }

    func stop() {
        motionKit.stopAccelerometerUpdates()
        motionKit.stopGyroUpdates()
        motionKit.stopDeviceMotionUpdates()
        motionKit.stopmagnetometerUpdates()
    }
}
