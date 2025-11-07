//
//  Padding.swift
//  SwipeSaver
//
//  Created by Артур Кулик on 05.11.2025.
//  Copyright © 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

enum Layout {
    enum Radius {
        static let small: CGFloat = 4
        static let regular: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
    }
    
    enum Padding: CGFloat {
        /// 2
        case small = 2
        /// 4
        case smallExt = 4
        /// 8
        case regular = 8
        /// 12
        case regularExt = 12
        /// 16
        case medium = 16
        /// 20
        case mediumExt = 20
        /// 24
        case large = 24
        /// 32
        case extraLarge = 32
        
        var horizontalSpacing: CGFloat {
            Layout.Padding.medium.rawValue
        }
    }
}


extension HStack {
    // Инициализатор с параметрами
    init(alignment: VerticalAlignment = .center, spacing: Layout.Padding, @ViewBuilder content: () -> Content) {
        self.init(alignment: alignment, spacing: spacing.rawValue, content: content)
    }

    // Инициализатор без параметров (чтобы избежать конфликта)
    init(@ViewBuilder content: () -> Content) {
        self.init(alignment: .center, spacing: nil, content: content)
    }
}

extension VStack {
    // Инициализатор с параметрами
    init(alignment: HorizontalAlignment = .center, spacing: Layout.Padding, @ViewBuilder content: () -> Content) {
        self.init(alignment: alignment, spacing: spacing.rawValue, content: content)
    }

    // Инициализатор без параметров
    init(@ViewBuilder content: () -> Content) {
        self.init(alignment: .center, spacing: nil, content: content)
    }
}

extension LazyHStack {
    // Инициализатор с параметрами
    init(alignment: VerticalAlignment = .center, spacing: Layout.Padding, @ViewBuilder content: () -> Content) {
        self.init(alignment: alignment, spacing: spacing.rawValue, content: content)
    }

    // Инициализатор без параметров
    init(@ViewBuilder content: () -> Content) {
        self.init(alignment: .center, spacing: nil, content: content)
    }
}

extension LazyVStack {
    // Инициализатор с параметрами
    init(alignment: HorizontalAlignment = .center, spacing: Layout.Padding, @ViewBuilder content: () -> Content) {
        self.init(alignment: alignment, spacing: spacing.rawValue, content: content)
    }

    // Инициализатор без параметров
    init(@ViewBuilder content: () -> Content) {
        self.init(alignment: .center, spacing: nil, content: content)
    }
}

extension View {
    func padding(_ padding: Layout.Padding) -> some View {
        self.padding(padding.rawValue)
    }

    func padding(_ edges: Edge.Set = .all, _ padding: Layout.Padding) -> some View {
        self.padding(edges, padding.rawValue)
    }
}
