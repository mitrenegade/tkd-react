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
    var filepath: URL?
    
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

    func start() {
        let string = DataManager.sharedInstance.filenameBase
        let fileName = "\(string).wav"
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        self.filepath = path
        audioRecorder = try! AVAudioRecorder(url: path, settings: [:])
        
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
        
        print("*** RecordingManager starting with url \(path) ***")
    }
    
    func stop() {
        audioRecorder.stop()
    }
}
