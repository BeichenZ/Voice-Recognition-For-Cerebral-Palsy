//
//  ListeningViewController.swift
//  VoiceRecognitionApp
//
//  Created by BC on 2017-02-26.
//  Copyright © 2017 BC. All rights reserved.
//

import UIKit

class ListeningViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Action
    
    @IBAction func stopButtonTapped(_ sender: UIButton) {
        dismiss(animated:true,completion: nil)
    }

    /*
    // MARK: - Navigation

     
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    //MARK: Action
    @IBAction func unwindFromStopToStartListening(sender:UIStoryboardSegue)
    {
        dismiss(animated:true,completion:nil)
    }

    
}