//
//  Login.swift
//  TokyoTechLogin
//
//  Created by moto on 2016/11/08.
//  Copyright © 2016年 nanashiki. All rights reserved.
//

import Foundation
import Alamofire

public enum LoginStatus {
    case logout
    case nowLogin
    case success
    case alreadySuccess
    case failure
    case noWiFi
    case othersWiFi
    case accountNotSet
    case unknownError
}

fileprivate struct LoginURL {
    static let login = "https://wlanauth.noc.titech.ac.jp/login.html"
    static let logout = "https://wlanauth.noc.titech.ac.jp/logout.html"
}

fileprivate struct FormInputName {
    static let username = "username"
    static let password = "password"
}

fileprivate struct ConfirmString {
    static let success = "Login Successful"
    static let alreadyLogined = "techauth.html"
    static let failure = "techfailure.html"
}

public struct PortalAccount {
    public let username:String
    public let password:String
}

open class Login: NSObject {
    open var status = LoginStatus.logout
    static let shared = Login()
    var sessionManager : SessionManager
    open var account = PortalAccount(username:"",password:"")
    
    fileprivate override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 3
        sessionManager = SessionManager(configuration: configuration)
    }
    
    
    
    open func start(ssid getSSID:@escaping (()->(String?)),completion:((LoginStatus)->())? = nil) {
        if status == .accountNotSet {
            completion?(status)
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: {
                self.start(ssid: getSSID,completion: completion)
            })
            return
        }
        
        if let ssid = getSSID() {
            print("SSID: "+ssid)
            if ssid == "TokyoTech" || ssid == "titech-pubnet"{
                // TokyoTech or titech-pubnet
                if status != .success && status != .alreadySuccess{
                    self.login(completion: {
                        status in
                        completion?(status)
                    })
                }
            }else{
                // Others Wi-Fi
                status = .othersWiFi
                completion?(status)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: {
                self.start(ssid: getSSID,completion: completion)
            })
        }else{
            // Not connect Wi-Fi
            print("SSID: ")
            status = .noWiFi
            completion?(status)
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: {
                self.start(ssid: getSSID,completion: completion)
            })
        }
    }
    
    open func login(completion:((LoginStatus)->())? = nil){
        status = .nowLogin
        sessionManager.request(LoginURL.login,
                          method: .post,
                          parameters: ["username":account.username,
                                       "password":account.password,
                                       "buttonClicked":"4",
                                       "redirect_url":"",
                                       "err_flag":"0",
                                       "Submit":"同意して利用",]
            ).responseString(completionHandler: {
                response in
                switch response.result {
                case .success(let html):
                    if html.contains(ConfirmString.success) {
                        self.status = .success
                    }else if html.contains(ConfirmString.alreadyLogined) {
                        self.status = .alreadySuccess
                    }else if html.contains(ConfirmString.failure){
                        self.status = .failure
                    }else{
                        self.status = .unknownError
                        print("Unknown Error")
                    }
                case .failure(let error):
                    print("Time out:\(error)")
                    self.status = .unknownError
                    break
                }
                completion?(self.status)
            }
        )
    }
    
    open func logout(completion: ((Bool)->())? = nil) {
        sessionManager.request(LoginURL.logout,
                          method: .post,
                          parameters: ["userStatus":"1",
                                       "err_flag":"0",
                                       "err_msg":"",])
            .responseString(completionHandler: {
                response in
                switch response.result {
                case .success(let html):
                    if html.contains("Web Authentication") {
                        self.status = .logout
                        print("Logout Success")
                        completion?(true)
                    }else{
                        self.status = .logout
                        print("Logout Error")
                        completion?(false)
                    }
                case .failure(let error):
                    print("Logout Time out:\(error)")
                    self.status = .unknownError
                    completion?(false)
                    break
                }
            }
        )
    }
}
