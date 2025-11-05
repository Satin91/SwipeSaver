import SwiftUI

// MARK: - Toast Type
enum ToastType {
    case error
    case warning
    case success
    
    var accentColor: Color {
        switch self {
        case .error:
            return Color(red: 0.95, green: 0.26, blue: 0.21) // #F24336
        case .warning:
            return Color(red: 1.0, green: 0.6, blue: 0.0) // #FF9800
        case .success:
            return Color(red: 0.3, green: 0.69, blue: 0.31) // #4CAF50
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .error:
            return .tm.container
        case .warning:
            return .tm.container
        case .success:
            return .tm.container
        }
    }
    
    var icon: String {
        switch self {
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }
}

// MARK: - Toast Model
struct ToastMessage: Equatable {
    let id: UUID
    let text: String
    let type: ToastType
    
    init(text: String, type: ToastType) {
        self.id = UUID() // Каждое сообщение получает уникальный ID
        self.text = text
        self.type = type
    }
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        return lhs.id == rhs.id // Сравниваем по уникальному ID
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: ToastMessage
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0
    @State private var dismissWorkItem: DispatchWorkItem?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.type.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(message.type.accentColor)
            
            Text(message.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: {
                dismissWorkItem?.cancel()
                dismissToast()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tm.background))
                .stroke(message.type.accentColor.opacity(0.3), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 4)
        )

        .padding(.horizontal, 16)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            showToast()
        }
        .onDisappear {
            dismissWorkItem?.cancel()
        }
    }
    
    private func showToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = 0
            opacity = 1
        }
        
        // Отменяем предыдущий таймер, если он был
        dismissWorkItem?.cancel()
        
        // Создаем новый таймер для автоматического скрытия через 5 секунд
        let workItem = DispatchWorkItem {
            self.dismissToast()
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
    }
    
    private func dismissToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = -100
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var message: ToastMessage?
    @State private var currentMessage: ToastMessage?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let currentMessage = currentMessage {
                VStack {
                    ToastView(message: currentMessage) {
                        self.currentMessage = nil
                    }
                    .padding(.top, 50) // Отступ от верха экрана
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
                .id(currentMessage.id) // Используем ID для отслеживания изменений
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentMessage?.id)
        .onChange(of: message) { newMessage in
            if let newMessage = newMessage {
                // Если есть новое сообщение, сначала скрываем старое
                if currentMessage != nil {
                    // Быстро скрываем текущий toast
                    withAnimation(.easeOut(duration: 0.2)) {
                        currentMessage = nil
                    }
                    // Показываем новый после небольшой задержки
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        currentMessage = newMessage
                        message = nil // Сбрасываем входящее сообщение
                    }
                } else {
                    // Если текущего нет, показываем сразу
                    currentMessage = newMessage
                    message = nil // Сбрасываем входящее сообщение
                }
            }
        }
    }
}

// MARK: - View Extension
extension View {
    func toast(message: Binding<ToastMessage?>) -> some View {
        self.modifier(ToastModifier(message: message))
    }
}

