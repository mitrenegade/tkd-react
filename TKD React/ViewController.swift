//
//  ViewController.swift
//  TKD React
//
//  Created by Bobby Ren on 1/16/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseAuth

class ViewController: UIViewController {
    
    @IBOutlet var tfBeeps: UITextField!
    @IBOutlet var tfMin: UITextField!
    @IBOutlet var tfMax: UITextField!
    
    let motionKit = MotionKit()
    
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    let session = AVAudioSession.sharedInstance()
    
    var csvString = "Time,Motion,Beep\n"
    
    var time = Date()
    
    var timeLine: [Int] = []
    
    var sessionNumber = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionNumber = Int(arc4random())
        
        //request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission () { allowed in
            if allowed {
                // Microphone allowed
            } else {
                // User denied microphone
            }
        }
        
        //setup to play sound while recording audio
        do {
            try! session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
        }
        
        //Checks if account already exists for device, creates anonymous account if needed for read/write access
        if let user = FIRAuth.auth()?.currentUser {
            print("JMD: User logged in with uid: " + user.uid + " and anon: \(user.isAnonymous)")
        } else {
            FIRAuth.auth()?.signInAnonymously() { (user, error) in
                if error != nil {
                    print("JMD: signInAnonomously error: \(error as Any)")
                    ref.child("users").child(user!.uid)
                    return
                }
                print("JMD: Anonymous user created with uid: " + user!.uid)
            }
        }
    }
    
    @IBAction func start(_ sender: Any) {
        print("start")
        
        guard let loops = Int(tfBeeps.text!), let min = Int(tfMin.text!), let max = Int(tfMax.text!) else {
            return
        }
        
        csvString = "Time,Motion,Beep\n"
        time = Date()
        
        
        startBeeps(sesNum: sessionNumber, loops: loops, min: min, max: max)
        
        startMotion()
        startRecording()
        
    }
    
    func startRecording() {
        
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m"
        
        let fileName = "\(df.string(from: time)).wav"
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        audioRecorder = try! AVAudioRecorder(url: path, settings: [:])
        
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }
    
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
            
            self.csvString.append("\(df.string(from: d)),\(average)\n")
        }
    }
    
    
    //Will stop actions but beeps will continue
    @IBAction func stop(_ sender: Any) {
        timeLine = []
        
        //reset session number to stop beeps
        sessionNumber = Int(arc4random())
        
        motionKit.stopAccelerometerUpdates()
        motionKit.stopGyroUpdates()
        motionKit.stopDeviceMotionUpdates()
        motionKit.stopmagnetometerUpdates()
        
        audioRecorder.stop()
        
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:m"
        
        let fileName = "\(df.string(from: time)).csv"
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        let fileName2 = "\(df.string(from: time)).wav"
        let path2 = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName2)
        
        //activity sheet
        do {
            try csvString.write(to: path, atomically: true, encoding: String.Encoding.utf8)
            
            let vc = UIActivityViewController(activityItems: [path, path2], applicationActivities: [])
            
            vc.excludedActivityTypes = [
                UIActivityType.assignToContact,
                UIActivityType.saveToCameraRoll,
                UIActivityType.postToFlickr,
                UIActivityType.postToVimeo,
                UIActivityType.postToTencentWeibo,
                UIActivityType.postToTwitter,
                UIActivityType.postToFacebook,
                //UIActivityType.openInIBooks
            ]
            present(vc, animated: true, completion: nil)
            
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
        
        //Firebase
        let  sessionRef = ref.child("sessions").childByAutoId()
        sessionRef.child("Motion").setValue(csvString)
        
        let csvRef = storageRef.child("\(df.string(from: time)).csv")
        
        _ = csvRef.putFile(path, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL()
                sessionRef.child("csvLink").setValue("\(downloadURL!)")
            }
        }
        
        let audioRef = storageRef.child("\(df.string(from: time)).wav")
        
        _ = audioRef.putFile(path2, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL()
                sessionRef.child("audioLink").setValue("\(downloadURL!)")
            }
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

