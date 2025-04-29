//
//  AccessibilityExtension.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/13/25.
//

import SwiftUI
import Combine

// MARK: - Basic Accessibility Extensions

extension View {
    /// A comprehensive accessibility modifier that combines multiple accessibility features
    func improvedAccessibility(
        label: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        hidden: Bool = false,
        combineChildren: Bool = false
    ) -> some View {
        self
            .accessibilityElement(children: combineChildren ? .combine : .contain)
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityHidden(hidden)
    }
    
    /// Adds accessibility shortcuts for navigating through different sections of the app
    func withKeyboardShortcuts(navigate: @escaping (NavigationDirection) -> Void) -> some View {
        self
            .keyboardShortcut(KeyEquivalent("j"), modifiers: [.command], action: { navigate(.down) })
            .keyboardShortcut(KeyEquivalent("k"), modifiers: [.command], action: { navigate(.up) })
            .keyboardShortcut(KeyEquivalent("h"), modifiers: [.command], action: { navigate(.left) })
            .keyboardShortcut(KeyEquivalent("l"), modifiers: [.command], action: { navigate(.right) })
            .keyboardShortcut(KeyEquivalent("n"), modifiers: [.command, .shift], action: { navigate(.next) })
            .keyboardShortcut(KeyEquivalent("p"), modifiers: [.command, .shift], action: { navigate(.previous) })
    }
    
    /// Adds common action keyboard shortcuts
    func withActionShortcuts(
        onNew: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onSearch: (() -> Void)? = nil
    ) -> some View {
        self
            .conditionalKeyboardShortcut(KeyEquivalent("n"), modifiers: [.command], action: onNew)
            .conditionalKeyboardShortcut(KeyEquivalent("s"), modifiers: [.command], action: onSave)
            .conditionalKeyboardShortcut(KeyEquivalent.delete, modifiers: [.command], action: onDelete)
            .conditionalKeyboardShortcut(KeyEquivalent("f"), modifiers: [.command], action: onSearch)
    }
    
    /// Apply a keyboard shortcut only if the action is non-nil
    private func conditionalKeyboardShortcut(
        _ key: KeyEquivalent,
        modifiers: EventModifiers = [],
        action: (() -> Void)?
    ) -> some View {
        Group {
            if let action = action {
                self.keyboardShortcut(key, modifiers: modifiers, action: action)
            } else {
                self
            }
        }
    }
}

// MARK: - Keyboard Shortcut Extensions

extension View {
    /// Adds a keyboard shortcut with a custom action
    func keyboardShortcut(
        _ key: KeyEquivalent,
        modifiers: EventModifiers = [],
        action: @escaping () -> Void
    ) -> some View {
        self.modifier(KeyboardShortcutModifier(key: key, modifiers: modifiers, action: action))
    }
}

/// A view modifier that adds a keyboard shortcut with a custom action
struct KeyboardShortcutModifier: ViewModifier {
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let action: () -> Void
    
    @State private var publisher = PassthroughSubject<Void, Never>()
    
    func body(content: Content) -> some View {
        content
            .background(
                EmptyView().onAppear {
                    // Register the action with a notification
                    NotificationCenter.default.addObserver(
                        forName: Notification.Name("KeyboardShortcut_\(key)_\(modifiers)"),
                        object: nil,
                        queue: .main
                    ) { _ in action() }
                }
            )
    }
}

// MARK: - Navigation Direction

/// Possible navigation directions for keyboard shortcuts
enum NavigationDirection {
    case up, down, left, right, next, previous
}

// MARK: - Voice Control Improvements

extension View {
    /// Adds voice control identifiers to improve voice control navigation
    func voiceControlIdentifier(_ identifier: String) -> some View {
        self
            .accessibilityIdentifier(identifier)
            .accessibilityHint("Say '\(identifier)' to interact with this element")
    }
}

// MARK: - Focus Management

extension View {
    /// Improves focus handling for keyboard navigation
    func improvedFocusable(
        id: String,
        binding: Binding<String?>,
        onFocus: @escaping () -> Void = {}
    ) -> some View {
        self
            .accessibilityAddTraits(binding.wrappedValue == id ? .isSelected : [])
            .onTapGesture {
                binding.wrappedValue = id
                onFocus()
            }
            .onChange(of: binding.wrappedValue) { oldValue, newValue in
                if newValue == id && oldValue != id {
                    onFocus()
                }
            }
    }
}
