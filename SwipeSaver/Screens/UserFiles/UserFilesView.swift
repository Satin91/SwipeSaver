//
//  UserFilesView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 06.11.2025.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine

final class UserFilesViewModel: ObservableObject {
    let videoSaverInteractor = Executor.videoSaverInteractor
    private let userDefaultsObserver = Executor.userDefaultsObserver
    private var cancellables = Set<AnyCancellable>()
    @Published var folders: [VideoFolder] = []
    
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .dateNewest
    @Published var draggedVideo: SavedVideo?
    
    init() {
        // Подписываемся на изменения в UserDefaultsObserver
        self.folders = videoSaverInteractor.videoFolders
        userDefaultsObserver.$videoFolders.assign(to: &$folders)
    }
    
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
    
    func moveVideoToFolder(_ video: SavedVideo, folder: VideoFolder?) {
        videoSaverInteractor.moveVideoToFolder(video.id, toFolderId: folder?.id)
    }
    
    func getVideosInFolder(_ folder: VideoFolder) -> [SavedVideo] {
        return videoSaverInteractor.getVideosInFolder(folder)
    }
    
    func getVideosWithoutFolder() -> [SavedVideo] {
        return videoSaverInteractor.getVideosWithoutFolder()
    }
    
    func getFolderSize(_ folder: VideoFolder) -> Int64 {
        return folder.totalSize
    }
    
