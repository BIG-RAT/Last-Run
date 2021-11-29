//
//  Globals.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21.
//

import Foundation

struct jamfProVersion {
    static var major = 0
    static var minor = 0
    static var patch = 0
}

struct dependency {
    static var wait = true
}

struct Log {
    static var path: String? = (NSHomeDirectory() + "/Library/Logs/last-run/")
    static var file  = "LastRun.log"
    static var maxFiles = 10
    static var maxSize  = 5000000 // 5MB
}

struct LogLevel {
    static var debug = false
}

struct results {
    static var final = [String:[String:String]]()
}

struct appInfo {
    static let dict    = Bundle.main.infoDictionary!
    static let version = dict["CFBundleShortVersionString"] as! String
}

struct policy {
    static var idName = [String:String]()
}

struct q {
    static var getRecord = OperationQueue() // create operation queue for API GET calls
}

struct setting {
    static var uapiToken             = ""
    static var jpapiSourceToken      = ""
    static var jpapiDestinationToken = ""
}
