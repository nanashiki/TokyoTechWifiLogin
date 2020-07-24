//
//  AppDelegate.swift
//  TokyoTechLogin
//
//  Created by moto on 2016/10/27.
//  Copyright © 2016年 nanashiki. All rights reserved.
//

import Cocoa
import Alamofire
import KeychainAccess
import CoreWLAN
import CFNetwork

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate,CWEventDelegate,NSUserNotificationCenterDelegate {
    var statusItem = NSStatusBar.system.statusItem(withLength: -1)
    @IBOutlet weak var menu: NSMenu!
    var interface:CWInterface?
    let login = Login.shared
    @IBOutlet weak var launchAtLoginItem: NSMenuItem!
    @IBOutlet weak var loginItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        
        self.statusItem.highlightMode = true
        self.statusItem.menu = menu
        self.statusItem.target = self
        self.statusItem.title = "No Wi-Fi"
        if let interface = CWWiFiClient().interface(withName: "en0") {
            self.interface = interface
            
            defer {
                login.start(ssid: {
                    interface.ssid()
                }, completion: { status in
                    DispatchQueue.main.async {
                        switch status {
                        case .success:
                            self.deliverNotification(title: "Login Success", informativeText: "Successful in Login TokyoTech Wi-Fi")
                        case .alreadySuccess:
                            self.deliverNotification(title: "Already Login", informativeText: "Already Login TokyoTech Wi-Fi")
                        case .failure:
                            self.deliverNotification(title: "Login Failed", informativeText: "Account or Password is incorrect")
                        default:
                            break
                        }
                        
                        if let ssid = interface.ssid() {
                            if ssid == "TokyoTech" || ssid == "titech-pubnet" {
                                self.loginItem.isEnabled = true
                            }else{
                                self.loginItem.isEnabled = false
                            }
                            self.statusItem.title = ssid
                        }else{
                            self.loginItem.isEnabled = false
                            self.statusItem.title = "No Wi-Fi"
                        }
                    }
                })
            }
            
            guard let username = UserDefaults.standard.string(forKey: "Account") else{
                login.status = .accountNotSet
                print("Account not set")
                return
            }
            
            guard let password = Keychain(service:"com.nanashiki.TokyoTechWifiLogin.password")[username] else{
                login.status = .accountNotSet
                print("Password not set")
                return
            }
            
            login.account = PortalAccount(username: username, password: password)
        }
        
        if existingItem(itemUrl: Bundle.main.bundleURL) != nil {
            launchAtLoginItem.state = .on
        } else {
            launchAtLoginItem.state = .off
        }
        
        //logout
//        forceLogout()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func quitBtnAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func loginBtnAction(_ sender: NSMenuItem) {
        guard let username = UserDefaults.standard.string(forKey: "Account") else{
            login.status = .failure
            print("Account not set")
            return
        }
        
        guard let _ = Keychain(service:"com.nanashiki.TokyoTechWifiLogin.password")[username] else{
            login.status = .failure
            print("Password not set")
            return
        }
        
        login.login()
    }
    @IBAction func launchAtLoginBtnAction(_ sender: NSMenuItem) {
        let wasOn = sender.state == .on
        sender.state = (wasOn ? .off : .on)
        setLaunchAtLogin(itemUrl: Bundle.main.bundleURL, enabled: !wasOn)
    }
    
    func forceLogout(){
        login.status = .accountNotSet
        login.logout(completion: {
            _ in
            NSApplication.shared.terminate(self)
        })
    }
    
    func deliverNotification(title:String,informativeText:String) {
        print(title)
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = informativeText
        notification.userInfo = ["title" : title]
        DispatchQueue.main.async {
            NSUserNotificationCenter.default.deliver(notification)
        }
        
    }
    
//    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
//        if menuItem == self.loginItem {
//            if let ssid = interface?.ssid(){
//                if ssid == "TokyoTech" || ssid == "titech-pubnet" {
//                    return true
//                }else{
//                    return false
//                }
//            }
//            return false
//        }
//        
//        return true
//    }
    
    // MARK: - Launch At Login Helper
    
    func getLoginItems() -> LSSharedFileList? {
        let allocator = CFAllocatorGetDefault().takeRetainedValue()
        let kLoginItems = kLSSharedFileListSessionLoginItems.takeUnretainedValue()
        guard let loginItems = LSSharedFileListCreate(allocator, kLoginItems, nil) else {
            return nil
        }
        return loginItems.takeRetainedValue()
    }
    
    func existingItem(itemUrl: URL) -> LSSharedFileListItem? {
        guard let loginItems = getLoginItems() else {
            return nil
        }
        
        var seed: UInt32 = 0
        if let currentItems = LSSharedFileListCopySnapshot(loginItems, &seed).takeRetainedValue() as? [LSSharedFileListItem] {
            for item in currentItems {
                let resolutionFlags = UInt32(kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes)
                if let cfurl = LSSharedFileListItemCopyResolvedURL(item, resolutionFlags, nil) {
                    let url = cfurl.takeRetainedValue() as URL
                    if itemUrl == url {
                        return item
                    }
                }
                
            }
        }
        return nil
    }
    
    func setLaunchAtLogin(itemUrl: URL, enabled: Bool) {
        guard let loginItems = getLoginItems() else {
            return
        }
        if let item = existingItem(itemUrl: itemUrl) {
            if (!enabled) {
                LSSharedFileListItemRemove(loginItems, item)
            }
        } else {
            if (enabled) {
                LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst.takeUnretainedValue(), nil, nil, itemUrl as CFURL, nil, nil)
            }
        }
    }
}
