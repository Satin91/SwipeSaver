//
//  BrowserFavoritesViewModel.swift
//  UntraX
//
//  Created by Артур Кулик on 27.10.2025.
//

import Foundation
import SwiftUI
import Combine

final class FavoritesViewModel: ObservableObject {
    @Published var selectedGroup: FavoriteGroup?
    @Published var showAddGroupSheet = false
    @Published var groupName = ""
    @Published var selectedColor = "#0A84FF"
    @Published var editingGroup: FavoriteGroup?
    @Published var deleteAlert: InfoAlert? // Alert for deletion confirmation
    
    let userDefaultsObserver: UserDefaultsObserver = Executor.userDefaultsObserver
    private let repository: WebViewInteractor = Executor.webViewInteractor
    private var groupToDelete: FavoriteGroup? // Group to delete
    private var cancellables = Set<AnyCancellable>()
    
    // Special "All" group to display all favorites
    var allGroup: FavoriteGroup {
        let allFavorites = userDefaultsObserver.favoriteGroups.flatMap { $0.favorites }
        return FavoriteGroup(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, // Fixed ID for "All"
            name: "All",
            colorHex: "#8E8E93", // Gray color
            favorites: allFavorites
        )
    }
    
    // All groups including "All"
    var allGroupsWithAll: [FavoriteGroup] {
        return [allGroup] + userDefaultsObserver.favoriteGroups
    }
    
    let availableColors = [
        "#0A84FF", // Blue
        "#FF453A", // Red
        "#32D74B", // Green
        "#FFD60A", // Yellow
        "#BF5AF2", // Purple
        "#FF9F0A", // Orange
        "#00C7BE", // Teal
        "#FF375F"  // Pink
    ]
    
