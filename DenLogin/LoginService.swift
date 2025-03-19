//
//  LoginService.swift
//  DenLogin
//
//  Created by Marko Dimitrijevic on 19.3.25..
//

import Foundation

protocol LoginServiceProtocol {
    func getToken() async throws -> String
}

struct LoginService: LoginServiceProtocol {
    
    let requestFinalizer: RequestFinalizer
    
    func getToken() async throws -> String {
        let endpoint = "http://localhost:3000/login"
        let url = URL(string: endpoint)! // Adjust the URL accordingly
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let requestBody: [String: Any] = [
            "username": "robkeg99",
            "password": "Roby1999"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        request = requestFinalizer.finalizedRequest(request: request, userId: "")
        
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard let cookie = httpResponse.allHeaderFields["Set-Cookie"] as? String else {
            throw URLError(.badServerResponse)
        }
        
        guard let token = extractSessionToken(from: cookie) else {
            throw URLError(.badServerResponse)
        }
        
        TokenRepo.save(token: token)
        
        return token
    }
    
    private func extractSessionToken(from cookie: String) -> String? {
        let pattern = #"(acc-session=[a-f0-9\-]+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: cookie, options: [], range: NSRange(location: 0, length: cookie.utf16.count)) {
            
            if let range = Range(match.range(at: 1), in: cookie) {
                return String(cookie[range])
            }
        }
        
        return nil
    }
}
