//
//  HomeView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: Coordinator
    private let purchaseRepository = Executor.purchaseRepository
    
    var body: some View {
        ZStack {
            Color.tm.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Home Screen")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(Color.tm.title)
                
                Text("Subscription: \(purchaseRepository.isSubscriptionActive() ? "Active ✅" : "Inactive ❌")")
                    .font(.subheadline)
                    .foregroundStyle(Color.tm.subTitle)
                
                Button("Navigate to Example") {
                    coordinator.push(to: .example)
                }
                .buttonStyle(.bordered)
                .tint(Color.tm.accent)
                
                Button("Check Premium Access") {
                    Task {
                        await Executor.appInteractor.checkPremiumAccess(showPaywall: $appState.isShowPaywall) {
                            print("Has premium access!")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tm.accentSecondary)
            }
            .padding()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .environmentObject(Coordinator())
}
