//
//  ViewController.swift
//  TKD React
//
//  Created by Bobby Ren on 1/16/17.
//  Copyright © 2017 RenderApps, LLC. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet var tfBeeps: UITextField!
    @IBOutlet var tfMin: UITextField!
    @IBOutlet var tfMax: UITextField!
        
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tfBeeps.text = "\(SettingsManager.instance.numberOfCues)"
        tfMin.text = "\(SettingsManager.instance.minInterval)"
        tfMax.text = "\(SettingsManager.instance.maxInterval)"
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

