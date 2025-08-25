//
//  ResultController.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21.
//

import Cocoa
import Foundation

class queryResults: NSObject {
    @objc var lastRunDate: String
    @objc var objectName: String
    @objc var objectType: String
    
    init(lastRunDate: String, objectName: String, objectType: String) {
        self.lastRunDate = lastRunDate
        self.objectName  = objectName
        self.objectType  = objectType
    }
}

class ResultVC: NSViewController {

    var myQ = DispatchQueue(label: "com.jamf.current")
    @IBOutlet weak var lastRunTableView: NSTableView!
    
    @IBOutlet var results_ArrayController: NSArrayController!
    
    let vc = ViewController()
    
    var resultsDict = [String:[String:String]]()
    var resultPage = ""
    
    let typeDict = ["mdcp":"Device Config Profile", "mdApp":"Device App", "computerApp":"Computer App", "ccp":"Computer Config Profile", "policy":"Policy"]
    
    func windowWillClose(notification: NSNotification) {
            NSApp.stopModal()
    }
    
    @IBAction func export_Action(_ sender: Any) {
        let timeStamp = dateTime()
        let exportQ   = DispatchQueue(label: "lastrun.exportQ", qos: DispatchQoS.background)
        let exportFile = "lastRun_\(timeStamp).csv"
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let exportURL  = downloadsDirectory.appendingPathComponent(exportFile)
        var header = ""
        var headerArray = [String]()
        var currentRow  = ""
        lastRunTableView.tableColumns.enumerated().forEach {
            (_, column) in
            header.append("\(column.title)\t")
            headerArray.append(column.identifier.rawValue)
        }
        header.removeLast()
        currentRow = header
        exportQ.sync {
            do {
                try "\(currentRow)\n".write(to: exportURL, atomically: true, encoding: .utf8)
                let allObjects = results_ArrayController.arrangedObjects
                if let exportFileOp = try? FileHandle(forUpdating: exportURL) {
                    exportFileOp.seekToEndOfFile()
                    for theObject in allObjects as! [queryResults] {
                        let objectDict = ["lastRunDate":theObject.lastRunDate, "objectName":theObject.objectName, "objectType":theObject.objectType]
                        currentRow = ""
                        for theHeader in headerArray {
                            currentRow.append(objectDict[theHeader] ?? "")
                            currentRow.append("\t")
                        }
                        currentRow.removeLast()
                        try exportFileOp.write(contentsOf: "\(currentRow)\n".data(using:String.Encoding.utf8)!)
                    }
                    try exportFileOp.close()
                    _ = Alert.shared.display(header: "Attention:", message: "Results exported to ~/Downloads/\(exportFile)", secondButton: "")
                }
            } catch {
                WriteToLog.shared.message("error writing \(currentRow) to \(exportURL)")
            }
        }
    }
    
    @IBAction func hideBlankDate(_ sender: NSButton) {
        if sender.state.rawValue == 1 {
            updateArray(operation: "hide")
        } else {
            updateArray(operation: "showAll")
        }
    }
    
    func updateArray(operation: String) {
        let arrayRange = 0 ..< (results_ArrayController.arrangedObjects as AnyObject).count
        results_ArrayController.remove(atArrangedObjectIndexes: IndexSet(integersIn: arrayRange))
        for (key, value) in resultsDict {
            for (theName, lastRun) in value {
                let runDateTime = "\(lastRun)".replacingOccurrences(of: " +0000", with: "")
                let currentResult = queryResults(lastRunDate: runDateTime, objectName: theName, objectType: typeDict[key]!)
                if operation == "showAll" || runDateTime != "" {
                    results_ArrayController.addObject(currentResult)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        lastRunTableView.tableColumns.forEach { (column) in
            column.headerCell.attributedStringValue = NSAttributedString(string: column.title, attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 18)])
        }
        updateArray(operation: "showAll")
    }
}
