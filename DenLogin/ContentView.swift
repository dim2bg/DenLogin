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
        }
        .padding()
    }
}

#Preview {
    ContentView(viewModel: LoginVM())
}

final class LoginVM: ObservableObject {
    @Published var token = ""
    let service = LoginService()
    init() {
        Task {
            await provideToken()
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
}


