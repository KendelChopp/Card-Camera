//
//  SingleCardLiveViewController.swift
//  Card Camera
//
//  Created by Kendel Chopp on 1/10/18.
//  Copyright © 2018 Kendel Chopp. All rights reserved.
//

import UIKit

class SingleCardLiveViewController: UIViewController {
    @IBOutlet var cardLabel: UILabel!
    @IBOutlet var cameraView: UIImageView!
    
    var videoCameraWrapper : SingleCardLiveCamera!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoCameraWrapper = SingleCardLiveCamera(controller:self, andImageView:cameraView, withNumCards: 1)
        self.videoCameraWrapper.setupLive(cardLabel)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        self.videoCameraWrapper.start()
    }
    override func viewDidDisappear(_ animated: Bool) {
        self.videoCameraWrapper.stop()
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
