//
//  BeReal_TechnicalTestApp.swift
//  BeReal-TechnicalTest
//
//  Created by Louis Fournier on 3/13/25.
//

import SwiftUI

@main
struct BeReal_TechnicalTestApp: App {
    // Create a shared instance of the data service
    @StateObject private var storyDataService = StoryDataService()
    
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(storyDataService)
        }
    }
}
