//
//  ContentView.swift
//  DropMe
//
//  Created by Md Akhlak on 13/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var dashboardViewModel: DashboardViewModel
    @StateObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "map")
                }
            
            ProfileView(viewModel: profileViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    ContentView(
        dashboardViewModel: DashboardViewModel(locationService: LocationService()),
        profileViewModel: ProfileViewModel()
    )
}
