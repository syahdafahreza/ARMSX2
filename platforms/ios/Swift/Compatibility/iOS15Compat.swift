// iOS15Compat.swift — Backward compatibility layer for iOS 15 and 16
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI

#if !os(macOS)

// MARK: - Observation Compatibility

@propertyWrapper
public struct ObservationIgnored<T> {
    public var wrappedValue: T
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

// MARK: - URL Documents Directory Compatibility

public extension URL {
    static var documentsDirectoryCompat: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - NavigationStack Compatibility

/// Provides a NavigationStack fallback for iOS 15, wrapping NavigationView,
/// while delegating to native SwiftUI.NavigationStack on iOS 16+.
public struct NavigationStack<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        if #available(iOS 16.0, *) {
            SwiftUI.NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
            .navigationViewStyle(.stack)
        }
    }
}

public extension NavigationStack {
    init<Data>(path: Binding<Data>?, @ViewBuilder content: () -> Content) {
        self.content = content()
    }
}

// MARK: - NavigationSplitView Compatibility

/// Provides a NavigationSplitView fallback for iOS 15, while delegating
/// to native SwiftUI.NavigationSplitView on iOS 16+.
public struct NavigationSplitView<Sidebar: View, Detail: View>: View {
    private let sidebar: Sidebar
    private let detail: Detail

    public init(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.detail = detail()
    }

    public var body: some View {
        if #available(iOS 16.0, *) {
            SwiftUI.NavigationSplitView {
                sidebar
            } detail: {
                detail
            }
        } else {
            HStack(spacing: 0) {
                sidebar
                detail
            }
        }
    }
}

// MARK: - ContentUnavailableView Compatibility

/// Fallback for iOS 17's ContentUnavailableView on iOS 15/16.
public struct ContentUnavailableView: View {
    private let title: Text
    private let systemImage: String?
    private let description: Text?

    public init(_ titleKey: LocalizedStringKey, systemImage: String? = nil, description: Text? = nil) {
        self.title = Text(titleKey)
        self.systemImage = systemImage
        self.description = description
    }

    public init(_ title: String, systemImage: String? = nil, description: Text? = nil) {
        self.title = Text(title)
        self.systemImage = systemImage
        self.description = description
    }

    public init(_ title: String, systemImage: String? = nil) {
        self.title = Text(title)
        self.systemImage = systemImage
        self.description = nil
    }

    public var body: some View {
        VStack(spacing: 12) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
            }
            title
                .font(.headline)
            if let description = description {
                description
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - UnevenRoundedRectangle Compatibility

public struct RectangleCornerRadii: Equatable {
    public var topLeading: CGFloat
    public var bottomLeading: CGFloat
    public var bottomTrailing: CGFloat
    public var topTrailing: CGFloat

    public init(
        topLeading: CGFloat = 0,
        bottomLeading: CGFloat = 0,
        bottomTrailing: CGFloat = 0,
        topTrailing: CGFloat = 0
    ) {
        self.topLeading = topLeading
        self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing
        self.topTrailing = topTrailing
    }
}

public struct UnevenRoundedRectangle: Shape {
    public var cornerRadii: RectangleCornerRadii
    public var style: RoundedCornerStyle

    public init(cornerRadii: RectangleCornerRadii, style: RoundedCornerStyle = .continuous) {
        self.cornerRadii = cornerRadii
        self.style = style
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = max(0, min(min(cornerRadii.topLeading, rect.width / 2), rect.height / 2))
        let tr = max(0, min(min(cornerRadii.topTrailing, rect.width / 2), rect.height / 2))
        let bl = max(0, min(min(cornerRadii.bottomLeading, rect.width / 2), rect.height / 2))
        let br = max(0, min(min(cornerRadii.bottomTrailing, rect.width / 2), rect.height / 2))

        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        if tr > 0 {
            path.addArc(
                center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                radius: tr,
                startAngle: Angle(degrees: -90),
                endAngle: Angle(degrees: 0),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        if br > 0 {
            path.addArc(
                center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                radius: br,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        if bl > 0 {
            path.addArc(
                center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                radius: bl,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        if tl > 0 {
            path.addArc(
                center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                radius: tl,
                startAngle: Angle(degrees: 180),
                endAngle: Angle(degrees: 270),
                clockwise: false
            )
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - View Modifier Compatibility

private struct OnChangeCompatibilityModifier<V: Equatable>: ViewModifier {
    let value: V
    let initial: Bool
    let action: (V, V) -> Void
    @State private var previousValue: V?

    func body(content: Content) -> some View {
        content
            .onAppear {
                if initial {
                    action(value, value)
                }
                previousValue = value
            }
            .onChange(of: value) { newValue in
                let old = previousValue ?? newValue
                previousValue = newValue
                action(old, newValue)
            }
    }
}

public enum VisibilityCompat {
    case automatic
    case visible
    case hidden
}

public struct CompatPresentationDetent: Hashable {
    public static let medium = CompatPresentationDetent()
    public static let large = CompatPresentationDetent()
}

public extension View {
    /// Two-argument and initial onChange backport for iOS 15.
    @ViewBuilder
    func onChange<V: Equatable>(
        of value: V,
        initial: Bool,
        _ action: @escaping (_ oldValue: V, _ newValue: V) -> Void
    ) -> some View {
        self.modifier(OnChangeCompatibilityModifier(value: value, initial: initial, action: action))
    }

    /// Two-argument onChange backport for iOS 15.
    @ViewBuilder
    func onChange<V: Equatable>(
        of value: V,
        _ action: @escaping (_ oldValue: V, _ newValue: V) -> Void
    ) -> some View {
        self.modifier(OnChangeCompatibilityModifier(value: value, initial: false, action: action))
    }

    /// sensoryFeedback stub for iOS 15/16.
    @ViewBuilder
    func sensoryFeedback<T: Equatable>(_ feedback: Any, trigger: T) -> some View {
        self
    }

    /// scrollTargetLayout stub for iOS 15/16.
    @ViewBuilder
    func scrollTargetLayout() -> some View {
        self
    }

    /// scrollTargetBehavior stub for iOS 15/16.
    @ViewBuilder
    func scrollTargetBehavior(_ behavior: Any) -> some View {
        self
    }

    /// scrollIndicators stub for iOS 15.
    @ViewBuilder
    func scrollIndicators(_ visibility: Any) -> some View {
        self
    }

    /// scrollContentBackground stub for iOS 15.
    @ViewBuilder
    func scrollContentBackground(_ visibility: Any) -> some View {
        self
    }

    /// presentationDetents stub for iOS 15.
    @ViewBuilder
    func presentationDetents(_ detents: Any) -> some View {
        self
    }

    /// presentationDragIndicator stub for iOS 15.
    @ViewBuilder
    func presentationDragIndicator(_ visibility: Any) -> some View {
        self
    }

    /// focusable stub for iOS 15.
    @ViewBuilder
    func focusable(_ isFocusable: Bool = true) -> some View {
        self
    }

    /// focusEffectDisabled stub for iOS 15.
    @ViewBuilder
    func focusEffectDisabled(_ disabled: Bool = true) -> some View {
        self
    }
}

#endif
