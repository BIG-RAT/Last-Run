//
//  TokenDelegate.swift
//  Last Run
//
//  Created by Leslie Helou on 11/26/21
//

import Cocoa

class TokenDelegate: NSObject, URLSessionDelegate {
    
    static let shared = TokenDelegate()
    private override init() { }
    
    var components   = DateComponents()
    var renewQ       = DispatchQueue(label: "com.token_refreshQ", qos: DispatchQoS.background)   // running background process for refreshing token
    
    func getToken(whichServer: String = "source", base64creds: String, completion: @escaping (_ authResult: (Int,String)) -> Void) {


//        WriteToLog.shared.message(stringOfText: "[getToken] token for \(whichServer) server: \(serverUrl)")
//        print("[getToken] JamfProServer.username[\(whichServer)]: \(String(describing: JamfProServer.username[whichServer]))")
//        print("[getToken] JamfProServer.password[\(whichServer)]: \(String(describing: JamfProServer.password[whichServer]?.prefix(1)))")
//        print("[getToken] JamfProServer.server[\(whichServer)]: \(String(describing: JamfProServer.source))")
//        print("[getToken] JamfProServer.server[\(whichServer)]: \(String(describing: JamfProServer.url[whichServer]))")
       
//        JamfProServer.url[whichServer] = serverUrl
        guard let serverUrl =  JamfProServer.url[whichServer] else {
            completion((404, ""))
            return
        }

        URLCache.shared.removeAllCachedResponses()

//        var tokenUrlString = "\(serverUrl)/api/v1/auth/token"

//        var apiClient = ( defaults.integer(forKey: "\(whichServer)UseApiClient") == 1 ) ? true:false
//
//        if apiClient {
//            tokenUrlString = "\(serverUrl)/api/oauth/token"
//        }
        
        var tokenUrlString = "\(serverUrl)/api/v1/auth/token"

        var apiClient = false
        if useApiClient == 1 {
            tokenUrlString = "\(serverUrl)/api/oauth/token"
            apiClient = true
        }

        tokenUrlString     = tokenUrlString.replacingOccurrences(of: "//api", with: "/api")
        //        print("[getToken] tokenUrlString: \(tokenUrlString)")

        let tokenUrl       = URL(string: "\(tokenUrlString)")
        guard let _ = URL(string: "\(tokenUrlString)") else {
            print("problem constructing the URL from \(tokenUrlString)")
            WriteToLog.shared.message(stringOfText: "[getToken] problem constructing the URL from \(tokenUrlString)")
            completion((500, "failed"))
            return
        }
        //        print("[getToken] tokenUrl: \(tokenUrl!)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"

        let (_, _, _, tokenAgeInSeconds) = timeDiff(startTime: JamfProServer.tokenCreated[whichServer] ?? Date())

        //        print("[getToken] JamfProServer.validToken[\(whichServer)]: \(String(describing: JamfProServer.validToken[whichServer]))")
        //        print("[getToken] \(whichServer) tokenAgeInSeconds: \(tokenAgeInSeconds)")
        //        print("[getToken] \(whichServer)  token exipres in: \((JamfProServer.authExpires[whichServer] ?? 30)*60)")
        //        print("[getToken] JamfProServer.currentCred[\(whichServer)]: \(String(describing: JamfProServer.currentCred[whichServer]))")

        if !( JamfProServer.validToken[whichServer] ?? false && tokenAgeInSeconds < (JamfProServer.authExpires[whichServer] ?? 0)*60 ) || (JamfProServer.currentCred[whichServer] != base64creds) {
            WriteToLog.shared.message(stringOfText: "[getToken] \(whichServer) tokenAgeInSeconds: \(tokenAgeInSeconds)")
            WriteToLog.shared.message(stringOfText: "[getToken] Attempting to retrieve token from \(String(describing: tokenUrl))")
            
            if apiClient {
                let clientId = JamfProServer.username[whichServer]
                let secret   = JamfProServer.password[whichServer]
                let clientString = "grant_type=client_credentials&client_id=\(String(describing: clientId))&client_secret=\(String(describing: secret))"
        //                print("[getToken] \(whichServer) clientString: \(clientString)")

                let requestData = clientString.data(using: .utf8)
                request.httpBody = requestData
                configuration.httpAdditionalHeaders = ["Content-Type" : "application/x-www-form-urlencoded", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
                JamfProServer.currentCred[whichServer] = clientString
            } else {
                configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64creds)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
                JamfProServer.currentCred[whichServer] = base64creds
            }
//            print("[getToken] tokenUrlString: \(tokenUrlString)")
//            print("[getToken] configuration.httpAdditionalHeaders: \(String(describing: configuration.httpAdditionalHeaders))")
            
//            print("[getToken] \(whichServer) tokenUrlString: \(tokenUrlString)")
//            print("[getToken]    \(whichServer) base64creds: \(base64creds)")
            
            let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                (data, response, error) -> Void in
                session.finishTasksAndInvalidate()
                if let httpResponse = response as? HTTPURLResponse {
                    if httpSuccess.contains(httpResponse.statusCode) {
                        if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) {
                            if let endpointJSON = json as? [String: Any] {
                                JamfProServer.accessToken[whichServer]   = apiClient ? (endpointJSON["access_token"] as? String ?? "")!:(endpointJSON["token"] as? String ?? "")!

                                JamfProServer.base64Creds[whichServer] = base64creds
                                if apiClient {
                                    JamfProServer.authExpires[whichServer] = 20 //(endpointJSON["expires_in"] as? String ?? "")!
                                } else {
                                    JamfProServer.authExpires[whichServer] = (endpointJSON["expires"] as? Double ?? 20)!
                                }
                                JamfProServer.tokenCreated[whichServer] = Date()
                                JamfProServer.validToken[whichServer]   = true
                                JamfProServer.authType[whichServer]     = "Bearer"
                                
                                //                      print("[JamfPro] result of token request: \(endpointJSON)")
                                WriteToLog.shared.message(stringOfText: "[getToken] new token created for \(serverUrl)")
                                
                                if JamfProServer.version[whichServer] == "" {
                                    // get Jamf Pro version - start
                                    getVersion(serverUrl: serverUrl, endpoint: "jamf-pro-version", apiData: [:], id: "", token: JamfProServer.accessToken[whichServer] ?? "", method: "GET") {
                                        (result: [String:Any]) in
                                        let versionString = result["version"] as! String
                                        
                                        if versionString != "" {
                                            WriteToLog.shared.message(stringOfText: "[JamfPro.getVersion] Jamf Pro Version: \(versionString)")
                                            JamfProServer.version[whichServer] = versionString
                                            let tmpArray = versionString.components(separatedBy: ".")
                                            if tmpArray.count > 2 {
                                                for i in 0...2 {
                                                    switch i {
                                                    case 0:
                                                        JamfProServer.majorVersion[whichServer] = Int(tmpArray[i]) ?? 0
                                                    case 1:
                                                        JamfProServer.minorVersion[whichServer] = Int(tmpArray[i]) ?? 0
                                                    case 2:
                                                        let tmp = tmpArray[i].components(separatedBy: "-")
                                                        JamfProServer.patchVersion[whichServer] = Int(tmp[0]) ?? 0
                                                        if tmp.count > 1 {
                                                            JamfProServer.build[whichServer] = tmp[1]
                                                        }
                                                    default:
                                                        break
                                                    }
                                                }
                                                if ( JamfProServer.majorVersion[whichServer] ?? 11 > 10 || (JamfProServer.majorVersion[whichServer] ?? 11 > 9 && JamfProServer.minorVersion[whichServer] ?? 35 > 34) ) {
                                                    JamfProServer.authType[whichServer] = "Bearer"
                                                    WriteToLog.shared.message(stringOfText: "[JamfPro.getVersion] \(serverUrl) set to use OAuth")
                                                    
                                                } else {
                                                    JamfProServer.authType[whichServer]    = "Basic"
                                                    JamfProServer.accessToken[whichServer] = base64creds
                                                    WriteToLog.shared.message(stringOfText: "[JamfPro.getVersion] \(serverUrl) set to use Basic")
                                                }
                                                completion((200, "success"))
                                                return
                                            }
                                        }
                                    }
                                    // get Jamf Pro version - end
                                } else {
                                    completion((200, "success"))
                                    return
                                }
                            } else {    // if let endpointJSON error
                                WriteToLog.shared.message(stringOfText: "[getToken] JSON error.\n\(String(describing: json))")
                                JamfProServer.validToken[whichServer] = false
                                completion((httpResponse.statusCode, "failed"))
                                return
                            }
                        } else {
                            // server down?
                            _ = Alert.shared.display(header: "", message: "Failed to get an expected response from \(String(describing: serverUrl)).", secondButton: "")
                            WriteToLog.shared.message(stringOfText: "[TokenDelegate.getToken] Failed to get an expected response from \(String(describing: serverUrl)).  Status Code: \(httpResponse.statusCode)")
                            JamfProServer.validToken[whichServer] = false
                            completion((httpResponse.statusCode, "failed"))
                            return
                        }
                    } else {    // if httpResponse.statusCode <200 or >299
                        _ = Alert.shared.display(header: "\(serverUrl)", message: "Failed to authenticate to \(serverUrl). \nStatus Code: \(httpResponse.statusCode)", secondButton: "")
                        WriteToLog.shared.message(stringOfText: "[getToken] Failed to authenticate to \(serverUrl).  Response error: \(httpResponse.statusCode)")
                        JamfProServer.validToken[whichServer] = false
                        completion((httpResponse.statusCode, "failed"))
                        return
                    }
                } else {
                    _ = Alert.shared.display(header: "\(serverUrl)", message: "Failed to connect. \nUnknown error, verify url and port.", secondButton: "")
                    WriteToLog.shared.message(stringOfText: "[getToken] token response error from \(serverUrl).  Verify url and port")
                    JamfProServer.validToken[whichServer] = false
                    completion((0, "failed"))
                    return
                }
            })
            task.resume()
        } else {
//            WriteToLog.shared.message(stringOfText: "[getToken] Use existing token from \(String(describing: tokenUrl))")
            completion((200, "success"))
            return
        }
    }
    
    func getVersion(serverUrl: String, endpoint: String, apiData: [String:Any], id: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        
        if method.lowercased() == "skip" {
//            if LogLevel.debug { WriteToLog.shared.message(stringOfText: "[Jpapi.action] skipping \(endpoint) endpoint with id \(id).") }
            let JPAPI_result = (endpoint == "auth/invalidate-token") ? "no valid token":"failed"
            completion(["JPAPI_result":JPAPI_result, "JPAPI_response":000])
            return
        }
        
        URLCache.shared.removeAllCachedResponses()
        var path = ""

        switch endpoint {
        case  "buildings", "csa/token", "icon", "jamf-pro-version", "auth/invalidate-token":
            path = "v1/\(endpoint)"
        default:
            path = "v2/\(endpoint)"
        }

        var urlString = "\(serverUrl)/api/\(path)"
        urlString     = urlString.replacingOccurrences(of: "//api", with: "/api")
        if id != "" && id != "0" {
            urlString = urlString + "/\(id)"
        }
//        print("[Jpapi] urlString: \(urlString)")
        
        let url            = URL(string: "\(urlString)")
        let configuration  = URLSessionConfiguration.default
        var request        = URLRequest(url: url!)
        switch method.lowercased() {
        case "get":
            request.httpMethod = "GET"
        case "create", "post":
            request.httpMethod = "POST"
        default:
            request.httpMethod = "PUT"
        }
        
        if apiData.count > 0 {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: apiData, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        WriteToLog.shared.message(stringOfText: "[Jpapi.action] Attempting \(method) on \(urlString).")
//        print("[Jpapi.action] Attempting \(method) on \(urlString).")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
        
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {

                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json as? [String:Any] {
                        completion(endpointJSON)
                        return
                    } else {    // if let endpointJSON error
                        if httpResponse.statusCode == 204 && endpoint == "auth/invalidate-token" {
                            completion(["JPAPI_result":"token terminated", "JPAPI_response":httpResponse.statusCode])
                        } else {
                            completion(["JPAPI_result":"failed", "JPAPI_response":httpResponse.statusCode])
                        }
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    WriteToLog.shared.message(stringOfText: "[TokenDelegate.getVersion] Response error: \(httpResponse.statusCode).")
                    completion(["JPAPI_result":"failed", "JPAPI_method":request.httpMethod ?? method, "JPAPI_response":httpResponse.statusCode, "JPAPI_server":urlString, "JPAPI_token":token])
                    return
                }
            } else {
                WriteToLog.shared.message(stringOfText: "[TokenDelegate.getVersion] GET response error.  Verify url and port.")
                completion([:])
                return
            }
        })
        task.resume()
        
    }   // func getVersion - end

}
