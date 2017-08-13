//
//  NetworkService.swift
//  Receiver
//
//  Created by Pavel Kazantsev on 8/13/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import Foundation

private let unlockTheDoorUrlStr = "https://api.getkisi.com/locks/5124/access"
private let authKey = "75388d1d1ff0dff6b7b04a7d5162cc6c"

/// The class combines API and the network layer
/// In real app it should be separated classes
class NetworkService {

    func unlockTheDoor(_ callback: @escaping (String?) -> Void) {
        post(url: URL(string: unlockTheDoorUrlStr)!,
             headers: ["Authorization": "KISI-LINK \(authKey)"], callback: callback)
    }

    private func post(url: URL, data: [String: Any]? = nil, headers: [String: String]? = nil, callback: @escaping (String?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        let task = URLSession.shared.dataTask(with: request) { (data, resp, err) in
            if let error = err {
                print("POST error: \(error)")
                callback(nil)
                return
            }
            do {
                if let respData = data, let json = try JSONSerialization.jsonObject(with: respData, options: []) as? [String: Any] {
                    print("Response json: \(json)")
                    callback(json["message"] as? String)
                } else {
                    callback(nil)
                }
            } catch {
                print("JSON error: \(error)")
                callback(nil)
            }
        }
        task.resume()
    }

}
