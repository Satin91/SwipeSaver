//
//  BrowserFavoritesView.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 28.10.2025.
//

import SwiftUI

struct FavoritesView: View {
    let onTapFavorite: (URL?) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FavoritesViewModel()
    @State private var isContentLoaded = false
    
    init(onTapFavorite: @escaping (URL?) -> Void) {
        self.onTapFavorite = onTapFavorite
    }
    
    var body: some View {
        content
            .onAppear {
                viewModel.selectFirstGroupIfNeeded()
                
                // Launch appearance animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        isContentLoaded = true
                    }
                }
            }
    }
    
    var content: some View {
            VStack(spacing: 0) {
                // Header
                HeaderView(
                    title: "Favorites",
                    isContentLoaded: isContentLoaded,
                    onClose: {
                        dismiss()
                    }
                ) {
                    // Group chips scroll view
                    groupChipsScrollView
                }
                
                // Content area
                if let selectedGroup = viewModel.selectedGroup {
                    favoritesContent(for: selectedGroup)
                } else {
                    emptyState
                }
            }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $viewModel.showAddGroupSheet) {
            addGroupSheet
                .presentationDetents([.height(400)])
                .presentationDragIndicator(.visible)
        }
        .infoAlert(
            alert: $viewModel.deleteAlert,
            onDelete: {
                viewModel.confirmDeleteGroup()
            }
        )
        .background(Color.tm.background.ignoresSafeArea(.all))
    }
    
    // MARK: - Components
    
    private var groupChipsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" chip - always first
                FavoriteGroupChip(
                    group: viewModel.allGroup,
                    isSelected: viewModel.selectedGroup?.id == viewModel.allGroup.id,
                    onTap: {
                        viewModel.selectGroup(viewModel.allGroup)
                    },
                    onEdit: {
                        // "All" cannot be edited - do nothing
                    },
                    onDelete: {
                        // "All" cannot be deleted - alert will be shown from ViewModel
                        viewModel.deleteGroup(viewModel.allGroup)
                    },
                    showContextMenu: false // Don't show context menu for "All"
                )
                
                ForEach(viewModel.userDefaultsObserver.favoriteGroups) { group in
                    FavoriteGroupChip(
                        group: group,
                        isSelected: viewModel.selectedGroup?.id == group.id,
                        onTap: {
                            viewModel.selectGroup(group)
                        },
                        onEdit: {
                            viewModel.startEditingGroup(group)
                        },
                        onDelete: {
                            viewModel.deleteGroup(group)
                        },
                        showContextMenu: viewModel.canEditGroup(group) || viewModel.canDeleteGroup(group)
                    )
                }
                
                // Add new group button
                addGroupButton
            }
            .padding(.horizontal, 20)
        }
        .opacity(isContentLoaded ? 1 : 0)
        .offset(y: isContentLoaded ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: isContentLoaded)
    }
    
    private var addGroupButton: some View {
        Button(action: {
            viewModel.openAddGroupSheet()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                Text("New")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.tm.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.tm.accent.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                Color.tm.accent.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func favoritesContent(for group: FavoriteGroup) -> some View {
        VStack {
            if group.favorites.isEmpty {
                emptyGroupState(for: group)
            } else {
                favoritesList(for: group)
            }
        }
    }
    
    private func favoritesList(for group: FavoriteGroup) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(group.favorites) { favorite in
                    FavoriteItemRow(
                        item: favorite,
                        groupColor: viewModel.getColorForFavorite(favorite, in: group),
                        currentGroup: group,
                        availableGroups: viewModel.getAvailableGroupsForMove(
                            currentGroup: viewModel.getGroupForFavorite(favorite) ?? group
                        ),
                        onTap: {
                            onTapFavorite(URL(string: favorite.url))
                            dismiss()
                        },
                        onDelete: {
                            if let sourceGroup = viewModel.getGroupForFavorite(favorite) {
                                viewModel.deleteFavorite(favorite, from: sourceGroup)
                            }
                        },
                        onMove: { targetGroup in
                            if let sourceGroup = viewModel.getGroupForFavorite(favorite) {
                                viewModel.moveFavorite(favorite, from: sourceGroup, to: targetGroup)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    private func emptyGroupState(for group: FavoriteGroup) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(group.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                group.color,
                                group.color.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("No favorites yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.tm.title.opacity(0.8))
            
            Text("Add your favorite pages to this group")
                .font(.system(size: 15))
                .foregroundColor(.tm.subTitle.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 60))
                .foregroundColor(.tm.subTitle.opacity(0.3))
            
            Text("No groups")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.tm.title.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var backgroundGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.tm.background,
                    Color.tm.backgroundSecondary.opacity(0.8),
                    Color.tm.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Accent spot in top-right corner
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tm.accent.opacity(0.12),
                            Color.tm.accent.opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 150, y: -150)
                .blur(radius: 40)
            
            // Secondary accent in center-left
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tm.accentSecondary.opacity(0.1),
                            Color.tm.accentSecondary.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 300)
                .offset(x: -100, y: 50)
                .blur(radius: 35)
            
            // Third spot at the bottom
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tm.accent.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 50, y: 300)
                .blur(radius: 45)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Add Group Sheet
    
    private var addGroupSheet: some View {
        AddGroupSheet(
            groupName: $viewModel.groupName,
            selectedColor: $viewModel.selectedColor,
            availableColors: viewModel.availableColors,
            isEditMode: viewModel.editingGroup != nil,
            onCreate: { viewModel.saveGroup() }
        )
    }
}

// MARK: - Add Group Sheet

struct AddGroupSheet: View {
    @Binding var groupName: String
    @Binding var selectedColor: String
    let availableColors: [String]
    let isEditMode: Bool
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            sheetHeader
            
            // Form content
            VStack(spacing: 20) {
                nameInputField
                colorPickerSection
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Create button
            createButton
        }
        .background(Color.tm.background.ignoresSafeArea(.all))
    }
    
    // MARK: - Components
    
    private var sheetHeader: some View {
        HStack {
            Text(isEditMode ? "Edit Group" : "New Group")
                .font(.tm.largeTitle)
                .foregroundColor(.tm.title)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 28)
    }
    
    private var nameInputField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name")
                .font(.hintTextMedium)
                .foregroundColor(.tm.subTitle.opacity(0.8))
                .padding(.leading, 4)
            
            
            TextFieldView(placeholder: "e.g., Work", text: $groupName, image: .search)
                .font(.system(size: 15, weight: .regular))
                .autocorrectionDisabled(true)
        }
    }
    
    private var inputFieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.tm.container.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.tm.border, lineWidth: 1)
            )
            .shadow(color: Color.tm.shadowColor.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Group Color")
                .font(.hintTextMedium)
                .foregroundColor(.tm.subTitle.opacity(0.8))
                .padding(.leading, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(availableColors.enumerated()), id: \.element) { index, colorHex in
                        ColorCircleButton(
                            colorHex: colorHex,
                            isSelected: selectedColor == colorHex,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedColor = colorHex
                                }
                            }
                        )
                        .padding(.horizontal, 8)
                        
                        // Divider between circles
                        if index < availableColors.count - 1 {
                            Divider()
                                .frame(height: 24)
                                .background(Color.tm.subTitle.opacity(0.15))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
            }
            .background(inputFieldBackground)
        }
    }
    
    private var createButton: some View {
        Button(action: onCreate) {
            HStack(spacing: 10) {
                // Color indicator
                Circle()
                    .fill(Color(hex: selectedColor))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.tm.border.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: selectedColor).opacity(0.5), radius: 6)
                
                Text(isEditMode ? "Save" : "Create Group")
                    .font(.system(size: 17, weight: .regular))
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .regular))
            }
            .foregroundColor(.tm.title)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.tm.container.opacity(0.9))
            )
        }
        .buttonStyle(.plain)
        .opacity(groupName.isEmpty ? 0.65 : 1)
        .disabled(groupName.isEmpty)
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
    
    private var sheetBackgroundGradient: some View {
        ZStack {
            // Multi-layer base gradient
            LinearGradient(
                colors: [
                    Color.tm.background,
                    Color.tm.backgroundSecondary.opacity(0.7),
                    Color.tm.background.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Top-left accent - bright spot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tm.accent.opacity(0.2),
                            Color.tm.accent.opacity(0.12),
                            Color.tm.accent.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: -120, y: -80)
                .blur(radius: 40)
            
            // Right spot - accentSecondary
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tm.accentSecondary.opacity(0.18),
                            Color.tm.accentSecondary.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 240)
                .offset(x: 140, y: 60)
                .blur(radius: 35)
            
            // Bottom spot - mixed
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tm.accent.opacity(0.15),
                            Color.tm.accentSecondary.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .offset(x: -80, y: 220)
                .blur(radius: 38)
            
            // Additional small spot for dynamics
            RoundedRectangle(cornerRadius: 80)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.tm.accent.opacity(0.1),
                            Color.tm.accentSecondary.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 140)
                .rotationEffect(.degrees(30))
                .offset(x: 100, y: 180)
                .blur(radius: 30)
        }
        .frame(maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

// MARK: - Color Circle Button

struct ColorCircleButton: View {
    let colorHex: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Selection ring (outer ring)
                if isSelected {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(hex: colorHex).opacity(0.5),
                                    Color(hex: colorHex).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 40, height: 40)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Main color circle (flat style, smaller size)
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.white.opacity(0.15),
                                lineWidth: 1.5
                            )
                    )
                    .scaleEffect(isSelected ? 1.0 : 0.95)
            }
            .frame(width: 40, height: 40)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Favorite Item Row

