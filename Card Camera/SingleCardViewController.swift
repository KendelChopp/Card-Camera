//
//  SingleCardViewController.swift
//  Card Camera
//
//  Created by Kendel Chopp on 1/7/18.
//  Copyright © 2018 Kendel Chopp. All rights reserved.
//

import UIKit

class SingleCardViewController: UIViewController {
    @IBOutlet var cameraView: UIImageView!
    @IBOutlet var cameraButton: UIImageView!
    var videoCameraWrapper : CardCameraWrapper!
    @IBOutlet var cardLabel: UILabel!
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        cameraButton.isUserInteractionEnabled = true
        cameraButton.addGestureRecognizer(tapGestureRecognizer)
        
        self.videoCameraWrapper = CardCameraWrapper(controller:self, andImageView:cameraView, withNumCards: 1)
        let numList = [UIImage(named:"A"), UIImage(named:"2"), UIImage(named:"3"), UIImage(named:"4"), UIImage(named:"5"), UIImage(named:"6"), UIImage(named:"7"), UIImage(named:"8"), UIImage(named:"9"), UIImage(named:"10"), UIImage(named:"J"), UIImage(named:"Q"), UIImage(named:"K"), UIImage(named:"JOKER")]
        for im in numList {
            self.videoCameraWrapper.loadTrainingNumber(im)
        }
        let suitList = [UIImage(named:"SPADE"), UIImage(named:"HEART"), UIImage(named:"DIAMOND"), UIImage(named:"CLUB")]
        for im in suitList {
            self.videoCameraWrapper.loadTrainingSuit(im)
        }
        
    }
    override func viewDidAppear(_ animated: Bool) {
        self.videoCameraWrapper.start()
    }
    override func viewDidDisappear(_ animated: Bool) {
        self.videoCameraWrapper.stop()
    }
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        //let tappedImage = tapGestureRecognizer.view as! UIImageView
        cardLabel.text = self.videoCameraWrapper.identifyCard()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
