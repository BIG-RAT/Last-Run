//
//  LastRun.swift
//  Last Run
//
//  Created by Leslie Helou on 11/26/21
//

import Foundation

class LastRun {
    
    static let shared = LastRun()
    private init() { }
    
    var updateProgressDelegate: UpdateProgressDelegate?
    func updateProgress(label: String, progress: Double) {
        updateProgressDelegate?.updateProgress(label: label, progress: progress)
    }
    
    var computerList     = [[String:Any]]()
    var mobiledeviceList = [[String:Any]]()
    var objectLastRun    = [String:[String:Int]]()
    var resultsDict      = [String:[String:String]]()
    
    var checkPolicies = false
    var checkCompCPs  = false
    var checkMDCPs    = false
    var checkCompApps = false
    var checkMDApps   = false
    
    func computers(jamfServer: String, b64Creds: String, theEndpoint: String, checkPolicies: Bool, checkCompCPs: Bool, checkCompApps: Bool, completion: @escaping (_ result: [String:[String:String]]) -> Void) {
        
        var computerCounter = 0
        var policyCount = 0
        var macAppcount = 0
        var totalComputerCalls = 0
        
        var apiCounter = 0
        
        resultsDict.removeAll()
        // get list of computers
        ApiCall.shared.getRecord(base64Creds: b64Creds, theEndpoint: theEndpoint, skip: !(checkPolicies || checkCompCPs || checkCompApps)) { [self]
            (computerResult: [String:AnyObject]) in
            computerCounter = computerResult.count
            //                print("computers: \(computerResult)")
            ApiCall.shared.getRecord(base64Creds: b64Creds, theEndpoint: "policies", skip: !checkPolicies) { [self]
                (policiesResult: [String:AnyObject]) in
                
                policyCount = policiesResult.count
                
                var usedPolicyIDs = [String]()
                if policiesResult.count > 0 {
                    let arrayOfPolicies = policiesResult["policies"] as! [[String:Any]]
                    if arrayOfPolicies.count > 0 {
                        for thePolicy in arrayOfPolicies {
                            if let thePolicyId = thePolicy["id"],
                               let thePolicyName = thePolicy["name"] {
                                //                                                if thePolicyId != "" && thePolicyName != "" {
                                if "\(thePolicyName)".range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at", options: .regularExpression) == nil && "\(thePolicyName)" != "Update Inventory" {
                                    policy.idName["\(thePolicyId)"] = "\(thePolicyName)"
                                }
                            }
                        }
                    }
                }
                
                
                if computerCounter > 0 {
                    computerList = computerResult["computers"] as! [[String:Any]]
                    WriteToLog.shared.message("found \(computerList.count) policies")
                    
                    totalComputerCalls = computerList.count + policy.idName.count
                    
                    objectLastRun["policy"] = [:]
                    objectLastRun["ccp"]    = [:]
                    resultsDict["policy"] = [:]
                    resultsDict["computerApp"] = [:]
                    resultsDict["ccp"] = [:]
                    for computer in computerList {
                        let computerID = computer["id"] as! Int
                        //                    print("computerID: \(computerID)")
                        
                        WriteToLog.shared.message("checking computer id \(computerID)'s history")
                        ApiCall.shared.getRecord(base64Creds: b64Creds, theEndpoint: "computerhistory/id/\(computerID)", skip: false) { [self]
                            (result: [String:AnyObject]) in
                            
                            apiCounter += 1
                            updateProgress(label: "computers", progress: Double(apiCounter)/Double(totalComputerCalls))
                            
                            let computerHistory = result["computer_history"] as? [String:Any]
                            
                            if checkPolicies {
                                //                            print("check policies")
                                // find last run date for policies
                                let policyLogs = computerHistory?["policy_logs"] as? [[String:Any]]
                                //                            print("policyLogs: \(String(describing: policyLogs))")
                                if policyLogs != nil {
                                    for log in policyLogs! {
                                        let policyID = log["policy_id"] as! Int
                                        let epoch    = log["date_completed_epoch"] as! Int // in milliseconds
                                        if objectLastRun["policy"]?["\(policyID)"] != nil {
                                            if epoch > (objectLastRun["policy"]?["\(policyID)"] ?? 0) as Int {
                                                objectLastRun["policy"]?["\(policyID)"] = epoch
                                            }
                                        } else {
                                            objectLastRun["policy"]?["\(policyID)"] = epoch
                                        }
                                    }
                                }
                            }
                            if checkCompCPs || checkCompApps {
                                //                            print("check configuration profiles")
                                // find last run date for computer configuration profiles
                                let compProfileCommands = computerHistory?["commands"] as? [String:Any]
                                let compProfilesCompleted = compProfileCommands?["completed"] as? [[String:Any]]
                                //                            print("policyLogs: \(String(describing: policyLogs))")
                                if compProfilesCompleted != nil {
                                    for command in compProfilesCompleted! {
                                        let commandName = command["name"] as! String
                                        let epoch    = command["completed_epoch"] as! Int // in milliseconds
                                        if objectLastRun["ccp"]?["\(commandName)"] != nil {
                                            if epoch > (objectLastRun["ccp"]?["\(commandName)"] ?? 0) as Int {
                                                objectLastRun["ccp"]?["\(commandName)"] = epoch
                                            }
                                        } else {
                                            objectLastRun["ccp"]?["\(commandName)"] = epoch
                                        }
                                    }
                                }
                            }
                            if apiCounter == computerList.count {
                                //                            ApiCall.shared.getRecord(base64Creds: b64Creds, theEndpoint: "policies", skip: !checkPolicies) { [self]
                                //                                (policiesResult: [String:AnyObject]) in
                                //                                    print("computers: \(policiesResult)")
//                                var usedPolicyIDs = [String]()
                                if policiesResult.count > 0 {
//                                    let arrayOfPolicies = policiesResult["policies"] as! [[String:Any]]
//                                    if arrayOfPolicies.count > 0 {
//                                        for thePolicy in arrayOfPolicies {
//                                            if let thePolicyId = thePolicy["id"],
//                                               let thePolicyName = thePolicy["name"] {
//                                                //                                                if thePolicyId != "" && thePolicyName != "" {
//                                                if "\(thePolicyName)".range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at", options: .regularExpression) == nil && "\(thePolicyName)" != "Update Inventory" {
//                                                    policy.idName["\(thePolicyId)"] = "\(thePolicyName)"
//                                                }
//                                            }
//                                        }
//                                    }
                                    //                                    print("\nPolicies")
                                    for (key, value) in objectLastRun["policy"]! {
                                        if policy.idName[key] != nil {
                                            //                                                print("\(String(describing: policy.idName[key]!)) (\(key))\t\t\(NSDate(timeIntervalSince1970:TimeInterval((value/1000))))")
                                            usedPolicyIDs.append(key)
                                            resultsDict["policy"]!["\(String(describing: policy.idName[key]!))  (\(key))"] = "\(NSDate(timeIntervalSince1970:TimeInterval((value/1000))))"
                                        }
                                    }
                                    //                                        print("resultsDict for policies: \(resultsDict)")
                                }
                                // find policies that haven't run
                                WriteToLog.shared.message("scanning for policies with no last run information")
                                for (policyId, policyName) in policy.idName {
                                    
                                    apiCounter += 1
                                    updateProgress(label: "computers", progress: Double(apiCounter)/Double(totalComputerCalls))
                                    
                                    if usedPolicyIDs.firstIndex(of: policyId) == nil {
                                        resultsDict["policy"]!["\(policyName)  (\(policyId))"] = ""
                                    }
                                }
                                var commandType = ""
                                //                                print("objectLastRun[\"ccp\"]: \(String(describing: objectLastRun["ccp"]!))")
                                var compProfilesArray = [String]()
                                WriteToLog.shared.message("scanning for computer configuration profiles that haven't run")
                                ApiCall.shared.getRecord(base64Creds: b64Creds, theEndpoint: "osxconfigurationprofiles", skip: !checkCompCPs) { [self]
                                    (cpResult: [String:AnyObject]) in
                                    //                                    print("computers: \(cpResult)")
                                    var allProfiles = [String]()
                                    
                                    if cpResult.count > 0 {
                                        let arrayOfProfiles = cpResult["os_x_configuration_profiles"] as! [[String:Any]]
                                        WriteToLog.shared.message("found \(arrayOfProfiles.count) computer configuration profiles")
                                        if arrayOfProfiles.count > 0 {
                                            for theProfile in arrayOfProfiles {
                                                allProfiles.append("\(String(describing: theProfile["name"]!))")
                                                compProfilesArray.append("Install Configuration Profile \(String(describing: theProfile["name"]!))")
                                                compProfilesArray.append("Remove Configuration Profile \(String(describing: theProfile["name"]!))")
                                            }
                                        }
                                    }
                                    //                                        print("compProfilesArray: \(compProfilesArray)")
                                    var l_profileName = ""
                                    var action = ""
                                    //                                        print("\nComputer Configuration Profiles")
                                    for (key, value) in objectLastRun["ccp"]! {
                                        if compProfilesArray.firstIndex(of: key) != nil || key.prefix(13) == "Install App -" {
                                            action = ""
                                            commandType = ""
                                            let keyArray = key.components(separatedBy: " ")
                                            if keyArray[0] == "Install" {
                                                action = " (Install)"
                                            } else if keyArray[0] == "Remove" {
                                                action = " (Remove)"
                                            }
                                            if keyArray.count > 1 {
                                                switch keyArray[1] {
                                                case "App":
                                                    if checkCompApps {
                                                        commandType = "computerApp"
                                                        l_profileName = key.replacingOccurrences(of: "Install App - ", with: "")
                                                        l_profileName = l_profileName.replacingOccurrences(of: "Remove App - ", with: "")
                                                    }
                                                case "Configuration":
                                                    if checkCompCPs {
                                                        commandType = "ccp"
                                                        l_profileName = key.replacingOccurrences(of: "Install Configuration Profile ", with: "")
                                                        l_profileName = l_profileName.replacingOccurrences(of: "Remove Configuration Profile ", with: "")
                                                    }
                                                default:
                                                    break
                                                }
                                            }
                                            l_profileName = "\(l_profileName)\(action)"
                                            //                                            print("\(l_profileName)\t\t\(NSDate(timeIntervalSince1970:TimeInterval((value/1000))))")
                                            if commandType != "" {
                                                resultsDict[commandType]!["\(l_profileName)"] = "\(NSDate(timeIntervalSince1970:TimeInterval((value/1000))))"
                                            }
                                        }
                                    }
                                    // search for profiles with no run info
                                    for profileName in allProfiles {
                                        if resultsDict["ccp"]!["\(profileName)"] == nil {
                                            resultsDict["ccp"]!["\(profileName)"] = ""
                                        }
                                    }
                                    // fetch all Mac Apps
                                    WriteToLog.shared.message("scanning for Mac Apps that haven't run")
                                    ApiCall.shared.getRecord(base64Creds: b64Creds, theEndpoint: "macapplications", skip: !checkCompApps) { [self]
                                        (macAppsResult: [String:AnyObject]) in
                                        //                                    print("computers: \(macAppsResult)")
                                        
                                        WriteToLog.shared.message("found \(macAppsResult.count) Mac Apps")
                                        if macAppsResult.count > 0 && checkCompApps {
                                            let arrayOfMacApps = macAppsResult["mac_applications"] as! [[String:Any]]
                                            if arrayOfMacApps.count > 0 {
                                                for theMacApp in arrayOfMacApps {
                                                    if let appName = theMacApp["name"] as? String {
                                                        if resultsDict["computerApp"]!["\(appName)"] == nil {
                                                            resultsDict["computerApp"]!["\(appName)"] = ""
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        completion(resultsDict)
                                    }
                                }
                                //                            }
                            }   // if counter == computerList.count - end
                        }   // ApiCall.shared.getRecord - computerId - end
                    }   // for computer in computerList - end
                } else {  // if result.count > 0 - end
                    completion(resultsDict)
                }
            } //close policies api call
        }
    }
    
    func devices(jamfServer: String, b64Creds: String, theEndpoint: String, checkMDCPs: Bool, checkMDApps: Bool, completion: @escaping (_ result: [String:[String:String]]) -> Void) {
        
        var deviceCount = 0
        var devideAppount = 0
        
        resultsDict.removeAll()
        // get list of mobile device
        ApiCall.shared.getRecord(base64Creds: b64Creds, theEndpoint: "mobiledevices", skip: !(checkMDCPs || checkMDApps)) { [self]
            (mobiledevices: [String:AnyObject]) in
//                print("mobile devices: \(result)")
            var commandType = ""
            resultsDict["mdApp"] = [:]
            resultsDict["mdcp"]   = [:]
            if mobiledevices.count > 0 {
                mobiledeviceList = mobiledevices["mobile_devices"] as! [[String:Any]]
                
                var deviceCounter = 0
                let mobileApiCalls = mobiledeviceList.count + 2
//                var completedApiCalls = 0
                
                objectLastRun["mdcp"]    = [:]
                for device in mobiledeviceList {
                    let deviceId = device["id"] as! Int
//                        print("deviceId: \(deviceId)")
                    ApiCall.shared.getRecord(base64Creds: b64Creds, theEndpoint: "mobiledevicehistory/id/\(deviceId)", skip: false) { [self]
                        (mdh: [String:AnyObject]) in
                        deviceCounter += 1
                        
                        updateProgress(label: "devices", progress: Double(deviceCounter)/Double(mobileApiCalls))
                        
                        let mobiledeviceHistory = mdh["mobile_device_history"] as? [String:Any]
                        
                        if checkMDCPs || checkMDApps {
//                                print("check mobile device configuration profiles)")
                            // find last run date for computer configuration profiles
                            let mdProfileCommands = mobiledeviceHistory?["management_commands"] as? [String:Any]
                            let mdProfilesCompleted = mdProfileCommands?["completed"] as? [[String:Any]]
//                            print("policyLogs: \(String(describing: policyLogs))")
                            if mdProfilesCompleted != nil {
                                for command in mdProfilesCompleted! {
                                    var mdCommandName = command["name"] as! String
                                    mdCommandName = mdCommandName.dropVersion
                                    let epoch    = command["date_time_completed_epoch"] as! Int // in milliseconds
                                    if objectLastRun["ccp"]?["\(mdCommandName)"] != nil {
                                        if epoch > (objectLastRun["mdcp"]?["\(mdCommandName)"] ?? 0) as Int {
                                            objectLastRun["mdcp"]?["\(mdCommandName)"] = epoch
                                        }
                                    } else {
                                        objectLastRun["mdcp"]?["\(mdCommandName)"] = epoch
                                    }
                                }
                            }
                        }
                        
                        if deviceCounter == mobiledeviceList.count {
//                            print("objectLastRun[\"mdcp\"]: \(String(describing: objectLastRun["mdcp"]))")
                            var mdProfilesArray = [String]()
                            ApiCall.shared.getRecord(base64Creds: b64Creds, theEndpoint: "mobiledeviceconfigurationprofiles", skip: !checkMDCPs) { [self]
                                (mdcp: [String:AnyObject]) in
                                deviceCounter += 1
                                
                                updateProgress(label: "devices", progress: Double(deviceCounter)/Double(mobileApiCalls))
                                
                                var allProfiles = [String]()
//                                    print("mobile devices: \(result)")
                                if mdcp.count > 0 {
                                    let arrayOfProfiles = mdcp["configuration_profiles"] as! [[String:Any]]
                                    if arrayOfProfiles.count > 0 {
                                        for theProfile in arrayOfProfiles {
                                            allProfiles.append("\(String(describing: theProfile["name"]!))")
                                            mdProfilesArray.append("Install Configuration Profile \(String(describing: theProfile["name"]!))")
                                            mdProfilesArray.append("Remove Configuration Profile \(String(describing: theProfile["name"]!))")
                                        }
                                    }
//                                    print("mdProfilesArray: \(mdProfilesArray)")
                                    var l_profileName = ""
                                    var action = ""
    //                                print("\nMobile Device Configuration Profiles")
                                    for (key, value) in objectLastRun["mdcp"]! {
                                        if mdProfilesArray.firstIndex(of: key) != nil {
                                            action = ""
                                            let keyArray = key.components(separatedBy: " ")
                                            if keyArray[0] == "Install" {
                                                action = " (Install)"
                                            } else if keyArray[0] == "Remove" {
                                                action = " (Remove)"
                                            }
                                            if keyArray.count > 1 {
                                                if keyArray[1] == "Configuration" {
                                                    commandType = "mdcp"
                                                    l_profileName = key.replacingOccurrences(of: "Install Configuration Profile ", with: "")
                                                    l_profileName = l_profileName.replacingOccurrences(of: "Remove Configuration Profile ", with: "")
                                                }
                                            }
                                            l_profileName = "\(l_profileName)\(action)"
    //                                        print("\(l_profileName)\t\t\(NSDate(timeIntervalSince1970:TimeInterval((value/1000))))")
                                            resultsDict[commandType]!["\(l_profileName)"] = "\(NSDate(timeIntervalSince1970:TimeInterval((value/1000))))"
                                        }
                                    }
                                }
                                // check for profiles with no run info
                                for profileName in allProfiles {
                                    if resultsDict["mdcp"]!["\(profileName)"] == nil {
                                        resultsDict["mdcp"]!["\(profileName)"] = ""
                                    }
                                }
                                
                                // check mobile device App Store Apps
                                var mdAppsArray = [String]()
                                ApiCall.shared.getRecord(base64Creds: b64Creds, theEndpoint: "mobiledeviceapplications", skip: !checkMDApps) { [self]
                                    (mobileDevceApps: [String:AnyObject]) in
//                                    print("mobile devices: \(result)")
                                    var allMobileApps = [String]()
                                    deviceCounter += 1
                                    
                                    updateProgress(label: "devices", progress: Double(deviceCounter)/Double(mobileApiCalls))
                                    
                                    if mobileDevceApps.count > 0 {
                                        let arrayOfApps = mobileDevceApps["mobile_device_applications"] as! [[String:Any]]
                                        if arrayOfApps.count > 0 {
                                            for theApp in arrayOfApps {
                                                allMobileApps.append("\(String(describing: theApp["name"]!))")
                                                mdAppsArray.append("Install App - \(String(describing: theApp["name"]!))")
                                                mdAppsArray.append("Remove App - \(String(describing: theApp["name"]!))")
                                            }
                                        }
//                                        print("mdAppsArray: \(mdAppsArray)")

                                        var l_profileName = ""
                                        var action = ""
    //                                    print("\nMobile Device Apps")
                                        for (key, value) in objectLastRun["mdcp"]! {
                                            if mdAppsArray.firstIndex(of: key) != nil {
                                                action = ""
                                                let keyArray = key.components(separatedBy: " ")
                                                l_profileName = key.replacingOccurrences(of: "Install App - ", with: "")
                                                l_profileName = l_profileName.replacingOccurrences(of: "Remove App - ", with: "")
                                                if keyArray[0] == "Install" {
                                                    action = " (Install)"
                                                } else if keyArray[0] == "Remove" {
                                                    action = " (Remove)"
                                                }
                                                if keyArray.count > 1 {
                                                    if keyArray[1] == "App" {
                                                        commandType = "mdApp"
                                                        l_profileName = key.replacingOccurrences(of: "Install App - ", with: "")
                                                        l_profileName = l_profileName.replacingOccurrences(of: "Remove App - ", with: "")
                                                    }
                                                }
                                                l_profileName = "\(l_profileName)\(action)"
    //                                            print("\(l_profileName)\t\t\(NSDate(timeIntervalSince1970:TimeInterval((value/1000))))")
                                                resultsDict[commandType]!["\(l_profileName)"] = "\(NSDate(timeIntervalSince1970:TimeInterval((value/1000))))"
                                            }
                                        }
                                    }
                                    // check of Mobile Device Apps with no run info
                                    for appName in allMobileApps {
                                        if resultsDict["mdApp"]!["\(appName)"] == nil {
                                            resultsDict["mdApp"]!["\(appName)"] = ""
                                        }
                                    }
                                    
                                    completion(resultsDict)
                                }   // ApiCall.shared.getRecord - mobiledeviceapplications - end
                            }
                        }
                    }
                }
            } else {  // if result.count > 0 - end
                completion(resultsDict)
            }
        }
    }
}
