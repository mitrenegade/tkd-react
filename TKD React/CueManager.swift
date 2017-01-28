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

    var audioPlayer:AVAudioPlayer!
    var isPlaying = false
    var loops: Int = 0

    func start() {
        isPlaying = true
        loops = SettingsManager.instance.numberOfCues
        self.tickAfter(seconds: self.delay())
    }
    
    private func delay() -> Double {
        let min = SettingsManager.instance.minInterval
        let max = SettingsManager.instance.maxInterval
        
        if min == max {
            return Double(min)
        }
        
        let delayms = Double(arc4random_uniform( UInt32((max-min) * 1000)) + UInt32(min*1000))
        return delayms / 1000.0
    }
    
    private func tickAfter(seconds: Double) {
        guard isPlaying else { return }
        guard loops != 0 else { return }

        let when = DispatchTime.now() + seconds
        DispatchQueue.main.asyncAfter(deadline: when, execute: {

            let sound = NSDataAsset(name: "tap-crisp")
            do {
                try self.audioPlayer = AVAudioPlayer(data: (sound?.data)!, fileTypeHint: AVFileTypeAIFF)
                self.audioPlayer.play()
            } catch {
                print("could not play sound")
            }
            DataManager.sharedInstance.logCue()
            
            // repeat
            if self.loops != -1 {
                self.loops -= 1
            }
            self.tickAfter(seconds: self.delay())
        })
    }

    func stop() {
        isPlaying = false
    }
}
