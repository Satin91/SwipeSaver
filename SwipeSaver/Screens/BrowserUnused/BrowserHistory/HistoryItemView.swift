import SwiftUI

struct HistoryItemView: View, Equatable {
    let item: BrowserHistoryItem
    let onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: .zero) {
            // Favicon
            FaviconView(url: URL(string: item.url)!)
                .frame(width: 48, height: 48)
                .background(smallElementBackground)
                .padding(.trailing, .medium)
            
            // Информация
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.tm.headline)
//                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tm.title)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // Индикатор домена
                    Circle()
                        .fill(Color.tm.accent.opacity(0.3))
                        .frame(width: 4, height: 4)
                    
                    Text(item.domain)
                        .font(.tm.hintTextMedium)
//                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.tm.subTitle.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 8)
            
            // Время
            timeLabel
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
//        .neumorphic()
        .bordered()
//        .background(RoundedRectangle(cornerRadius: 16).fill(.clear).stroke(Color.tm.border, lineWidth: 1))
//        .lightGlassmorphism(cornerRadius: 16, shadowRadius: 40, shadowOpacity: colorScheme == .dark ? 0.4 : 0.11)
//        .uiKitShadow(color: .tm.shadowColor, opacity: colorScheme == .dark ? 0.4 : 0.11, radius: 40, cornerRadius: 20)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = item.url
            }) {
                Label("Copy Link", systemImage: "doc.on.doc")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Компоненты
    
    private var timeLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.tm.subTitle.opacity(0.4))
            
            Text(item.formattedTime)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.tm.subTitle.opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            smallElementBackground
        )
    }
    
    private var smallElementBackground: some View {
        Capsule()
            .fill(Color.tm.container.opacity(0.3))
            .overlay(
                Capsule()
                    .strokeBorder(Color.tm.border.opacity(0.8), lineWidth: 0.5)
            )
//            .uiKitShadow(color: .tm.shadowColor, opacity: 0.1, radius: 35, cornerRadius: 40)
    }
    
    static func == (lhs: HistoryItemView, rhs: HistoryItemView) -> Bool {
        lhs.item.id == rhs.item.id
    }
}

#Preview {
    HistoryItemView(item: .init(title: "Search new tabs428576238756", url: "google.com"), onDelete: { })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.tm.accent.opacity(0.2).ignoresSafeArea(.all)
        }
}
