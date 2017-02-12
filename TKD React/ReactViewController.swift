//
//  ReactViewController.swift
//  TKD React
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 RenderApps, LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class ReactViewController: UIViewController {

    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var labelCount: UILabel!
    
    let cueManager = CueManager()
    let recordingManager = RecordingManager()
    let motionManager = MotionManager()
    
    var timer: Timer?
    var startTime: Date?
    var paused: Bool = false
    var saved: Bool = false
    var timeElapsedSincePause: TimeInterval = 0 // tracks previous time after a pause/resume
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var savingOverlay: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // make sure label is the correct size
        self.labelTime.sizeToFit()
        self.labelTime.center = CGPoint(x: self.labelTime.superview!.frame.size.width/2, y: self.labelTime.superview!.frame.size.height/2)
        
        //request microphone permission
        
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

        self.start()
    }
    
    @IBAction func didClickButton(_ sender: AnyObject?) {
        if self.timer != nil {
            self.pause()
        }
        else {
            if paused {
                self.showOptions()
            }
            else {
                self.start()
            }
        }
    }

    func start() {
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
                self.refresh()
            })
        } else {
            // Fallback on earlier versions
            self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        }
        
        if self.paused {
            print("resuming")
        }
        else {
            // create CSV writer
            DataManager.sharedInstance.start()
            
            // start recording motion
            motionManager.start()
            
            // start recording audio
            recordingManager.start()
            
            // start cue timer
            cueManager.start()
        }

        // start timer
        self.labelTime.textAlignment = .left // to eliminate jitter
        startTime = Date()
        self.timer?.fire()

        self.button.setTitle("STOP", for: .normal)
    }
    
    func refresh() {
        if let start = startTime {
            let df = DateFormatter()
            df.dateFormat = "mm:ss:SS"
            let interval = Date().timeIntervalSince(start)
            let date = Date(timeIntervalSinceReferenceDate: interval)
            self.labelTime.text = df.string(from: date)
        }
        else {
            self.labelTime.text = "0"
        }
        
        self.labelCount.text = "\(self.cueManager.elapsed)"
    }
    
    func resume() {
        self.saved = false // new data will be added so must resave
        self.start()
    }
    
    func reset() {
        self.button.setTitle("START", for: .normal)
        self.labelTime.text = "0"
        self.labelTime.textAlignment = .center // number is now 0
        self.paused = false
        self.saved = false
        self.timeElapsedSincePause = 0
        
        self.cueManager.elapsed = 0
        self.labelCount.text = "\(self.cueManager.elapsed)"
    }
    
    func pause() {
        if let startTime = self.startTime {
            self.timeElapsedSincePause += Date().timeIntervalSince(startTime)
        }
        self.timer?.invalidate()
        self.timer = nil
        self.startTime = nil
        
        cueManager.stop()
        recordingManager.stop()
        motionManager.stop()
        
        DataManager.sharedInstance.stop()
        
        paused = true
        self.button.setTitle("OPTIONS", for: .normal)
        
        self.showOptions()
    }
    
    func showOptions() {
        let alert = UIAlertController(title: "Session ended", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Save and send data", style: .default, handler: { (action) in
            if self.saved {
                guard let dataPath = DataManager.sharedInstance.filepath else {
                    self.simpleAlert("Invalid data path", message: "Could not load path for data")
                    return
                }
                guard let audioPath = self.recordingManager.filepath else {
                    self.simpleAlert("Invalid audio path", message: "Could not load path for audio")
                    return
                }
                
                let paths = [dataPath, audioPath]
                self.sendData(paths: paths)
            }
            else {
                self.savingOverlay.isHidden = false
                self.saveData(completion: { (success, paths) in
                    self.savingOverlay.isHidden = true
                    if success {
                        self.sendData(paths: paths)
                        self.saved = true
                    }
                    else {
                        self.simpleAlert("Error uploading data", message: "Please click PAUSED button to try again")
                    }
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Resume session", style: .default, handler: { (action) in
            // resume
            self.resume()
        }))
        alert.addAction(UIAlertAction(title: "Discard session", style: .default, handler: { (action) in
            // discard
            self.reset()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            // return to session, but not unpause
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveData(completion: @escaping ((Bool, [URL])->Void)) {
    
        guard let dataPath = DataManager.sharedInstance.filepath else {
            self.simpleAlert("Invalid data path", message: "Could not load path for data")
            return
        }
        guard let audioPath = recordingManager.filepath else {
            self.simpleAlert("Invalid audio path", message: "Could not load path for audio")
            return
        }
        
        var successCount = 0
        var errorCount = 0

        //Firebase
        let csvString = DataManager.sharedInstance.csvString
        let filenameBase = DataManager.sharedInstance.filenameBase
        
        let  sessionRef = ref.child("sessions").childByAutoId()
        sessionRef.child("Motion").setValue(csvString)
        
        let csvRef = storageRef.child("\(filenameBase).csv")
        
        _ = csvRef.putFile(dataPath, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
                errorCount += 1
                if successCount + errorCount == 2 {
                    completion(false, [dataPath, audioPath])
                }
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL()
                sessionRef.child("csvLink").setValue("\(downloadURL!)")
                successCount += 1
                if successCount + errorCount == 2 {
                    completion(true, [dataPath, audioPath])
                }
            }
        }
        
        let audioRef = storageRef.child("\(filenameBase).wav")
        
        _ = audioRef.putFile(audioPath, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
                if successCount + errorCount == 2 {
                    completion(false, [dataPath, audioPath])
                }
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL()
                sessionRef.child("audioLink").setValue("\(downloadURL!)")
                successCount += 1
                if successCount + errorCount == 2 {
                    completion(true, [dataPath, audioPath])
                }
            }
        }
        
    }
    
    func sendData(paths: [URL]) {
        let vc = UIActivityViewController(activityItems: paths, applicationActivities: [])
        
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

    }
}
