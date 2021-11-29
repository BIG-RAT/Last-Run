//
//  Extensions.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21.
//

import Foundation

extension String {
    var fqdnFromUrl: String {
        get {
            var fqdn = ""
            let nameArray = self.components(separatedBy: "://")
            if nameArray.count > 1 {
                fqdn = nameArray[1]
            } else {
                fqdn =  self
            }
            if fqdn.contains(":") {
                let fqdnArray = fqdn.components(separatedBy: ":")
                fqdn = fqdnArray[0]
            }
            return fqdn
        }
    }
    var dropVersion: String {
        get {
            var newName = self
            let nameArray = self.components(separatedBy: " ")
            if nameArray.count > 3 {
                if nameArray[1] == "App" && nameArray[2] == "-" {
                    newName = nameArray.dropLast().joined(separator: " ")
//                    newName = nameArray.joined(separator: " ")
                }
            }
            return newName
        }
    }
    var urlFix: String {
        get {
            var fixedUrl = self.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            fixedUrl = fixedUrl.replacingOccurrences(of: "/?failover", with: "")
            return fixedUrl
        }
    }
}
