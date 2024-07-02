//
//  ApiCall.swift
//  Last Run
//
//  Created by Leslie Helou on 11/25/21
//

import Cocoa

class ApiCall: NSObject, URLSessionDelegate {
    
    
    static let shared = ApiCall()
    private override init() { }
    
    func getRecord(base64Creds: String, theEndpoint: String, skip: Bool, completion: @escaping (_ result: [String:AnyObject]) -> Void) {

        if skip {
            completion([:])
            return
        }
        let theServer = JamfProServer.url["source"] ?? ""
        if theServer == "" {
            completion([:])
            return
        }
        let objectEndpoint = theEndpoint.replacingOccurrences(of: "//", with: "/")
        WriteToLog.shared.message(stringOfText: "[Json.getRecord] get endpoint: \(objectEndpoint) from server: \(theServer)")
    
        URLCache.shared.removeAllCachedResponses()
        var existingDestUrl = ""
        
        existingDestUrl = "\(theServer)/JSSResource/\(objectEndpoint)"
        existingDestUrl = existingDestUrl.urlFix
//        existingDestUrl = existingDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
//        existingDestUrl = existingDestUrl.replacingOccurrences(of: "/?failover", with: "")
        
        if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Json.getRecord] Looking up: \(existingDestUrl)") }
//      print("existing endpoints URL: \(existingDestUrl)")
        let destEncodedURL = URL(string: existingDestUrl)
        let jsonRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)

        q.getRecord.maxConcurrentOperationCount = 4
        
        let semaphore = DispatchSemaphore(value: 0)
        q.getRecord.addOperation {
//        getRecordQ.async {
            
            jsonRequest.httpMethod = "GET"
            let destConf = URLSessionConfiguration.ephemeral

            destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType["source"] ?? "") \(JamfProServer.accessToken["source"] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = destSession.dataTask(with: jsonRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
//                    print("[Json.getRecord] httpResponse: \(String(describing: httpResponse))")
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                        do {
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let endpointJSON = json as? [String:AnyObject] {
                                if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Json.getRecord] \(endpointJSON)") }
                                completion(endpointJSON)
                            } else {
                                WriteToLog.shared.message(stringOfText: "[Json.getRecord] error parsing JSON for \(existingDestUrl)")
                                completion([:])
                            }
                        }
                    } else {
                        WriteToLog.shared.message(stringOfText: "[Json.getRecord] error HTTP Status Code: \(httpResponse.statusCode)")
                        completion([:])
                    }
                } else {
                    WriteToLog.shared.message(stringOfText: "[Json.getRecord] error parsing JSON for \(existingDestUrl)")
                    completion([:])
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // getRecordQ - end
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}

