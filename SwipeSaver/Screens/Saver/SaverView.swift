//
//  SaverView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//

import SwiftUI

final class SaverViewModel: ObservableObject {
    let videoSaverInteractor = Executor.videoSaverInteractor
    
    @Published var urlText: String = ""
    
    init() {
    urlText = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
    }
    
    func uploadVideo() {
        guard !urlText.isEmpty else { return }
        Task { @MainActor in
//            await videoSaverInteractor.downloadSocialVideo(from: urlText)
            await videoSaverInteractor.downloadVideo(from: urlText)
        }
    }
}

struct SaverView: View {
    @StateObject private var viewModel = SaverViewModel()
    @ObservedObject private var interactor = Executor.videoSaverInteractor
    
    var body: some View {
        VStack(spacing: .medium) {
            // Header с информацией
            headerView
            
            // Поле ввода URL
            urlInputSection
            
            // Кнопка загрузки
            downloadButton
            
            // Прогресс загрузки
            if interactor.isDownloading {
                progressView
            }
            
            // Ошибка
            if let errorMessage = interactor.errorMessage {
                errorView(message: errorMessage)
            }
            
            // Список сохраненных видео
            savedVideosSection
        }
        .padding(.horizontal, .medium)
        .padding(.top, .medium)
        .background(Color.tm.background.ignoresSafeArea())
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: .regular) {
            HStack {
                VStack(alignment: .leading, spacing: .smallExt) {
                    Text("Сохранено видео")
                        .font(.caption)
                        .foregroundColor(.tm.subTitle)
                    
                    Text("\(interactor.savedVideos.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.tm.title)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: .smallExt) {
                    Text("Общий размер")
                        .font(.caption)
                        .foregroundColor(.tm.subTitle)
                    
                    Text(interactor.getFormattedTotalSize())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.tm.accent)
                }
            }
            .padding(.medium)
            .background(Color.tm.container)
            .cornerRadius(Layout.Radius.medium)
        }
    }
    
    // MARK: - URL Input
    
    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: .regular) {
            Text("Вставьте ссылку")
                .font(.headline)
                .foregroundColor(.tm.title)
            
            HStack(spacing: .regular) {
                Image(systemName: "link")
                    .foregroundColor(.tm.accent)
                    .font(.system(size: 20))
                
                TextField("https://youtube.com/watch?v=...", text: $viewModel.urlText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.tm.title)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .disabled(interactor.isDownloading)
                
                if !viewModel.urlText.isEmpty {
                    Button(action: {
                        viewModel.urlText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.tm.subTitle)
                    }
                }
            }
            .padding(.medium)
            .background(Color.tm.container)
            .cornerRadius(Layout.Radius.regular)
            
            // Подсказка о поддерживаемых платформах
            HStack(spacing: .smallExt) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.tm.accent)
                
                Text("Поддерживается: YouTube, TikTok, Instagram, прямые ссылки на видео")
                    .font(.caption)
                    .foregroundColor(.tm.subTitle)
            }
        }
    }
    
    // MARK: - Download Button
    
    private var downloadButton: some View {
        Button(action: {
            viewModel.uploadVideo()
        }) {
            HStack(spacing: .regular) {
                Image(systemName: interactor.isDownloading ? "arrow.down.circle.fill" : "arrow.down.circle")
                    .font(.system(size: 20))
                
                Text(interactor.isDownloading ? "Загрузка..." : "Загрузить видео")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.medium)
            .background(viewModel.urlText.isEmpty || interactor.isDownloading ? Color.tm.inactive : Color.tm.accent)
            .foregroundColor(.white)
            .cornerRadius(Layout.Radius.regular)
        }
        .disabled(viewModel.urlText.isEmpty || interactor.isDownloading)
    }
    
    // MARK: - Progress View
    
    private var progressView: some View {
        VStack(spacing: .regular) {
            HStack {
                Text("Загрузка")
                    .font(.subheadline)
                    .foregroundColor(.tm.title)
                
                Spacer()
                
                Text("\(Int(interactor.downloadProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.tm.accent)
            }
            
            ProgressView(value: interactor.downloadProgress)
                .tint(.tm.accent)
        }
        .padding(.medium)
        .background(Color.tm.container)
        .cornerRadius(Layout.Radius.regular)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        HStack(spacing: .regular) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.tm.error)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.tm.title)
            
            Spacer()
            
            Button(action: {
                interactor.errorMessage = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.tm.subTitle)
            }
        }
        .padding(.medium)
        .background(Color.tm.error.opacity(0.1))
        .cornerRadius(Layout.Radius.regular)
    }
    
    // MARK: - Saved Videos
    
    private var savedVideosSection: some View {
        VStack(alignment: .leading, spacing: .regular) {
            HStack {
                Text("Сохраненные видео")
                    .font(.headline)
                    .foregroundColor(.tm.title)
                
                Spacer()
                
                if !interactor.savedVideos.isEmpty {
                    Button(action: {
                        interactor.clearAllVideos()
                    }) {
                        Text("Очистить все")
                            .font(.caption)
                            .foregroundColor(.tm.error)
                    }
                }
            }
            
            if interactor.savedVideos.isEmpty {
                emptyStateView
            } else {
                videosList
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: .medium) {
            Image(systemName: "film.stack")
                .font(.system(size: 50))
                .foregroundColor(.tm.subTitle)
            
            Text("Нет сохраненных видео")
                .font(.headline)
                .foregroundColor(.tm.title)
            
            Text("Вставьте ссылку и нажмите \"Загрузить\"")
                .font(.caption)
                .foregroundColor(.tm.subTitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.extraLarge)
        .background(Color.tm.container)
        .cornerRadius(Layout.Radius.medium)
    }
    
    private var videosList: some View {
        ScrollView {
            LazyVStack(spacing: .regular) {
                ForEach(interactor.savedVideos) { video in
                    VideoRow(video: video, onDelete: {
                        interactor.deleteSavedVideo(video)
                    })
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SaverView()
}

