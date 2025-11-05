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
    
    var body: some View {
        ZStack {
            Color.tm.background
                .ignoresSafeArea()
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
