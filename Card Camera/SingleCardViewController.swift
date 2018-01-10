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
    @IBOutlet var cardLabel: UILabel!
    var videoCameraWrapper : SingleCardCamera!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        cameraButton.isUserInteractionEnabled = true
        cameraButton.addGestureRecognizer(tapGestureRecognizer)
        self.videoCameraWrapper = SingleCardCamera(controller:self, andImageView:cameraView, withNumCards: 1)

        
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
    @IBAction func exit(_ sender: Any) {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        }
    }
    
}
