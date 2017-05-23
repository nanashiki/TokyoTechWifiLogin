//
//  ConfirmViewController.swift
//  TokyoTechLogin
//
//  Created by nana_dotApp on 2017/05/21.
//  Copyright © 2017年 nanashiki. All rights reserved.
//

import Cocoa

class ConfirmViewController: NSViewController {
    var message = ""
    var success = false
    var parentVC = NSViewController()
    @IBOutlet weak var messageLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.stringValue = message
    }
    
    @IBAction func confirmBtnAction(_ sender: NSButton) {
        if success{
            parentVC.dismiss(nil)
        }else{
            self.dismiss(nil)
        }
    }
}
