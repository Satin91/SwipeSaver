//
//  ExampleView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

struct ExampleView: View {
    @StateObject private var viewModel = ExampleViewModel()
    @EnvironmentObject var coordinator: Coordinator
    
    var body: some View {
        ZStack {
            Color.tm.background
                .ignoresSafeArea()
            
            content
        }
        .navigationTitle("Example")
        .navigationBarTitleDisplayMode(.inline)
        .loader(isLoading: $viewModel.isLoading, message: "Loading...")
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .task {
            await viewModel.loadData()
        }
    }
    
    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Example Screen")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(Color.tm.title)
                
                Text(viewModel.data)
                    .font(.subheadline)
                    .foregroundStyle(Color.tm.subTitle)
                
                GlassButton(title: "Refresh", icon: "arrow.clockwise") {
                    viewModel.refreshData()
                }
                .padding(.horizontal, 20)
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        ExampleView()
            .environmentObject(Coordinator())
    }
}
