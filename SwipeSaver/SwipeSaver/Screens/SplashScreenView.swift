//
//  SplashScreenView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.tm.accent
                .ignoresSafeArea()
            
            VStack {
                Image(systemName: "star.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(Color.tm.background)
                
                Text("SwipeSaver")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(Color.tm.title)
                    .padding(.top, 20)
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
