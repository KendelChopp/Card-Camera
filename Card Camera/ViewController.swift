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
        let numList = [UIImage(named:"A"), UIImage(named:"2"), UIImage(named:"3"), UIImage(named:"4"), UIImage(named:"5"), UIImage(named:"6"), UIImage(named:"7"), UIImage(named:"8"), UIImage(named:"9"), UIImage(named:"10"), UIImage(named:"J"), UIImage(named:"Q"), UIImage(named:"K"), UIImage(named:"JOKER")]
        for im in numList {
            CameraFunctions.loadTrainingNumber(im)
        }
        let suitList = [UIImage(named:"SPADE"), UIImage(named:"HEART"), UIImage(named:"DIAMOND"), UIImage(named:"CLUB")]
        for im in suitList {
            CameraFunctions.loadTrainingSuit(im)
        }
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

