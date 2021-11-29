//
//  ViewController.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var saveCreds_button: NSButton!
    
    let fm = FileManager()
    var preferencesDict = [String:AnyObject]()
    let prefsPath = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support/Last Run/settings.plist")

    @IBOutlet weak var jamfServer_TextField: NSTextField!
    @IBOutlet weak var uname_TextField: NSTextField!
    @IBOutlet weak var passwd_TextField: NSSecureTextField!
    
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
    
    @IBAction func search_action(_ sender: Any) {
        computerList.removeAll()
        policy.idName.removeAll()
        objectLastRun.removeAll()
        resultsDict.removeAll()
        
        jamfServer = jamfServer_TextField.stringValue
        username   = uname_TextField.stringValue
        password   = passwd_TextField.stringValue
        let creds  = "\(username):\(password)"
        b64Creds   = creds.data(using: .utf8)?.base64EncodedString() ?? ""

        checkPolicies = (policies_button.state.rawValue == 1) ? true:false
        checkCompCPs  = (ccp_button.state.rawValue == 1) ? true:false
        checkCompApps = (cApps_button.state.rawValue == 1) ? true:false
        checkMDCPs    = (mdcp_button.state.rawValue == 1) ? true:false
        checkMDApps   = (mdApps_button.state.rawValue == 1) ? true:false
        
        spinner_progress.startAnimation(self)
        search_button.isEnabled = false
        LastRun().computers(jamfServer: jamfServer, b64Creds: b64Creds, theEndpoint: "computers", checkPolicies: checkPolicies, checkCompCPs: checkCompCPs, checkCompApps: checkCompApps) { [self]
            (computerHistory: [String:[String:String]]) in
            LastRun().devices(jamfServer: jamfServer, b64Creds: b64Creds, theEndpoint: "mobiledevices", checkMDCPs: checkMDCPs, checkMDApps: checkMDApps) { [self]
                (deviceHistory: [String:[String:String]]) in
                resultsDict = computerHistory.merging(deviceHistory) { (_, new) in new }
                for (key, value) in resultsDict {
                    for (theName, lastRun) in value {
                        print("\(lastRun)\t\t\(theName)\t\t\(key)")

                    }
                }
                spinner_progress.stopAnimation(self)
                search_button.isEnabled = true
                      
                self.performSegue(withIdentifier: "showResults", sender: self)
                
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
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

