//
//  USC_Football_TrackerApp.swift
//  USC Football Tracker
//
//  Created by Cody Tran on 7/24/26.
//

import SwiftUI

@main
struct USC_Football_TrackerApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Seasons", systemImage: "calendar")
                    }
                
                PredictorView()
                    .tabItem {
                        Label("Predictor", systemImage: "chart.line.uptrend.xyaxis")
                    }
                
                
                AccoladesView()
                    .tabItem {
                        Label("Accolades", systemImage: "trophy.fill")
                    }
                
                AboutView()
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
        }
    }
}


#Preview {
    TabView {
        ContentView()
            .tabItem {
                Label("Seasons", systemImage: "calendar")
            }

        PredictorView()
            .tabItem {
                Label("Predictor", systemImage: "chart.line.uptrend.xyaxis")
            }


        AccoladesView()
            .tabItem {
                Label("Accolades", systemImage: "trophy.fill")
            }

        AboutView()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
    }
}
