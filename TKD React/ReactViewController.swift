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
    
    var sessionNumber = Int(arc4random())

    let cueManager = CueManager()
    let recordingManager = RecordingManager()
    let motionManager = MotionManager()
    
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

    }

    @IBAction func start(_ sender: Any) {
        print("start")
        
        let loops = SettingsManager.instance.numberOfCues
        let min = SettingsManager.instance.minInterval
        let max = SettingsManager.instance.maxInterval
        
        csvString = "Time,Motion,Beep\n"
        time = Date()
        
        cueManager.startBeeps(sesNum: sessionNumber, loops: loops, min: min, max: max)
        
        motionManager.startMotion()
        recordingManager.startRecording()
        
    }
    
    //Will stop actions but beeps will continue
    @IBAction func stop(_ sender: Any) {
        
        //reset session number to stop beeps
        sessionNumber = Int(arc4random())
                
        cueManager.stop()
        recordingManager.stop()
        
        
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
}
