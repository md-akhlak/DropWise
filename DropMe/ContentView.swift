//
//  ContentView.swift
//  DropMe
//
//  Created by Md Akhlak on 13/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var dashboardViewModel: DashboardViewModel
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                DashboardView(viewModel: dashboardViewModel)
            }
        }
        .onAppear {
            // Hide splash after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showSplash = false }
            }
        }
    }
}

#Preview {
    ContentView(
        dashboardViewModel: DashboardViewModel(locationService: LocationService())
    )
}
