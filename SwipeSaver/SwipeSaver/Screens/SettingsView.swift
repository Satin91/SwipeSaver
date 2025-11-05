//
//  SettingsView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    private let appInteractor = Executor.appInteractor
    private let purchaseRepository = Executor.purchaseRepository
    
    var body: some View {
        ZStack {
            Color.tm.background
                .ignoresSafeArea()
            
            List {
                Section("Subscription") {
                    HStack {
                        Text("Status")
                            .foregroundStyle(Color.tm.title)
                        Spacer()
                        Text(purchaseRepository.isSubscriptionActive() ? "Active ✅" : "Inactive ❌")
                            .foregroundStyle(Color.tm.subTitle)
                    }
                }
                .listRowBackground(Color.tm.container)
                
                Section("Настройки") {
                    Toggle("Dark Mode", isOn: $appInteractor.appSettings.isDarkMode)
                        .tint(Color.tm.accent)
                    Toggle("Notifications", isOn: $appInteractor.appSettings.notificationsEnabled)
                        .tint(Color.tm.accent)
                }
                .listRowBackground(Color.tm.container)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
