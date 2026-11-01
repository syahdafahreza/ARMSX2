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

// MARK: - NavigationLink Value Compatibility for iOS 15

public extension NavigationLink where Destination == EmptyView {
    init<P: Hashable>(value: P?, @ViewBuilder label: () -> Label) {
        self.init(destination: EmptyView(), label: label)
    }
}

public extension NavigationLink where Destination == EmptyView, Label == Text {
    init<P: Hashable>(_ titleKey: LocalizedStringKey, value: P?) {
        self.init(destination: EmptyView(), label: { Text(titleKey) })
    }

    init<S: StringProtocol, P: Hashable>(_ title: S, value: P?) {
        self.init(destination: EmptyView(), label: { Text(title) })
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

    public init(_ titleKey: LocalizedStringKey, systemImage: String? = nil) {
        self.title = Text(titleKey)
        self.systemImage = systemImage
        self.description = nil
    }

    public init(
        @ViewBuilder label: () -> Text,
        @ViewBuilder description: () -> Text = { Text("") },
        @ViewBuilder actions: () -> AnyView = { AnyView(EmptyView()) }
    ) {
        self.title = label()
        self.systemImage = nil
        self.description = description()
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

// MARK: - LabeledContent Compatibility

public struct LabeledContent<Label: View, Content: View>: View {
    private let label: Label
    private let content: Content

    public init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self.label = label()
        self.content = content()
    }

    public var body: some View {
        HStack {
            label
            Spacer()
            content
                .foregroundColor(.secondary)
        }
    }
}

public extension LabeledContent where Label == Text, Content == Text {
    init<S1: StringProtocol, S2: StringProtocol>(_ title: S1, value: S2) {
        self.label = Text(title)
        self.content = Text(value)
    }

    init(_ titleKey: LocalizedStringKey, value: String) {
        self.label = Text(titleKey)
        self.content = Text(value)
    }
}

public extension LabeledContent where Label == Text {
    init<S: StringProtocol>(_ title: S, @ViewBuilder content: () -> Content) {
        self.label = Text(title)
        self.content = content()
    }

    init(_ titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.label = Text(titleKey)
        self.content = content()
    }
}

// MARK: - AnyLayout / HStackLayout / ZStackLayout Compatibility

public struct HStackLayout {
    public let alignment: VerticalAlignment
    public let spacing: CGFloat?
    public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }
}

public struct ZStackLayout {
    public let alignment: Alignment
    public init(alignment: Alignment = .center) {
        self.alignment = alignment
    }
}

public struct AnyLayout {
    private let layoutType: LayoutType

    private enum LayoutType {
        case hstack(VerticalAlignment, CGFloat?)
        case zstack(Alignment)
    }

    public init(_ layout: HStackLayout) {
        self.layoutType = .hstack(layout.alignment, layout.spacing)
    }

    public init(_ layout: ZStackLayout) {
        self.layoutType = .zstack(layout.alignment)
    }

    public func callAsFunction<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        Group {
            switch layoutType {
            case .hstack(let alignment, let spacing):
                HStack(alignment: alignment, spacing: spacing) {
                    content()
                }
            case .zstack(let alignment):
                ZStack(alignment: alignment) {
                    content()
                }
            }
        }
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

// MARK: - Compatibility Enums & Structs

public struct CompatVisibility: Hashable, ExpressibleByBooleanLiteral {
    public static let automatic = CompatVisibility(0)
    public static let visible = CompatVisibility(1)
    public static let hidden = CompatVisibility(2)

    private let id: Int
    private init(_ id: Int) { self.id = id }

    public init(booleanLiteral value: Bool) {
        self = value ? .visible : .hidden
    }
}

public struct CompatToolbarPlacement: Hashable {
    public static let navigationBar = CompatToolbarPlacement()
    public static let bottomBar = CompatToolbarPlacement()
    public static let tabBar = CompatToolbarPlacement()
    public static let automatic = CompatToolbarPlacement()
}

public struct CompatPresentationDetent: Hashable {
    public static let medium = CompatPresentationDetent()
    public static let large = CompatPresentationDetent()
    public static func fraction(_ fraction: CGFloat) -> CompatPresentationDetent { CompatPresentationDetent() }
    public static func height(_ height: CGFloat) -> CompatPresentationDetent { CompatPresentationDetent() }
}

public struct CompatContentMarginPlacement: Hashable {
    public static let scrollContent = CompatContentMarginPlacement()
    public static let automatic = CompatContentMarginPlacement()
}

public struct CompatScrollBounceBehavior: Hashable {
    public static let always = CompatScrollBounceBehavior()
    public static let basedOnSize = CompatScrollBounceBehavior()
    public static let automatic = CompatScrollBounceBehavior()
}

public struct CompatNavigationSplitViewStyle: Hashable {
    public static let balanced = CompatNavigationSplitViewStyle()
    public static let prominentDetail = CompatNavigationSplitViewStyle()
}

public struct CompatContainerBackgroundPlacement: Hashable {
    public static let navigation = CompatContainerBackgroundPlacement()
    public static let widget = CompatContainerBackgroundPlacement()
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

    /// scrollContentBackground stub for iOS 15.
    @ViewBuilder
    func scrollContentBackground(_ visibility: CompatVisibility) -> some View {
        self
    }