    func formatFolderSize(_ bytes: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

struct UserFilesView: View {
    @StateObject private var viewModel = UserFilesViewModel()
    @ObservedObject private var interactor = Executor.videoSaverInteractor
    @State private var showingSortOptions = false
    @State private var selectedFolder: VideoFolder?
    
    var body: some View {
        content
            .sheet(isPresented: $showingSortOptions) {
                sortOptionsSheet
            }
            .sheet(item: $selectedFolder) { folder in
                FolderDetailView(folder: folder, viewModel: viewModel)
            }
    }
    
    // MARK: - Compact Header
    
    var content: some View {
            VStack(spacing: .regular) {
                // Компактный Header
                compactHeaderView
                    .padding(.horizontal, .medium)
                    .padding(.top, .medium)
                
                VStack(spacing: .medium) {
                    // Поиск и сортировка
                    searchAndSortSection
                        .padding(.horizontal, .medium)
                    // Папки
                    foldersSection
                        .padding(.horizontal, .medium)
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
                .padding(.top, .regular)
            }
            .background(BackgroundGradient())
    }
    
    private var compactHeaderView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Files")
                .font(.tm.largeTitle)
                .foregroundColor(.tm.title)
            
            Text("\(viewModel.totalVideosCount) videos • \(viewModel.totalSize)")
                .font(.tm.hintText)
                .foregroundColor(.tm.subTitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Folders Section
    
    private var foldersSection: some View {
        VStack(alignment: .leading, spacing: .regular) {
            Text("Папки")
                .font(.tm.defaultTextMedium)
                .foregroundColor(.tm.title)
            
            HStack(spacing: .regular) {
                ForEach(viewModel.folders) { folder in
                    FolderCardView(
                        folder: folder,
                        onTap: {
                            selectedFolder = folder
                        },
                        onDrop: { video in
                            viewModel.moveVideoToFolder(video, folder: folder)
                        }
                    )
                    .environmentObject(viewModel)
                }
            }
        }
    }
    
    // MARK: - Search and Sort
    
    private var searchAndSortSection: some View {
        HStack(spacing: .regular) {
            TextFieldView(placeholder: "Поиск по названию или платформе", text: $viewModel.searchText, image: .search)
                .textFieldStyle(.plain)
                .foregroundColor(.tm.title)
                .autocapitalization(.none)
            Button(action: {
                showingSortOptions = true
            }) {
                Image(.sort)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.tm.accent)
                    .frame(width: 28, height: 28)
                    .padding(.regular)
                    .material(cornerRadius: Layout.Radius.regular)
//                    .cornerRadius(Layout.Radius.regular)
            }
        }
    }
    
    // MARK: - Videos List
    
    private var videosListView: some View {
        VStack(alignment: .leading, spacing: .regular) {
//            HStack {
//                if !interactor.savedVideos.isEmpty {
//                    Spacer()
//                    Button(action: {
//                        viewModel.clearAllVideos()
//                    }) {
//                        HStack(spacing: .smallExt) {
//                            Image(systemName: "trash")
//                            Text("Select")
//                        }
//                        .font(.captionTextMedium)
//                        .foregroundColor(.tm.accent)
//                    }
//                }
//            }
//            .padding(.horizontal, .medium)
            
            ScrollView {
                LazyVStack(spacing: .regular) {
                    ForEach(viewModel.filteredAndSortedVideos) { video in
                        VideoRow(video: video, onAction: {
                            viewModel.deleteVideo(video)
                        })
                        .onDrag {
                            viewModel.draggedVideo = video
                            return NSItemProvider(object: video.id.uuidString as NSString)
                        }
                        .contextMenu {
                            // Проверяем, в какой папке находится видео
                            let currentFolder = viewModel.videoSaverInteractor.getFolderForVideo(video.id)
                            
                            if currentFolder != nil {
                                Button(action: {
                                    viewModel.moveVideoToFolder(video, folder: nil)
                                }) {
                                    Label("Убрать из папки", systemImage: "folder.badge.minus")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, .medium)
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

// MARK: - Folder Detail View

struct FolderDetailView: View {
    let folder: VideoFolder
    @ObservedObject var viewModel: UserFilesViewModel
    @Environment(\.dismiss) var dismiss
    
    var folderVideos: [SavedVideo] {
        viewModel.getVideosInFolder(folder)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.tm.background
                    .ignoresSafeArea()
                
                VStack(spacing: .medium) {
                    // Заголовок
                    VStack(alignment: .leading, spacing: .small) {
                        HStack(spacing: .regular) {
                            Image(systemName: folder.iconName)
                                .font(.system(size: 32))
                                .foregroundStyle(Color(hex: folder.color))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(folder.name)
                                    .font(.tm.largeTitle)
                                    .foregroundColor(.tm.title)
                                
                                Text("\(folderVideos.count) видео")
                                    .font(.tm.hintText)
                                    .foregroundColor(.tm.subTitle)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, .medium)
                        .padding(.top, .medium)
                    }
                    
                    // Список видео
                    if folderVideos.isEmpty {
                        emptyFolderView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: .regular) {
                                ForEach(folderVideos) { video in
                                    VideoRow(video: video, onAction: {
                                        viewModel.deleteVideo(video)
                                    })
                                    .contextMenu {
                                        Button(action: {
                                            viewModel.moveVideoToFolder(video, folder: nil)
                                        }) {
                                            Label("Убрать из папки", systemImage: "folder.badge.minus")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, .medium)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.tm.accent)
                }
            }
        }
    }
    
    private var emptyFolderView: some View {
        VStack(spacing: .medium) {
            Image(systemName: folder.iconName)
                .font(.system(size: 50))
                .foregroundColor(.tm.subTitle)
            
            Text("Папка пуста")
                .font(.headline)
                .foregroundColor(.tm.title)
            
            Text("Перетащите видео в эту папку для организации файлов")
                .font(.caption)
                .foregroundColor(.tm.subTitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.extraLarge)
        .background(Color.tm.container)
        .cornerRadius(Layout.Radius.medium)
        .padding(.horizontal, .medium)
    }
}

// MARK: - Folder Card Component

struct FolderCardView: View {
    let folder: VideoFolder
    let onTap: () -> Void
    let onDrop: (SavedVideo) -> Void
    
    @State private var isTargeted = false
    @State private var scale: CGFloat = 1.0
    @EnvironmentObject var viewModel: UserFilesViewModel
    
    private var videosCount: Int {
        folder.items.count
    }
    
    private var folderDescription: String {
        if videosCount == 0 {
            return "Пусто"
        } else {
            return "\(videosCount) • \(folder.formattedSize)"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: .small) {
                // Название папки
                Text(folder.name)
                    .font(.tm.title)
                    .foregroundColor(.tm.title)
                    .lineLimit(1)
                
                Spacer()
                
                // Описание состояния
                Text(folderDescription)
                    .font(.tm.defaultText)
                    .foregroundColor(videosCount == 0 ? .tm.subTitle : .tm.accent)
            }
            .padding(.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 80)
            .material(cornerRadius: Layout.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.Radius.medium)
                    .stroke(isTargeted ? Color(hex: folder.color) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(scale)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scale)
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            guard let draggedVideo = viewModel.draggedVideo else { return false }
            
            // Тактильная отдачка
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            onDrop(draggedVideo)
            return true
        }
        .onChange(of: isTargeted) { newValue in
            scale = newValue ? 1.05 : 1.0
        }
    }
}

// MARK: - Preview

#Preview {
    UserFilesView()
}
