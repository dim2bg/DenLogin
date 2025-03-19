//
//  ContentView.swift
//  DenLogin
//
//  Created by Marko Dimitrijevic on 19.3.25..
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: LoginVM
    var body: some View {
        VStack {
            Text("Token:")
            Text(viewModel.token)
            Spacer()
            Text("Number of user's posts:")
            Text(viewModel.posts.count)
            Spacer()
            Button("Remove all tokens") {
                TokenRepo.removeAll()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView(viewModel: LoginVM())
}

final class LoginVM: ObservableObject {
    @Published var token = ""
    @Published var posts = [Post]()
    let service = LoginService(requestFinalizer: RequestFinalizer())
    let postsService = PostsService(requestFinalizer: RequestFinalizer())
    init() {
        Task {
            await provideToken()
            await providePosts()
        }
    }
    
    @MainActor
    private func provideToken() async {
        do {
            token = try await service.getToken()
        } catch {
            print("error fetching token...")
            print("\(error)")
        }
        
    }
    
    @MainActor
    private func providePosts() async {
        do {
            posts = try await postsService.getPosts(authorId: "5f19927c25b042b1849b27407ec1641b", using: "")
        } catch {
            print("error fetching posts...")
            print("\(error)")
        }
        
    }
}

extension Text {
    init(_ value: Int) {
        self = Text("\(value)")
    }
}
