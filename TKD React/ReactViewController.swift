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
    
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
            self.stop()
        }
        else {
            self.start()
        }
    }

    func start() {
        startTime = Date()
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
                self.refresh()
            })
        } else {
            // Fallback on earlier versions
            self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        }
        self.timer?.fire()
        
        // create CSV writer
        DataManager.sharedInstance.start()

        // start recording motion
        motionManager.start()
        
        // start recording audio
        recordingManager.start()
        
        // start cue timer
        cueManager.start()
        
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
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
        
        cueManager.stop()
        recordingManager.stop()
        motionManager.stop()
        
        DataManager.sharedInstance.stop()
        
        guard let dataPath = DataManager.sharedInstance.filepath else {
            self.simpleAlert("Invalid data path", message: "Could not load path for data")
            return
        }
        guard let audioPath = recordingManager.filepath else {
            self.simpleAlert("Invalid audio path", message: "Could not load path for audio")
            return
        }
        
        let vc = UIActivityViewController(activityItems: [dataPath, audioPath], applicationActivities: [])
        
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

        //Firebase
        let csvString = DataManager.sharedInstance.csvString
        let filenameBase = DataManager.sharedInstance.filenameBase
        
        let  sessionRef = ref.child("sessions").childByAutoId()
        sessionRef.child("Motion").setValue(csvString)
        
        let csvRef = storageRef.child("\(filenameBase).csv")
        
        _ = csvRef.putFile(dataPath, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL()
                sessionRef.child("csvLink").setValue("\(downloadURL!)")
            }
        }
        
        let audioRef = storageRef.child("\(filenameBase).wav")
        
        _ = audioRef.putFile(audioPath, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL()
                sessionRef.child("audioLink").setValue("\(downloadURL!)")
            }
        }
        
        self.button.setTitle("START", for: .normal)
    }
}