struct FavoriteItemRow: View {
    let item: BrowserFavoriteItem
    let groupColor: Color
    let currentGroup: FavoriteGroup
    let availableGroups: [FavoriteGroup]
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMove: (FavoriteGroup) -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(groupColor)
                .frame(width: 4, height: 44)
            
            // Favicon using new metadata system
            if let url = URL(string: item.url) {
                FaviconView(
                    url: url,
                    faviconURL: item.faviconURL,
                    ogImageURL: item.ogImageURL,
                    type: .auto,  // Automatically selects the best option
                    size: 44
                )
            } else {
                // Fallback if URL is invalid
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(groupColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(groupColor)
                }
            }
            
            // Title and URL
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.tm.defaultTextMedium)
                    .foregroundColor(.tm.title)
                    .lineLimit(1)
                
                Text(item.url)
                    .font(.tm.hintText)
                    .foregroundColor(.tm.subTitle.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Menu button (3 dots)
            Menu {
                // Move to group
                if !availableGroups.isEmpty {
                    Menu {
                        ForEach(availableGroups) { group in
                            Button {
                                onMove(group)
                            } label: {
                                Label {
                                    Text(group.name)
                                } icon: {
                                    Circle()
                                        .fill(group.color)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                    } label: {
                        Label("Move to...", systemImage: "folder")
                    }
                }
                
                Divider()
                
                // Delete
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tm.subTitle.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.tm.container.opacity(0.5))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.clear)
//                .neumorphic(cornerRadius: 16)
                .bordered()
//                .fill(Color.tm.container.opacity(0.6))
                .onTapGesture {
                    onTap()
                }
        )
    }
}

// MARK: - Preview

#Preview {
    FavoritesView(onTapFavorite: { _ in })
}
