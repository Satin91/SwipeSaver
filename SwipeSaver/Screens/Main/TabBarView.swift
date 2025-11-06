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
    
    let items: [TabItem] = [
        .init(id: 0, icon: .home,title: "Home"),
        .init(id: 1,icon: .folder, title: "File Manager"),
        .init(id: 2, icon: .settings, title: "Settings")
    ]
    
    var body: some View {
        tabView
    }
    
    private var tabView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                SaverView()
                    .tag(0)
                
                UserFilesView()
                    .tag(1)
                
                SettingsView()
                    .tag(2)
            }
            .overlay(alignment: .bottom) {
                TabBarOverlay(
                    selectedTab: $selection,
                    items: items
                )
            }
            .ignoresSafeArea(.keyboard)
        }
        .toolbar(.hidden, for: .tabBar)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    TabBarView()
        .environmentObject(AppState())
}

