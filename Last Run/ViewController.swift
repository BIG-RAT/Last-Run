//
//  ViewController.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21.
//

import Cocoa

class ViewController: NSViewController {
    
    
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
        userDefaults.set(sender.state.rawValue, forKey: "saveCreds")
        userDefaults.synchronize()
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
        WriteToLog().createLogFile() { [self]
            (result: String) in
            computerList.removeAll()
            policy.idName.removeAll()
            objectLastRun.removeAll()
            resultsDict.removeAll()
            
            jamfServer = jamfServer_TextField.stringValue
            username   = uname_TextField.stringValue
            password   = passwd_TextField.stringValue
            let creds  = "\(username):\(password)"
            b64Creds   = creds.data(using: .utf8)?.base64EncodedString() ?? ""
            jamfProServer.validToken["source"] = false
            
            checkPolicies = (policies_button.state.rawValue == 1) ? true:false
            checkCompCPs  = (ccp_button.state.rawValue == 1) ? true:false
            checkCompApps = (cApps_button.state.rawValue == 1) ? true:false
            checkMDCPs    = (mdcp_button.state.rawValue == 1) ? true:false
            checkMDApps   = (mdApps_button.state.rawValue == 1) ? true:false
            
            spinner_progress.startAnimation(self)
            search_button.isEnabled = false
            runComplete = false
            TokenDelegate().getToken(whichServer: "source", serverUrl: jamfServer, base64creds: b64Creds) { [self]
                authResult in
                let (statusCode,theResult) = authResult
                if theResult == "success" {
                    userDefaults.set(jamfServer, forKey: "server")
                    userDefaults.set(username, forKey: "username")
                    if saveCreds_button.state.rawValue == 1 {
                        Credentials2().save(service: "lastrun-\(jamfServer.fqdnFromUrl)", account: username, data: password)
                    }
                    LastRun().computers(jamfServer: jamfServer, b64Creds: b64Creds, theEndpoint: "computers", checkPolicies: checkPolicies, checkCompCPs: checkCompCPs, checkCompApps: checkCompApps) { [self]
                        (computerHistory: [String:[String:String]]) in
                        LastRun().devices(jamfServer: jamfServer, b64Creds: b64Creds, theEndpoint: "mobiledevices", checkMDCPs: checkMDCPs, checkMDApps: checkMDApps) { [self]
                            (deviceHistory: [String:[String:String]]) in
                            resultsDict = computerHistory.merging(deviceHistory) { (_, new) in new }
                            spinner_progress.stopAnimation(self)
                            search_button.isEnabled = true
                            runComplete = true
                            
                            self.performSegue(withIdentifier: "showResults", sender: self)
                        }
                    }
                } else {
                    _ = Alert().display(header: "Attention:", message: "Failed to authenticate.  Status code: \(statusCode)", secondButton: "")
                    spinner_progress.stopAnimation(self)
                    search_button.isEnabled = true
                    runComplete = true
                }
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showResults") {
            if let resultsVC = segue.destinationController as? ResultVC {
                resultsVC.resultsDict = resultsDict
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        WriteToLog().createLogFile() { [self]
            (result: String) in
            jamfServer_TextField.stringValue = userDefaults.string(forKey: "server") ?? ""
            uname_TextField.stringValue = userDefaults.string(forKey: "username") ?? ""
            saveCreds_button.state = NSControl.StateValue(userDefaults.integer(forKey: "saveCreds")) 
            if jamfServer_TextField.stringValue != "" {
                let credentialsArray = Credentials2().retrieve(service: "lastrun-\(jamfServer_TextField.stringValue.fqdnFromUrl)")
                if credentialsArray.count == 2 {
                    uname_TextField.stringValue = credentialsArray[0]
                    passwd_TextField.stringValue = credentialsArray[1]
                }
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

