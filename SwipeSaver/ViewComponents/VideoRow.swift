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
            VStack(alignment: .leading, spacing: 4) {
                Text(video.fileName)
                    .font(.tm.defaultTextMedium)
                    .foregroundColor(.tm.title)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(video.platform)
                        .font(.tm.captionText)
                        .foregroundColor(.tm.accent)
                    
                    Text("•")
                        .font(.tm.captionText)
                        .foregroundColor(.tm.subTitle)
                    
                    Text(formatFileSize(video.fileSize))
                        .font(.tm.captionText)
                        .foregroundColor(.tm.subTitle)
                    
                    Text("•")
                        .font(.tm.captionText)
                        .foregroundColor(.tm.subTitle)
                    
                    Text(formatDate(video.dateAdded))
                        .font(.tm.captionText)
                        .foregroundColor(.tm.subTitle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Кнопка удаления
            Button(action: onDelete) {
                Image(.more)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.tm.subTitle)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .medium)
        .material()
    }
    
    @ViewBuilder
    private var platformIcon: some View {
        Image(.video)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(Color.tm.accent)
            .frame(width: 44, height: 44)
            .cornerRadius(Layout.Radius.small)
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
