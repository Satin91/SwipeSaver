//
//  UserFilesView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 06.11.2025.
//

import SwiftUI

final class UserFilesViewModel: ObservableObject {
    let videoSaverInteractor = Executor.videoSaverInteractor
    
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .dateNewest
    
    enum SortOption: String, CaseIterable {
        case dateNewest = "Сначала новые"
        case dateOldest = "Сначала старые"
        case sizeDescending = "По размеру (убыв.)"
        case sizeAscending = "По размеру (возр.)"
        case nameAZ = "По имени (А-Я)"
        case nameZA = "По имени (Я-А)"
        
        var icon: String {
            switch self {
            case .dateNewest, .dateOldest:
                return "calendar"
            case .sizeDescending, .sizeAscending:
                return "arrow.up.arrow.down"
            case .nameAZ, .nameZA:
                return "textformat"
            }
        }
    }
    
    var filteredAndSortedVideos: [SavedVideo] {
        var videos = videoSaverInteractor.savedVideos
        
        // Фильтрация по поиску
        if !searchText.isEmpty {
            videos = videos.filter { video in
                video.fileName.localizedCaseInsensitiveContains(searchText) ||
                video.platform.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Сортировка
        switch sortOption {
        case .dateNewest:
            videos.sort { $0.dateAdded > $1.dateAdded }
        case .dateOldest:
            videos.sort { $0.dateAdded < $1.dateAdded }
        case .sizeDescending:
            videos.sort { $0.fileSize > $1.fileSize }
        case .sizeAscending:
            videos.sort { $0.fileSize < $1.fileSize }
        case .nameAZ:
            videos.sort { $0.fileName.localizedCompare($1.fileName) == .orderedAscending }
        case .nameZA:
            videos.sort { $0.fileName.localizedCompare($1.fileName) == .orderedDescending }
        }
        
        return videos
    }
    
    var totalVideosCount: Int {
        return videoSaverInteractor.savedVideos.count
    }
    
    var totalSize: String {
        return videoSaverInteractor.getFormattedTotalSize()
    }
    
    func deleteVideo(_ video: SavedVideo) {
        videoSaverInteractor.deleteSavedVideo(video)
    }
    
    func clearAllVideos() {
        videoSaverInteractor.clearAllVideos()
    }
}

struct UserFilesView: View {
    @StateObject private var viewModel = UserFilesViewModel()
    @ObservedObject private var interactor = Executor.videoSaverInteractor
    @State private var showingSortOptions = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.tm.background
                    .ignoresSafeArea()
                
                VStack(spacing: .medium) {
                    // Статистика
                    statisticsView
                    
                    // Поиск и сортировка
                    searchAndSortSection
                    // Список видео
                    if viewModel.filteredAndSortedVideos.isEmpty {
                        if viewModel.searchText.isEmpty {
                            emptyStateView
                        } else {
                            searchEmptyStateView
                        }
                    } else {
                        videosListView
                    }
                }
                .padding(.horizontal, .medium)
                .padding(.top, .medium)
            }
            .navigationTitle("Мои файлы")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSortOptions) {
                sortOptionsSheet
            }
        }
    }
    
    // MARK: - Statistics
    
    private var statisticsView: some View {
        HStack(spacing: .medium) {
            // Количество видео
            StatCard(
                title: "Всего видео",
                value: "\(viewModel.totalVideosCount)",
                icon: "film.stack",
                color: .tm.accent
            )
            
            // Общий размер
            StatCard(
                title: "Общий размер",
                value: viewModel.totalSize,
                icon: "internaldrive",
                color: .tm.accentSecondary
            )
        }
    }
    
    // MARK: - Search and Sort
    
    private var searchAndSortSection: some View {
        HStack(spacing: .regular) {
            // Поиск
            HStack(spacing: .regular) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.tm.subTitle)
                    .font(.system(size: 16))
                
                TextField("Поиск по названию или платформе", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.tm.title)
                    .autocapitalization(.none)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.tm.subTitle)
                    }
                }
            }
            .padding(.medium)
            .background(Color.tm.container)
            .cornerRadius(Layout.Radius.regular)
            
            // Кнопка сортировки
            Button(action: {
                showingSortOptions = true
            }) {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.tm.accent)
                    .frame(width: 44, height: 44)
                    .background(Color.tm.container)
                    .cornerRadius(Layout.Radius.regular)
            }
        }
    }
    
    // MARK: - Videos List
    
    private var videosListView: some View {
        VStack(alignment: .leading, spacing: .regular) {
            HStack {
                Text("Файлы (\(viewModel.filteredAndSortedVideos.count))")
                    .font(.headline)
                    .foregroundColor(.tm.title)
                
                Spacer()
                
                if !interactor.savedVideos.isEmpty {
                    Button(action: {
                        viewModel.clearAllVideos()
                    }) {
                        HStack(spacing: .smallExt) {
                            Image(systemName: "trash")
                            Text("Очистить")
                        }
                        .font(.caption)
                        .foregroundColor(.tm.error)
                    }
                }
            }
            
            ScrollView {
                LazyVStack(spacing: .regular) {
                    ForEach(viewModel.filteredAndSortedVideos) { video in
                        VideoRow(video: video, onDelete: {
                            viewModel.deleteVideo(video)
                        })
                    }
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyStateView: some View {
        VStack(spacing: .medium) {
            Image(systemName: "folder")
                .font(.system(size: 50))
                .foregroundColor(.tm.subTitle)
            
            Text("Нет сохраненных файлов")
                .font(.headline)
                .foregroundColor(.tm.title)
            
            Text("Загрузите видео в разделе \"Загрузка\"")
                .font(.caption)
                .foregroundColor(.tm.subTitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.extraLarge)
        .background(Color.tm.container)
        .cornerRadius(Layout.Radius.medium)
    }
    
    private var searchEmptyStateView: some View {
        VStack(spacing: .medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.tm.subTitle)
            
            Text("Ничего не найдено")
                .font(.headline)
                .foregroundColor(.tm.title)
            
            Text("Попробуйте изменить поисковый запрос")
                .font(.caption)
                .foregroundColor(.tm.subTitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.extraLarge)
        .background(Color.tm.container)
        .cornerRadius(Layout.Radius.medium)
    }
    
    // MARK: - Sort Options Sheet
    
    private var sortOptionsSheet: some View {
        NavigationView {
            List {
                ForEach(UserFilesViewModel.SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        viewModel.sortOption = option
                        showingSortOptions = false
                    }) {
                        HStack {
                            Image(systemName: option.icon)
                                .foregroundColor(.tm.accent)
                                .frame(width: 24)
                            
                            Text(option.rawValue)
                                .foregroundColor(.tm.title)
                            
                            Spacer()
                            
                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.tm.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Сортировка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        showingSortOptions = false
                    }
                    .foregroundColor(.tm.accent)
                }
            }
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: .regular) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .cornerRadius(Layout.Radius.regular)
            
            VStack(alignment: .leading, spacing: .smallExt) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.tm.subTitle)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.tm.title)
            }
            
            Spacer()
        }
        .padding(.medium)
        .background(Color.tm.container)
        .cornerRadius(Layout.Radius.regular)
    }
}

// MARK: - Preview

#Preview {
    UserFilesView()
}
