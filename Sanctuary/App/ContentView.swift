//
//  ContentView.swift
//  Sanctuary
//
//  Main content view with authentication routing
//

import SwiftUI

struct ContentView: View {
    @Environment(DependencyContainer.self) private var dependencies
    
    var body: some View {
        Group {
            if dependencies.isAuthenticated {
                DashboardView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.smooth, value: dependencies.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environment(DependencyContainer.shared)
}
