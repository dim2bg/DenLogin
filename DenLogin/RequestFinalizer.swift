//
//  RequestFinalizer.swift
//  DenLogin
//
//  Created by Marko Dimitrijevic on 19.3.25..
//

import Foundation

protocol RequestFinalizerProtocol {
    func finalizedRequest(request: URLRequest, userId: String) -> URLRequest
}

final class RequestFinalizer: RequestFinalizerProtocol {
    
    func finalizedRequest(request: URLRequest, userId: String) -> URLRequest {
        
        var finalized = request
        
        let userAgent = "PostmanRuntime/7.43.2"
        finalized.setValue("", forHTTPHeaderField: "Set-Cookie")
        finalized.setValue(TokenRepo.getToken(), forHTTPHeaderField: "Cookie")
        finalized.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        finalized.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return finalized
    }
}
