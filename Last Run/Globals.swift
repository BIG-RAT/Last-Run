//
//  Globals.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21.
//

import Foundation

let httpSuccess            = 200...299
var refreshInterval:UInt32 = 20*60  // 20 minutes
var runComplete            = false
let userDefaults           = UserDefaults.standard


struct appInfo {
    static let dict            = Bundle.main.infoDictionary!
    static let version         = dict["CFBundleShortVersionString"] as! String
    static let name            = dict["CFBundleExecutable"] as! String
    static let userAgentHeader = "\(String(describing: name.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!))/\(appInfo.version)"
}

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
struct history {
    static var startTime = Date()
}

struct jamfProServer {
    static var majorVersion = 0
    static var minorVersion = 0
    static var patchVersion = 0
    static var version      = ["source":"", "destination":""]
    static var build        = ""
    static var source       = ""
    static var destination  = ""
    static var whichServer  = ""
    static var sourceUser   = ""
    static var destUser     = ""
    static var sourcePwd    = ""
    static var destPwd      = ""
    static var storeCreds   = 0
    static var toSite       = false
    static var destSite     = ""
    static var importFiles  = 0
    static var authCreds    = ["source":"", "destination":""]
    static var authExpires  = ["source":"", "destination":""]
    static var authType     = ["source":"Bearer", "destination":"Bearer"]
    static var base64Creds  = ["source":"", "destination":""]
    static var validToken   = ["source":false, "destination":false]
    static var tokenCreated = [String:Date?]()
    static var pkgsNotFound = 0
    static var sessionCookie = [HTTPCookie]()
    static var stickySession = false
}

struct policy {
    static var idName = [String:String]()
}

struct q {
    static var getRecord = OperationQueue() // create operation queue for API GET calls
}

func dateTime() -> String {
    let current = Date()
    let localCalendar = Calendar.current
    let dateObjects: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    let dateTime = localCalendar.dateComponents(dateObjects, from: current)
    let currentMonth  = leadingZero(value: dateTime.month!)
    let currentDay    = leadingZero(value: dateTime.day!)
    let currentHour   = leadingZero(value: dateTime.hour!)
    let currentMinute = leadingZero(value: dateTime.minute!)
    let currentSecond = leadingZero(value: dateTime.second!)
    let stringDate = "\(dateTime.year!)\(currentMonth)\(currentDay)_\(currentHour)\(currentMinute)\(currentSecond)"
    return stringDate
}

// add leading zero to single digit integers
func leadingZero(value: Int) -> String {
    var formattedValue = ""
    if value < 10 {
        formattedValue = "0\(value)"
    } else {
        formattedValue = "\(value)"
    }
    return formattedValue
}

public func timeDiff(forWhat: String) -> (Int,Int,Int) {
    var components:DateComponents?
    switch forWhat {
    case "runTime":
        components = Calendar.current.dateComponents([.second, .nanosecond], from: history.startTime, to: Date())
    case "sourceTokenAge","destTokenAge":
        let whichServer = (forWhat == "sourceTokenAge") ? "source":"dsstination"
        components = Calendar.current.dateComponents([.second, .nanosecond], from: (jamfProServer.tokenCreated[whichServer] ?? Date())!, to: Date())
    default:
        break
    }
    
    let timeDifference = Int(components?.second! ?? 0)
    let (h,r) = timeDifference.quotientAndRemainder(dividingBy: 3600)
    let (m,s) = r.quotientAndRemainder(dividingBy: 60)
    return(h,m,s)
}
