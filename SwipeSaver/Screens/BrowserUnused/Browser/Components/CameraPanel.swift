//
//  CameraPanel.swift
//  SwipeSaver
//
//  Created by AI Assistant on 24.10.2024.
//

import SwiftUI

/// Панель управления камерой (аналог WebViewPanel)
struct CameraPanel<T: CameraObservables>: View {
    @ObservedObject var observables: T
    
    let onSearch: (Data) -> Void
    let onClose: () -> Void
    
    private let generator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
            
            // Контент панели (меняется в зависимости от состояния)
            switch observables.state {
            case .shooting:
                shootingControls
            case .shotTaken:
                photoControls
            }
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .overlay(alignment: .topLeading, content: {
            flashButton
                .padding(.leading, .medium)
        })
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Shooting Controls
    
    private var shootingControls: some View {
        HStack(spacing: 24) {
            actionButton(icon: "xmark") {
                onClose()
            }
            captureButton
            actionButton(icon: "reload") {
                generator.impactOccurred()
                observables.switchCamera()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
    
    private var flashButton: some View {
        Button {
            generator.impactOccurred()
            observables.toggleFlash()
        } label: {
            Image(systemName: observables.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(observables.isFlashEnabled ? .yellow : .white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }
    
    private var captureButton: some View {
        Button {
            generator.impactOccurred()
            observables.takePhoto()
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 70, height: 70)
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
            }
        }
    }
    
    // MARK: - Photo Controls
    
    private var photoControls: some View {
        HStack(spacing: 24) {
            // Retake кнопка
            VStack(spacing: 8) {
                Button {
                    generator.impactOccurred()
                    observables.retakePhoto()
                } label: {
                    Text("Retake")
    //                    .font(.system(size: 11, weight: .medium))
                        .font(.tm.secondaryText)
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                
//                Text("Retake")
////                    .font(.system(size: 11, weight: .medium))
//                    .font(.tm.secondaryText)
//                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Search кнопка (акцентная)
            Button {
                generator.impactOccurred()
                if let data = observables.capturedPhotoData {
                    onSearch(data)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 70, height: 70)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
            
            // Cancel кнопка
            VStack(spacing: 8) {
                Button {
                    generator.impactOccurred()
                    onClose()
                } label: {
                    Text("Cancel")
    //                    .font(.system(size: 11, weight: .medium))
                        .font(.tm.secondaryText)
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                
//                Text("Cancel")
////                    .font(.system(size: 11, weight: .medium))
//                    .font(.tm.secondaryText)
//                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Helpers
    
    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(icon)
//                .font(.system(size: 20, weight: .semibold))
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                )
        }
    }
}
