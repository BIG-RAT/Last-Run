//
//  ResultController.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21.
//

import Cocoa
import Foundation
import WebKit

class ResultVC: NSViewController {

    @IBOutlet weak var results_WebView: WKWebView!
    var myQ = DispatchQueue(label: "com.jamf.current")
    
    let vc = ViewController()
    
    var resultsDict = [String:[String:String]]()
    var resultPage = ""
    
    func windowWillClose(notification: NSNotification) {
            NSApp.stopModal()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        WriteToLog().message(stringOfText: "[PreviewController: viewDidLoad]")
//        self.view.window?.orderOut(self)
        
        generatePage()
            
    }
    
    func generatePage() {
//        resultsDict = results.final
        let typeDict = ["mdcp":"Device Config Profile", "mdApp":"Device App", "computerApp":"Computer App", "ccp":"Computer Config Profile", "policy":"Policy"]
//        WriteToLog().message(stringOfText: "present values: \(prevAllRecordValuesArray[recordNumber])")
//        resultsDict = vc.resultsDict
        if resultsDict.count > 0 {
           
    //            WriteToLog().message(stringOfText: "result: \(result)")
//                let existingValuesDict = result
    //            WriteToLog().message(stringOfText: "bundle path: \(Bundle.main.bundlePath)")
                // old background: #619CC7
            var tableBody = ""
            var newLine   = ""
            for (key, value) in resultsDict {
                for (theName, lastRun) in value {
//                    print("\(lastRun)\t\t\(theName)\t\t\(key)")
                    let runDateTime = "\(lastRun)".replacingOccurrences(of: " +0000", with: "")
                    newLine = """
                    <tr>
                    <td style='text-align:left; width: 26%'>\(runDateTime)</td>
                    <td style='text-align:left; width: 48%'>\(theName)</td>
                    <td style='text-align:left; width: 26%'>\(typeDict[key] ?? key)</td>
                    </tr>
"""
                    tableBody = tableBody + newLine
                }
            }
            //                tr:nth-child(even) { background-color: #FFFFFF; }
                resultPage = """
                    <!DOCTYPE html>
                    <html>
                    <head>
                    <style>
                    body { color: white; background-color: #2F4254; }
                    table, th, td {
                    border: 0px solid black;padding-right: 3px;text-align: left;
                    }
                    #resultsTable { border-collapse: collapse; table-layout: fixed; margin: auto; }
                    th, td { border-bottom: 1px solid #4C7A9B; }
                    </style>
                    </head>
                    <body>
                    <table id="resultsTable">
                    <tr>
                    <th style='width: 26%'; onclick="sortTable(0)">Last Run (UTC)</th>
                    <th style='width: 48%'; onclick="sortTable(1)">Object Name</th>
                    <th style='width: 26%'; onclick="sortTable(2)">Object Type</th>
                    </tr>
                    \(tableBody)
                    </table>
            
            <script>
            function sortTable(n) {
              var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
              table = document.getElementById("resultsTable");
              switching = true;
              //Set the sorting direction to ascending:
              dir = "asc";
              /*Make a loop that will continue until
              no switching has been done:*/
              while (switching) {
                //start by saying: no switching is done:
                switching = false;
                rows = table.rows;
                /*Loop through all table rows (except the
                first, which contains table headers):*/
                for (i = 1; i < (rows.length - 1); i++) {
                  //start by saying there should be no switching:
                  shouldSwitch = false;
                  /*Get the two elements you want to compare,
                  one from current row and one from the next:*/
                  x = rows[i].getElementsByTagName("TD")[n];
                  y = rows[i + 1].getElementsByTagName("TD")[n];
                  /*check if the two rows should switch place,
                  based on the direction, asc or desc:*/
                  if (dir == "asc") {
                    if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
                      //if so, mark as a switch and break the loop:
                      shouldSwitch= true;
                      break;
                    }
                  } else if (dir == "desc") {
                    if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
                      //if so, mark as a switch and break the loop:
                      shouldSwitch = true;
                      break;
                    }
                  }
                }
                if (shouldSwitch) {
                  /*If a switch has been marked, make the switch
                  and mark that a switch has been done:*/
                  rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                  switching = true;
                  //Each time a switch is done, increase this count by 1:
                  switchcount ++;
                } else {
                  /*If no switching has been done AND the direction is "asc",
                  set the direction to "desc" and run the while loop again.*/
                  if (switchcount == 0 && dir == "asc") {
                    dir = "desc";
                    switching = true;
                  }
                }
              }
            }
            </script>
            
                    </body>
                </html>
            """
    //        WriteToLog().message(stringOfText: "new test: \(previewPage)")
//            print("\(resultPage)")
            DispatchQueue.main.async { [self] in
                self.results_WebView.loadHTMLString(resultPage, baseURL: nil)
            }
        } else {
//            ViewController().alert_dialog("Attention", message: "No records found to lookup.")
//            DispatchQueue.main.async {
//                self.view.window?.orderOut(self)
//                self.view.window?.close()
//            }
//            return
        }
        
    }
    
}
