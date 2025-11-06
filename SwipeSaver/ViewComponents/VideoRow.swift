//
//  VideoRow.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 06.11.2025.
//

import SwiftUI

struct VideoRow: View {
    let video: SavedVideo
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: .medium) {
            // Иконка платформы
            platformIcon
            
            // Информация о видео
            VStack(alignment: .leading, spacing: .smallExt) {
                Text(video.fileName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.tm.title)
                    .lineLimit(1)
                
                HStack(spacing: .regular) {
                    Text(video.platform)
                        .font(.caption)
                        .foregroundColor(.tm.accent)
                    
                    Text("•")
                        .foregroundColor(.tm.subTitle)
                    
                    Text(formatFileSize(video.fileSize))
                        .font(.caption)
                        .foregroundColor(.tm.subTitle)
                    
                    Text("•")
                        .foregroundColor(.tm.subTitle)
                    
                    Text(formatDate(video.dateAdded))
                        .font(.caption)
                        .foregroundColor(.tm.subTitle)
                }
            }
            
            Spacer()
            
            // Кнопка удаления
            Button(action: onDelete) {
                Image(.trash)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.tm.error)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.medium)
        .background(Color.tm.container)
        .cornerRadius(Layout.Radius.regular)
    }
    
    @ViewBuilder
    private var platformIcon: some View {
        Image(.video)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(Color.tm.accent)
            .frame(width: 32, height: 32)
            .cornerRadius(Layout.Radius.regular)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
}

