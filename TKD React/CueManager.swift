//
//  CueManager.swift
//  TKD React
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 RenderApps, LLC. All rights reserved.
//

import UIKit
import AVFoundation

class CueManager: NSObject {

    var timeLine: [Int] = []

    func startBeeps(sesNum: Int, loops: Int, min: Int, max: Int) {
        resetTimeLine(loops: loops, min: min, max: max)
        
        var x = 1
        for delay in timeLine {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay), execute: {
                
                let sound = NSDataAsset(name: "tap-crisp")
                
                //check if number has changed, which would mean stop has been pressed
                if sesNum == self.sessionNumber {
                    do {
                        try self.audioPlayer = AVAudioPlayer(data: (sound?.data)!, fileTypeHint: AVFileTypeAIFF)
                        self.audioPlayer.play()
                    } catch {
                        print("could not play sound")
                    }
                    
                    print("triggered beep #\(x) after \(delay) seconds")
                    x += 1
                    
                    let d = Date()
                    let df = DateFormatter()
                    df.dateFormat = "y-MM-dd H:m:ss.SSSS"
                    
                    self.csvString.append("\(df.string(from: d)),,1\n")
                } else {
                    print("would have triggered beep #\(x) after \(delay) seconds, but has been stopped")
                    x += 1
                }
            })
        }
    }

    func resetTimeLine(loops: Int, min: Int, max: Int) {
        
        timeLine = []
        
        for x in 1...loops {
            let delay = Int(arc4random_uniform(UInt32(max - min))) + min
            
            if x == 1 {
                timeLine.append(delay)
            } else {
                let y = timeLine[x - 2]
                timeLine.append(delay + y)
            }
            
            print(timeLine)
        }
    }
    
    func stop() {
        timeLine = []
    }
}
