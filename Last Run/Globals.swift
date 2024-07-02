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
let defaults               = UserDefaults.standard
var useApiClient           = 0
var appsGroupId            = "group.PS2F6S478M.jamfie.SharedJPMA"
var didRun                 = false
var saveServers            = true
var maxServerList          = 20
let sharedDefaults         = UserDefaults(suiteName: appsGroupId)
let sharedContainerUrl     = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appsGroupId)
let sharedSettingsPlistUrl = (sharedContainerUrl?.appendingPathComponent("Library/Preferences/\(appsGroupId).plist"))!


struct AppInfo {
    static let dict          = Bundle.main.infoDictionary!
    static let version       = dict["CFBundleShortVersionString"] as! String
    static let build         = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    static let name          = dict["CFBundleExecutable"] as! String
    
    static let appSupport    = NSHomeDirectory() + "/Library/Application Support/"
    static let bookmarksPath = NSHomeDirectory() + "/Library/Application Support/bookmarks/"
    static let volumes       = NSHomeDirectory() + "/Volumes"

    static let userAgentHeader = "\(String(describing: name.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!))/\(AppInfo.version)"
}

struct JamfProServer {
    static var mask         = false
    static var majorVersion = ["source":0, "destination":0]
    static var minorVersion = ["source":0, "destination":0]
    static var patchVersion = ["source":0, "destination":0]
    static var build        = ["source":"", "destination":""]
    static var accessToken  = ["source":"", "destination":""]
    static var base64Creds  = ["source":"", "destination":""]
    static var authExpires:[String:Double]  = ["source":20.0, "destination":20.0]
    static var authType     = ["source":"Bearer", "destination":"Bearer"]
    static var currentCred  = ["source":"", "destination":""]               // used if we want to auth with a different account / string used to generate token
    static var validToken   = ["source":false, "destination":false]
    static var version      = ["source":"", "destination":""]
    static var tokenCreated = ["source": Date(), "destination": Date()]
    static var username     = ["source":"", "destination":""]
    static var password     = ["source":"", "destination":""]
    static var dpType       = ["source":"", "destination":""]
    static var saveCreds    = ["source":0, "destination":0]
    static var useApiClient = ["source":0, "destination":0]
    static var url          = ["source":"", "destination":""]
    
    static var bucket       = ["source":"", "destination":""]
    static var accessKey    = ["source":"", "destination":""]
    static var secret       = ["source":"", "destination":""]
    static var region       = ["source":"", "destination":""]
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

public func timeDiff(startTime: Date) -> (Int, Int, Int, Double) {
    let endTime = Date()
//                    let components = Calendar.current.dateComponents([.second, .nanosecond], from: startTime, to: endTime)
//                    let timeDifference = Double(components.second!) + Double(components.nanosecond!)/1000000000
//                    WriteToLog.shared.message(stringOfText: "[ViewController.download] time difference: \(timeDifference) seconds")
    let components = Calendar.current.dateComponents([
        .hour, .minute, .second, .nanosecond], from: startTime, to: endTime)
    var diffInSeconds = Double(components.hour!)*3600 + Double(components.minute!)*60 + Double(components.second!) + Double(components.nanosecond!)/1000000000
    diffInSeconds = Double(round(diffInSeconds * 1000) / 1000)
//    let timeDifference = Int(components.second!) //+ Double(components.nanosecond!)/1000000000
//    let (h,r) = timeDifference.quotientAndRemainder(dividingBy: 3600)
//    let (m,s) = r.quotientAndRemainder(dividingBy: 60)
//    WriteToLog.shared.message(stringOfText: "[ViewController.download] download time: \(h):\(m):\(s) (h:m:s)")
    return (Int(components.hour!), Int(components.minute!), Int(components.second!), diffInSeconds)
}
