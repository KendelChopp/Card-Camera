//
//  ViewController.swift
//  Card Camera
//
//  Created by Kendel Chopp on 12/27/17.
//  Copyright © 2017 Kendel Chopp. All rights reserved.
//
// Black (#0E0816), Fuschia (#A239CA), Blue (#4717F6), Gray (#E7DFDD)
import UIKit

class ViewController: UIViewController {
    @IBOutlet var singleButton: UIButton!
    @IBOutlet var singleButtonLive: UIButton!
    @IBOutlet var golfButton: UIButton!
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        golfButton.layer.cornerRadius = 5
        singleButtonLive.layer.cornerRadius = 5
        singleButton.layer.cornerRadius = 5
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

