//
//  TokenRepo.swift
//  DenLogin
//
//  Created by Marko Dimitrijevic on 19.3.25..
//

import Foundation

final class TokenRepo {
    static let defaults = UserDefaults.standard
    static func getToken() -> String {
        let sessionId = defaults.string(forKey: "session_id")
        let accSession = defaults.string(forKey: "acc-session")
        let token = (sessionId != nil)
        ? sessionId! + "; " + (accSession ?? "")
        : (accSession ?? "")
        print("TokenRepo.token = \(token)")
        return token
    }
    static func save(token: String) {
        if token.contains("acc-session") {
            defaults.setValue(token, forKey: "acc-session")
        }
        if token.contains("session_id") {
            defaults.setValue(token, forKey: "session_id")
        }
    }
    static func removeAll() {
        defaults.setValue(nil, forKey: "acc-session")
        defaults.setValue(nil, forKey: "session_id")
    }
}


// PostsService

protocol PostsServiceProtocol {
    var requestFinalizer: RequestFinalizerProtocol { get }
    func getPosts(authorId: String, using userId: String) async throws -> [Post]
}

final class PostsService: PostsServiceProtocol {
    let requestFinalizer: RequestFinalizerProtocol
    init(requestFinalizer: RequestFinalizerProtocol) {
        self.requestFinalizer = requestFinalizer
    }
    func getPosts(authorId: String, using userId: String) async throws -> [Post] {
        
        let posts = try await getAllPosts(authorId: authorId, using: userId).votable
        
        return posts
    }
    
    
    private func getAllPosts(authorId: String, using userId: String) async throws -> [Post] {
        let endpoint =  "http://localhost:3000/" + "api/v1/content"
        let url = buildURL(path: endpoint, authorId: authorId)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let final = requestFinalizer.finalizedRequest(request: request, userId: userId)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: final)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                // Token expired, refresh and retry
                // SKIPPED !!! TODO:
                
                // Update request with new token
                let newFinal = requestFinalizer.finalizedRequest(request: request, userId: userId)
                
                let (retryData, retryResponse) = try await URLSession.shared.data(for: newFinal)
                
                guard let retryHttpResponse = retryResponse as? HTTPURLResponse, (200..<300).contains(retryHttpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                return try JSONDecoder().decode(PostsDTO.self, from: retryData).contents.compactMap(Post.init)
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            return try JSONDecoder().decode(PostsDTO.self, from: data).contents.compactMap(Post.init)
            
        } catch {
            throw error
        }

    }
    
    private func buildURL(path: String, authorId: String) -> URL {
        guard var components = URLComponents(string: path) else {
            fatalError()
        }
       
        components.queryItems = [
            URLQueryItem(name: "contentType", value: "post"),
            URLQueryItem(name: "authorId", value: authorId),
            URLQueryItem(name: "limit", value: "10"),
            URLQueryItem(name: "sortBy", value: "created"),
            URLQueryItem(name: "position", value: "0")
        ]
        
        return components.url!
    }
}

struct Post {
    let id: String
    let type: PostType
    let title: String?
    let lairName: String
    let url: String
    let canVote: Bool
    init?(dto: PostsDTO.PostDTO) {
        guard let postType = PostType(dto.contentType) else {
            return nil
        }
        id = dto.id
        type = postType
        title = dto.title
        lairName = dto.lair.displayName
        url = dto.url
        canVote = (dto.viewerData.voting.nrg.vote == 0)
    }
    
    enum PostType {
        case post
        case reply
        init?(_ contentType: String) {
            switch contentType {
            case "post": self = .post
            case "reply": self = .reply
            default: return nil
            }
        }
    }
}
extension [Post] {
    var votable: [Post] {
        self.filter { $0.canVote }
    }
}

import Foundation

// Root model
struct PostsDTO: Codable {
    let count: Int
    let nextOffset: Int
    let contents: [PostDTO]
    
    // Post content
    struct PostDTO: Codable {
        let id: String
        let created: Int
        let createdNano: Int64
        let modified: Int
        let modifiedNano: Int64
        let contentType: String
        let content: String
        let dcTransactionId: String
        let renderType: String
        let author: Author
        let anonymous: Bool
        let authorBanned: Bool
        let lair: Lair
        let stats: Stats
        let tags: [Tag]
        let viewerData: ViewerData
        let published: Bool
        let sticky: Bool
        let edited: Bool
        let editable: Bool
        let boosted: Bool
        let url: String
        let image: Image?
        let media: [Media]?
        let depth: Int
        let blocked: Bool
        let deleted: Bool
        let deletedBy: String
        let title: String?
        
        // Author details
        struct Author: Codable {
            let id: String
            let registered: Int
            let displayName: String
            let description: String
            let flagImgId: String
            let avatarImgId: String
            let siteReputation: Int
            let lairReputation: Int
            let isBot: Bool
        }

        // Lair details
        struct Lair: Codable {
            let id: String
            let name: String
            let displayName: String
        }

        // Stats details
        struct Stats: Codable {
            let score: Int
            let adjScore: Int
            let views: Int
            let replyCount: Int
            let trendingScoreMultiplier: Double
            let weightedScore: Double
            let mtrBoost: String
            let tip: Tip
            
            // Tip details
            struct Tip: Codable {
                let mtr: Bool
                let lor: Bool
                let lot: Bool
            }
        }

        // Tag details
        struct Tag: Codable {
            let id: String
            let tag: String
            let created: Int64
            let filterable: Bool
            let ageRestriction: Bool
            let userCreated: Bool
            let consensus: Int
            let addedByAuthor: Bool
            let addedByAuthUser: Bool
        }

        // Viewer data
        struct ViewerData: Codable {
            let voting: Voting
            
            // Voting details
            struct Voting: Codable {
                let nrg: Vote
                let tag: [String]
            }
            
            // Vote details
            struct Vote: Codable {
                let vote: Int
                let initialVote: Int
            }
        }

        // Image details
        struct Image: Codable {
            let id: String
        }

        // Media details
        struct Media: Codable {
            let image: String
        }

    }

}

