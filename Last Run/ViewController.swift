//
//  ViewController.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21.
//

import Cocoa

class ViewController: NSViewController, SendLoginInfoDelegate {
    
    func sendLoginInfo(loginInfo: (String, String, String, String, Int)) {
            print("[ViewController] loginInfo: \(loginInfo)")
        jamfServer_TextField.stringValue = loginInfo.1.fqdnFromUrl
    }
    
    let fm = FileManager()
    var preferencesDict = [String:AnyObject]()
    let prefsPath = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support/Last Run/settings.plist")

    @IBOutlet weak var jamfServer_TextField: NSTextField!
    @IBOutlet weak var uname_TextField: NSTextField!
    @IBOutlet weak var passwd_TextField: NSSecureTextField!
    @IBOutlet weak var saveCreds_button: NSButton!
    
    @IBOutlet var policies_button: NSButton!
    @IBOutlet var ccp_button: NSButton!
    @IBOutlet var mdcp_button: NSButton!
    @IBOutlet var cApps_button: NSButton!
    @IBOutlet var mdApps_button: NSButton!
    
    
    @IBOutlet var spinner_progress: NSProgressIndicator!
    @IBOutlet var search_button: NSButton!
    
    var jamfServer       = ""
    var username         = ""
    var password         = ""
    var b64Creds         = ""
    var computerList     = [[String:Any]]()
    var mobiledeviceList = [[String:Any]]()
    var objectLastRun    = [String:[String:Int]]()
    var resultsDict      = [String:[String:String]]()
    
    var checkPolicies = false
    var checkCompCPs  = false
    var checkMDCPs    = false
    var checkCompApps = false
    var checkMDApps   = false
    
    @IBAction func saveCreds_action(_ sender: NSButton) {
        defaults.set(sender.state.rawValue, forKey: "saveCreds")
//        defaults.synchronize()
    }
    
    @IBAction func toggleAll(_ sender: NSButton) {
        if NSEvent.modifierFlags.contains(.option) {
            let theState = sender.state.rawValue
            policies_button.state = NSControl.StateValue(rawValue: theState)
            ccp_button.state = NSControl.StateValue(rawValue: theState)
            mdcp_button.state = NSControl.StateValue(rawValue: theState)
            cApps_button.state = NSControl.StateValue(rawValue: theState)
            mdApps_button.state = NSControl.StateValue(rawValue: theState)
        }
    }
    
    @IBAction func search_action(_ sender: Any) {
        WriteToLog.shared.createLogFile() { [self]
            (result: String) in
            computerList.removeAll()
            policy.idName.removeAll()
            objectLastRun.removeAll()
            resultsDict.removeAll()
            
//            jamfServer = jamfServer_TextField.stringValue
//            username   = uname_TextField.stringValue
//            password   = passwd_TextField.stringValue
//            let creds  = "\(username):\(password)"
//            b64Creds   = creds.data(using: .utf8)?.base64EncodedString() ?? ""
//            jamfProServer.validToken["source"] = false
            
            checkPolicies = (policies_button.state.rawValue == 1) ? true:false
            checkCompCPs  = (ccp_button.state.rawValue == 1) ? true:false
            checkCompApps = (cApps_button.state.rawValue == 1) ? true:false
            checkMDCPs    = (mdcp_button.state.rawValue == 1) ? true:false
            checkMDApps   = (mdApps_button.state.rawValue == 1) ? true:false
            
            spinner_progress.startAnimation(self)
            search_button.isEnabled = false
            runComplete = false
            TokenDelegate.shared.getToken(whichServer: "source", base64creds: JamfProServer.base64Creds["source"] ?? "") { [self]
                authResult in
                let (statusCode,theResult) = authResult
                if theResult == "success" {
                    defaults.set(jamfServer, forKey: "server")
                    defaults.set(username, forKey: "username")
//                    if saveCreds_button.state.rawValue == 1 {
//                        Credentials.shared.save(service: "lastrun-\(jamfServer.fqdnFromUrl)", account: username, credential: password)
//                    }
                    LastRun.shared.computers(jamfServer: jamfServer, b64Creds: b64Creds, theEndpoint: "computers", checkPolicies: checkPolicies, checkCompCPs: checkCompCPs, checkCompApps: checkCompApps) { [self]
                        (computerHistory: [String:[String:String]]) in
                        LastRun.shared.devices(jamfServer: jamfServer, b64Creds: b64Creds, theEndpoint: "mobiledevices", checkMDCPs: checkMDCPs, checkMDApps: checkMDApps) { [self]
                            (deviceHistory: [String:[String:String]]) in
                            resultsDict = computerHistory.merging(deviceHistory) { (_, new) in new }
                            spinner_progress.stopAnimation(self)
                            search_button.isEnabled = true
                            runComplete = true
                            
                            self.performSegue(withIdentifier: "showResults", sender: self)
                        }
                    }
                } else {
                    _ = Alert.shared.display(header: "Attention:", message: "Failed to authenticate.  Status code: \(statusCode)", secondButton: "")
                    spinner_progress.stopAnimation(self)
                    search_button.isEnabled = true
                    runComplete = true
                }
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        print("[prepare] segue.identifier: \(segue.identifier)")
        if segue.identifier == "loginView" {
                let loginVC: LoginVC = segue.destinationController as! LoginVC
                loginVC.delegate = self
            } else if (segue.identifier == "showResults") {
                if let resultsVC = segue.destinationController as? ResultVC {
                    resultsVC.resultsDict = resultsDict
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        WriteToLog.shared.createLogFile() {
            (result: String) in
//            jamfServer_TextField.stringValue = defaults.string(forKey: "server") ?? ""
//            uname_TextField.stringValue = defaults.string(forKey: "username") ?? ""
//            saveCreds_button.state = NSControl.StateValue(defaults.integer(forKey: "saveCreds")) 
//            if jamfServer_TextField.stringValue != "" {
//                let credentialsArray = Credentials.shared.retrieve(service: "\(jamfServer_TextField.stringValue.fqdnFromUrl)", account: "\()")
//                if credentialsArray.count == 2 {
//                    uname_TextField.stringValue = credentialsArray[0]
//                    passwd_TextField.stringValue = credentialsArray[1]
//                }
//            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
//        print("[viewDidAppear] showLoginWindow: \(showLoginWindow)")
        if showLoginWindow {
            performSegue(withIdentifier: "loginView", sender: nil)
            showLoginWindow = false
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

