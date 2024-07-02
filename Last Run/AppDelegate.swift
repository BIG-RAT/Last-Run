//
//  AppDelegate.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    var isDir: ObjCBool    = true
    
    @IBAction func showLogFolder(_ sender: Any) {
        isDir = false
        if (FileManager().fileExists(atPath: Log.path!.appending("/LastRun.log"), isDirectory: &isDir)) {
            let logFiles = [URL(fileURLWithPath: Log.path!.appending("/LastRun.log"))]
                    NSWorkspace.shared.activateFileViewerSelecting(logFiles)
        } else {
            _ = Alert.shared.display(header: "Alert", message: "There are currently no log files to display.", secondButton: "")
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // quit the app if the window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        return true
    }
}

