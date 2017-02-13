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
    var elapsed: Int = 0
    
    var timer: Timer?
    var startTime: Date?
    var startDelay: TimeInterval = 5 // first tick occurs instantly after timer starts, so delay for 5 seconds

    func start() {
        isPlaying = true
        loops = SettingsManager.instance.numberOfCues
        
        let when = DispatchTime.now() + startDelay
        DispatchQueue.main.asyncAfter(deadline: when, execute: {
            if SettingsManager.instance.randomizedIntervals {
                self.startRandomIntervals()
            }
            else {
                self.startRegularIntervals()
            }
        })
    }
    
    func startRegularIntervals() {
        startTime = Date()
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { (timer) in
                self.tick()
            })
            self.tick()
        } else {
            // Fallback on earlier versions
            self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
            self.tick()
        }
    }
    
    func startRandomIntervals() {
        let str = loops == -1 ? "infinite" : "\(loops)"
        let delay = self.delay()
        print("*** CueManager starting with \(str) loops, initial delay: \(delay) ***")
        self.tickAfter(seconds: delay)
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
        let when = DispatchTime.now() + seconds
        DispatchQueue.main.asyncAfter(deadline: when, execute: {

            guard self.isPlaying else { return }
            guard self.loops != 0 else { return }

            self.tick()
            //DataManager.sharedInstance.logCue()
            
            let delay = self.delay()
            self.tickAfter(seconds: delay)
            print("... delaying \(delay) seconds")
        })
    }
    
    func tick() {
        print("TICK!")
        self.elapsed += 1
        let sound = NSDataAsset(name: "tap-crisp")
        do {
            try self.audioPlayer = AVAudioPlayer(data: (sound?.data)!, fileTypeHint: AVFileTypeAIFF)
            self.audioPlayer.play()
        } catch {
            print("could not play sound")
        }

        // repeat
        if self.loops != -1 {
            self.loops -= 1
        }
        
        if self.loops == 0 {
            self.stop()
        }
    }

    func stop() {
        self.isPlaying = false
        self.timer?.invalidate()
        self.timer = nil
        startTime = nil
    }
    
    func resume(startDelay: TimeInterval) {
        // TODO: calculate time left from last timer
        self.startDelay = startDelay
        self.start()
    }
    
    func reset() {
        elapsed = 0
    }
}
