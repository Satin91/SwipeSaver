//
//  CustomTextField.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//

import SwiftUI

struct TextFieldView: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let image: ImageResource?
    var keyboardType: UIKeyboardType = .default
    var autocorrectionDisabled: Bool = true
    var textInputAutocapitalization: TextInputAutocapitalization = .never
    
    
    init(placeholder: String, text: Binding<String>, icon: String, keyboardType: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        image = nil
        self.keyboardType = keyboardType
    }
    
    init(placeholder: String, text: Binding<String>, image: ImageResource, keyboardType: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self._text = text
        self.icon = ""
        self.image = image
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if let image {
                Image(image)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.tm.subTitle)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.tm.subTitle)
            }
            
            // Text Field
            TextField(placeholder, text: $text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.tm.title)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled(autocorrectionDisabled)
                .textInputAutocapitalization(textInputAutocapitalization)
                .keyboardType(keyboardType)
            
            // Clear Button
            if !text.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.tm.subTitle.opacity(0.4))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.tm.container.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.tm.border, lineWidth: 1)
                )
                .shadow(color: Color.tm.shadowColor.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        TextFieldView(
            placeholder: "Search history...",
            text: .constant(""),
            icon: "magnifyingglass"
        )
        
        TextFieldView(
            placeholder: "https://google.com",
            text: .constant("https://example.com"),
            icon: "link",
            keyboardType: .URL
        )
    }
    .padding()
    .background(Color.tm.background)
}

