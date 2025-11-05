//
//  TabBarView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

/// Главный TabBar приложения
struct TabBarView: View {
    @State private var selection: Int = 0
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        tabView
    }
    
    private var tabView: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { 
                    Label("Home", systemImage: "house.fill") 
                }
                .tag(0)
            
            ExampleView()
                .tabItem { 
                    Label("Example", systemImage: "star.fill") 
                }
                .tag(1)
            
            SettingsView()
                .tabItem { 
                    Label("Settings", systemImage: "gear") 
                }
                .tag(2)
        }
        .tint(.blue)
    }
}

#Preview {
    TabBarView()
        .environmentObject(AppState())
}

