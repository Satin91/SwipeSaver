//
//  BrowserFavoriteGroupChip.swift
//  UntraX
//
//  Created by Артур Кулик on 26.10.2025.
//

import SwiftUI

struct FavoriteGroupChip: View {
    let group: FavoriteGroup
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    var showContextMenu: Bool = true // По умолчанию показываем
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Color indicator
                Circle()
                    .fill(group.color)
                    .frame(width: 8, height: 8)
                    .shadow(color: group.color.opacity(0.5), radius: 4, x: 0, y: 2)
                
                // Group name
                Text(group.name)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .tm.title : .tm.subTitle.opacity(0.8))
                
                // Favorites count badge
                if !group.favorites.isEmpty {
                    Text("\(group.favorites.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? group.color : .tm.subTitle.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? group.color.opacity(0.15) : Color.tm.subTitle.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    // Background
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.tm.container.opacity(0.8))
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.tm.container.opacity(0.5))
                    }
                    
                    // Border
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSelected ? 
                                LinearGradient(
                                    colors: [
                                        group.color.opacity(0.4),
                                        group.color.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [
                                        Color.tm.subTitle.opacity(0.15),
                                        Color.tm.subTitle.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4) // Дополнительный padding чтобы тень не обрезалась
        .if(showContextMenu) { view in
            view.contextMenu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - View Extension для условного модификатора

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // "All" chip без контекстного меню
        FavoriteGroupChip(
            group: FavoriteGroup(
                name: "All",
                colorHex: "#8E8E93",
                favorites: [
                    BrowserFavoriteItem(url: "https://google.com", title: "Google"),
                    BrowserFavoriteItem(url: "https://github.com", title: "GitHub")
                ]
            ),
            isSelected: true,
            onTap: {},
            onEdit: {},
            onDelete: {},
            showContextMenu: false
        )
        
        // Selected chip
        FavoriteGroupChip(
            group: FavoriteGroup(
                name: "Main",
                colorHex: "#0A84FF",
                favorites: [
                    BrowserFavoriteItem(url: "https://google.com", title: "Google"),
                    BrowserFavoriteItem(url: "https://github.com", title: "GitHub")
                ]
            ),
            isSelected: false,
            onTap: {},
            onEdit: {},
            onDelete: {}
        )
        
        // Unselected chip
        FavoriteGroupChip(
            group: FavoriteGroup(
                name: "Work",
                colorHex: "#FF453A",
                favorites: [
                    BrowserFavoriteItem(url: "https://example.com", title: "Example")
                ]
            ),
            isSelected: false,
            onTap: {},
            onEdit: {},
            onDelete: {}
        )
        
        // Empty group
        FavoriteGroupChip(
            group: FavoriteGroup(
                name: "Personal",
                colorHex: "#32D74B",
                favorites: []
            ),
            isSelected: false,
            onTap: {},
            onEdit: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color.tm.background)
}