    /// scrollIndicators stub for iOS 15.
    @ViewBuilder
    func scrollIndicators(_ visibility: CompatVisibility) -> some View {
        self
    }

    /// scrollBounceBehavior stub for iOS 15/16.
    @ViewBuilder
    func scrollBounceBehavior(_ behavior: CompatScrollBounceBehavior, axes: Axis.Set = [.vertical]) -> some View {
        self
    }

    /// scrollDisabled stub for iOS 15.
    @ViewBuilder
    func scrollDisabled(_ disabled: Bool) -> some View {
        self
    }

    /// scrollPosition stub for iOS 15/16.
    @ViewBuilder
    func scrollPosition<ID: Hashable>(id: Binding<ID?>, anchor: UnitPoint? = nil) -> some View {
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

    /// presentationDetents stub for iOS 15.
    @ViewBuilder
    func presentationDetents(_ detents: Set<CompatPresentationDetent>) -> some View {
        self
    }

    /// presentationDetents stub for iOS 15.
    @ViewBuilder
    func presentationDetents(_ detents: [CompatPresentationDetent]) -> some View {
        self
    }

    /// presentationDragIndicator stub for iOS 15.
    @ViewBuilder
    func presentationDragIndicator(_ visibility: CompatVisibility) -> some View {
        self
    }

    /// presentationBackground stub for iOS 15/16.
    @ViewBuilder
    func presentationBackground<S: ShapeStyle>(_ style: S) -> some View {
        self
    }

    /// presentationBackground stub for iOS 15/16.
    @ViewBuilder
    func presentationBackground(_ color: Color) -> some View {
        self
    }

    /// presentationCornerRadius stub for iOS 15/16.
    @ViewBuilder
    func presentationCornerRadius(_ cornerRadius: CGFloat?) -> some View {
        self
    }

    /// persistentSystemOverlays stub for iOS 15.
    @ViewBuilder
    func persistentSystemOverlays(_ visibility: CompatVisibility) -> some View {
        self
    }

    /// contentMargins stub for iOS 15/16.
    @ViewBuilder
    func contentMargins(_ edges: Edge.Set = .all, _ insets: EdgeInsets, for placement: CompatContentMarginPlacement = .automatic) -> some View {
        self
    }

    /// contentMargins stub for iOS 15/16.
    @ViewBuilder
    func contentMargins(_ edges: Edge.Set = .all, _ length: CGFloat?, for placement: CompatContentMarginPlacement = .automatic) -> some View {
        self
    }

    /// contentMargins stub for iOS 15/16.
    @ViewBuilder
    func contentMargins(_ length: CGFloat, for placement: CompatContentMarginPlacement = .automatic) -> some View {
        self
    }

    /// toolbarBackground stub for iOS 15.
    @ViewBuilder
    func toolbarBackground(_ visibility: CompatVisibility, for bars: CompatToolbarPlacement...) -> some View {
        self
    }

    /// toolbarBackground stub for iOS 15.
    @ViewBuilder
    func toolbarBackground<S: ShapeStyle>(_ style: S, for bars: CompatToolbarPlacement...) -> some View {
        self
    }

    /// toolbar visibility stub for iOS 15.
    @ViewBuilder
    func toolbar(_ visibility: CompatVisibility, for bars: CompatToolbarPlacement...) -> some View {
        self
    }

    /// containerBackground stub for iOS 15/16.
    @ViewBuilder
    func containerBackground<S: ShapeStyle>(_ style: S, for placement: CompatContainerBackgroundPlacement) -> some View {
        self
    }

    /// containerBackground stub for iOS 15/16.
    @ViewBuilder
    func containerBackground(_ color: Color, for placement: CompatContainerBackgroundPlacement) -> some View {
        self
    }

    /// navigationSplitViewStyle stub for iOS 15.
    @ViewBuilder
    func navigationSplitViewStyle(_ style: CompatNavigationSplitViewStyle) -> some View {
        self
    }

    /// fontWeight stub for iOS 15.
    @ViewBuilder
    func fontWeight(_ weight: Font.Weight?) -> some View {
        self
    }

    /// navigationDestination stub for iOS 15.
    @ViewBuilder
    func navigationDestination<V: View>(isPresented: Binding<Bool>, @ViewBuilder destination: () -> V) -> some View {
        self.background(
            NavigationLink(
                destination: destination(),
                isActive: isPresented,
                label: { EmptyView() }
            )
            .hidden()
        )
    }

    /// navigationDestination stub for iOS 15.
    @ViewBuilder
    func navigationDestination<D: Hashable, C: View>(for data: D.Type, @ViewBuilder destination: @escaping (D) -> C) -> some View {
        self
    }

    /// navigationDestination stub for iOS 15.
    @ViewBuilder
    func navigationDestination<T, C: View>(item: Binding<T?>, @ViewBuilder destination: @escaping (T) -> C) -> some View {
        self.background(
            NavigationLink(
                destination: Group {
                    if let val = item.wrappedValue {
                        destination(val)
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { item.wrappedValue != nil },
                    set: { if !$0 { item.wrappedValue = nil } }
                ),
                label: { EmptyView() }
            )
            .hidden()
        )
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

    /// sensoryFeedback stub for iOS 15/16.
    @ViewBuilder
    func sensoryFeedback<T: Equatable>(_ feedback: Any, trigger: T) -> some View {
        self
    }
}

#endif
