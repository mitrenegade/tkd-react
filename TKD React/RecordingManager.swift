//
//  RecordingManager.swift
//  TKD React
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 RenderApps, LLC. All rights reserved.
//

import UIKit
import AVFoundation

class RecordingManager: NSObject {

    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!

    override init() {
        AVAudioSession.sharedInstance().requestRecordPermission () { allowed in
            if allowed {
                // Microphone allowed
            } else {
                // User denied microphone
            }
        }
        
        //setup to play sound while recording audio
        do {
            let session = AVAudioSession.sharedInstance()
            try! session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
        }
    }

    func startRecording() {
        
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m"
        let fileName = "\(df.string(from: NSDate())).wav"
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        audioRecorder = try! AVAudioRecorder(url: path, settings: [:])
        
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }
    
    func stop() {
        audioRecorder.stop()
    }
}
