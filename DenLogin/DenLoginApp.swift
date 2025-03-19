//
//  DenLoginApp.swift
//  DenLogin
//
//  Created by Marko Dimitrijevic on 19.3.25..
//

import SwiftUI

@main
struct DenLoginApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: LoginVM())
        }
    }
}
