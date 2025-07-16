//
//  DropMeApp.swift
//  DropMe
//
//  Created by Md Akhlak on 13/7/25.
//

import SwiftUI

@main
struct DropMeApp: App {
    let locationService = LocationService()
    let routeOptimizationService = RouteOptimizationService()
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                dashboardViewModel: DashboardViewModel(
                    locationService: locationService,
                    routeOptimizationService: routeOptimizationService
                )
            )
        }
    }
}