    init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    /// Sets up observers for automatic UI updates
    private func setupObservers() {
        // Subscribe to favoriteGroups changes and auto-update selectedGroup
        userDefaultsObserver.$favoriteGroups
            .sink { [weak self] updatedGroups in
                guard let self = self, let current = self.selectedGroup else { return }
                
                // If it's the "All" group, recreate it to get fresh data
                if current.id == self.allGroup.id {
                    // Force recreate the "All" group with fresh data
                    let freshAllGroup = self.createFreshAllGroup()
                    DispatchQueue.main.async {
                        self.selectedGroup = freshAllGroup
                    }
                } else {
                    // Find and update the selected group from the new data
                    if let updatedGroup = updatedGroups.first(where: { $0.id == current.id }) {
                        self.selectedGroup = updatedGroup
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    /// Creates a fresh "All" group with current data
    private func createFreshAllGroup() -> FavoriteGroup {
        let allFavorites = userDefaultsObserver.favoriteGroups.flatMap { $0.favorites }
        return FavoriteGroup(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            name: "All",
            colorHex: "#8E8E93",
            favorites: allFavorites
        )
    }
    
    // MARK: - Public Methods
    
    /// Initializes the first group as selected
    func selectFirstGroupIfNeeded() {
        if selectedGroup == nil {
            // Select "All" by default
            selectedGroup = createFreshAllGroup()
        }
    }
    
    /// Checks if a group can be deleted
    func canDeleteGroup(_ group: FavoriteGroup) -> Bool {
        // Cannot delete "All" and "Main"
        return group.id != allGroup.id && group.name != "Main"
    }
    
    /// Checks if a group can be edited
    func canEditGroup(_ group: FavoriteGroup) -> Bool {
        // Cannot edit "All" and "Main"
        return group.id != allGroup.id && group.name != "Main"
    }
    
    /// Finds the group color for a specific favorite item
    func getColorForFavorite(_ favorite: BrowserFavoriteItem, in group: FavoriteGroup) -> Color {
        // If this is the "All" group, find the original group of the item
        if group.id == allGroup.id {
            for originalGroup in userDefaultsObserver.favoriteGroups {
                if originalGroup.favorites.contains(where: { $0.id == favorite.id }) {
                    return originalGroup.color
                }
            }
        }
        // Otherwise return the group's own color
        return group.color
    }
    
    /// Finds the group for a specific favorite item
    func getGroupForFavorite(_ favorite: BrowserFavoriteItem) -> FavoriteGroup? {
        for group in userDefaultsObserver.favoriteGroups {
            if group.favorites.contains(where: { $0.id == favorite.id }) {
                return group
            }
        }
        return nil
    }
    
    /// Gets available groups for moving (excluding "All" and current group)
    func getAvailableGroupsForMove(currentGroup: FavoriteGroup) -> [FavoriteGroup] {
        return userDefaultsObserver.favoriteGroups.filter { group in
            group.id != currentGroup.id && group.id != allGroup.id
        }
    }
    
    /// Deletes a favorite item
    func deleteFavorite(_ favorite: BrowserFavoriteItem, from group: FavoriteGroup) {
        // If deleting from "All" group, find the actual group
        if group.id == allGroup.id {
            // Find the actual group containing this favorite
            for originalGroup in userDefaultsObserver.favoriteGroups {
                if originalGroup.favorites.contains(where: { $0.id == favorite.id }) {
                    deleteFavoriteFromActualGroup(favorite, from: originalGroup)
                    return
                }
            }
        } else {
            deleteFavoriteFromActualGroup(favorite, from: group)
        }
    }
    
    /// Internal method to delete favorite from actual group
    private func deleteFavoriteFromActualGroup(_ favorite: BrowserFavoriteItem, from group: FavoriteGroup) {
        var groups = userDefaultsObserver.favoriteGroups
        guard let groupIndex = groups.firstIndex(where: { $0.id == group.id }) else { return }
        
        groups[groupIndex].favorites.removeAll { $0.id == favorite.id }
        userDefaultsObserver.updateFavoriteGroups(groups)
        
        print("✅ [BrowserFavoritesViewModel] Favorite deleted: \(favorite.title)")
        
        // Force refresh if "All" is selected
        if let selected = selectedGroup, selected.id == allGroup.id {
            DispatchQueue.main.async {
                self.selectedGroup = self.createFreshAllGroup()
            }
        }
    }
    
    /// Moves a favorite item to another group
    func moveFavorite(_ favorite: BrowserFavoriteItem, from sourceGroup: FavoriteGroup, to targetGroup: FavoriteGroup) {
        var groups = userDefaultsObserver.favoriteGroups
        
        // Find group indices
        guard let sourceIndex = groups.firstIndex(where: { $0.id == sourceGroup.id }),
              let targetIndex = groups.firstIndex(where: { $0.id == targetGroup.id }) else {
            return
        }
        
        // Remove from source group
        groups[sourceIndex].favorites.removeAll { $0.id == favorite.id }
        
        // Add to target group (if not already there)
        if !groups[targetIndex].favorites.contains(where: { $0.id == favorite.id }) {
            groups[targetIndex].favorites.append(favorite)
        }
        
        userDefaultsObserver.updateFavoriteGroups(groups)
        
        // No need to manually refresh - Combine subscription will handle it automatically
        
        print("✅ [BrowserFavoritesViewModel] Favorite moved from '\(sourceGroup.name)' to '\(targetGroup.name)': \(favorite.title)")
    }
    
    /// Selects a group
    func selectGroup(_ group: FavoriteGroup) {
        selectedGroup = group
    }
    
    /// Opens the form for creating a new group
    func openAddGroupSheet() {
        editingGroup = nil
        groupName = ""
        selectedColor = availableColors[0]
        showAddGroupSheet = true
    }
    
    /// Opens the form for editing a group
    func startEditingGroup(_ group: FavoriteGroup) {
        editingGroup = group
        groupName = group.name
        selectedColor = group.colorHex
        showAddGroupSheet = true
    }
    
    /// Deletes a group
    func deleteGroup(_ group: FavoriteGroup) {
        // Check if deletion is allowed
        if !canDeleteGroup(group) {
            deleteAlert = InfoAlert(
                title: "Cannot Delete",
                text: "The group \"\(group.name)\" cannot be deleted.",
                style: .info
            )
            return
        }
        
        // Don't allow deleting the last regular group (except All)
        let regularGroupsCount = userDefaultsObserver.favoriteGroups.count
        guard regularGroupsCount > 1 else {
            // Show informational alert
            deleteAlert = InfoAlert(
                title: "Cannot Delete",
                text: "Cannot delete the last group. At least one group must remain.",
                style: .info
            )
            return
        }
        
        // Save group for deletion and show confirmation
        groupToDelete = group
        deleteAlert = InfoAlert(
            title: "Delete Group?",
            text: "The group \"\(group.name)\" and all favorites in it will be deleted. This action cannot be undone.",
            style: .destructive,
            deleteTitle: "Delete"
        )
    }
    
    /// Confirms group deletion
    func confirmDeleteGroup() {
        guard let group = groupToDelete else { return }
        
        // Delete through repository
        var groups = userDefaultsObserver.favoriteGroups
        groups.removeAll { $0.id == group.id }
        userDefaultsObserver.updateFavoriteGroups(groups)
        
        // If deleting the selected group, switch to "All"
        if selectedGroup?.id == group.id {
            selectedGroup = allGroup
        }
        
        groupToDelete = nil
        print("✅ [BrowserFavoritesViewModel] Group deleted: \(group.name)")
    }
    
    /// Saves a group (create or update)
    func saveGroup() {
        guard !groupName.isEmpty else { return }
        
        if let editingGroup = editingGroup {
            // Edit mode
            updateGroup(editingGroup)
        } else {
            // Create mode
            createGroup()
        }
        
        // Close form and reset state
        closeSheet()
    }
    
    // MARK: - Private Methods
    
    private func createGroup() {
        repository.createFavoriteGroup(name: groupName, colorHex: selectedColor)
        
        // Select the new group
        if let newGroup = userDefaultsObserver.favoriteGroups.last {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedGroup = newGroup
            }
        }
        
        print("✅ [BrowserFavoritesViewModel] Group created: \(groupName)")
    }
    
    private func updateGroup(_ group: FavoriteGroup) {
        var groups = userDefaultsObserver.favoriteGroups
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        
        groups[index].name = groupName
        groups[index].colorHex = selectedColor
        userDefaultsObserver.updateFavoriteGroups(groups)
        
        // Update selected group if it's the one being edited
        if selectedGroup?.id == group.id {
            if let updatedGroup = userDefaultsObserver.favoriteGroups.first(where: { $0.id == group.id }) {
                selectedGroup = updatedGroup
            }
        }
        
        print("✅ [BrowserFavoritesViewModel] Group updated: \(groupName)")
    }
    
    private func closeSheet() {
        showAddGroupSheet = false
        editingGroup = nil
        groupName = ""
        
        selectedColor = availableColors[0]
    }
}

