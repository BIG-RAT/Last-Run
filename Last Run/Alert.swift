//
//  ApiCall.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21
//

import Cocoa

class Alert: NSObject {
    func display(header: String, message: String, secondButton: String) -> String {
        NSApplication.shared.activate(ignoringOtherApps: true)
        var selected = ""
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.warning
        if secondButton != "" {
            let otherButton = dialog.addButton(withTitle: secondButton)
            otherButton.keyEquivalent = "\r"
        }
        let okButton = dialog.addButton(withTitle: "OK")
        okButton.keyEquivalent = "o"
        
        let theButton = dialog.runModal()
        switch theButton {
        case .alertFirstButtonReturn:
            selected = secondButton
        default:
            selected = "OK"
        }
        return selected
    }   // func alert_dialog - end
}
