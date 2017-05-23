//
//  ViewController.swift
//  TokyoTechLogin
//
//  Created by moto on 2016/10/27.
//  Copyright © 2016年 nanashiki. All rights reserved.
//

import Cocoa
import KeychainAccess

enum ACPASSConfirmationError : Error{
    case NoError
    case AccountContainSpace
    case PasswordIllegalString
    case Unknown
}

class ViewController: NSViewController {
    @IBOutlet weak var accountTF: NSTextField!
    @IBOutlet weak var passwordTF: NSSecureTextField!
    var message = ""
    var success = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let account = UserDefaults.standard.string(forKey: "Account") {
            accountTF.stringValue = account
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    @IBAction func saveBtnAction(_ sender: AnyObject) {
        let (error,username,password) = tfConfirmation()
        
        
        switch error {
        case .NoError:
            saveAccount(username: username, password: password)
            
            Login.shared.account = PortalAccount(username: username, password: password)
            Login.shared.status = .logout
            
            message = "アカウントを設定しました！"
            success = true
        case .AccountContainSpace:
            message = "無効なアカウントです"
            success = false
        case .PasswordIllegalString:
            message = "無効なパスワードです"
            success = false
        case .Unknown:
            message = "不明なエラーです"
            success = false
        }
        self.performSegue(withIdentifier: "Confirm", sender: nil)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let vc = segue.destinationController as? ConfirmViewController else{
            return
        }
        
        vc.message = self.message
        vc.success = self.success
        vc.parentVC = self
    }
    
    @IBAction func cancelBtnAction(_ sender: NSButton) {
        self.dismiss(nil)
    }
    
    func tfConfirmation()->(ACPASSConfirmationError,String,String){
        if var account = accountTF?.stringValue{
            if let password = passwordTF?.stringValue{
                if account.characters.count == 0 || account.contains(" "){
                    return (.AccountContainSpace,"","")
                }
                
                account = account.uppercased()
                
                if password.characters.count < 8 || password.contains(" "){
                    return (.PasswordIllegalString,"","")
                }
                
                return (.NoError,account,password)
            }
        }
        
        return (.Unknown,"","")
        
    }
    
    func saveAccount(username:String,password:String) {
        let ud = UserDefaults.standard
        ud.set(username, forKey: "Account")
        ud.synchronize()
        
        Keychain(service:"com.nanashiki.TokyoTechWifiLogin.password")[username] = password
    }
}

