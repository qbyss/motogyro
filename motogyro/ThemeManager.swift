//
//  ThemeManager.swift
//  motogyro
//
//  Theme management for light/dark mode
//

import SwiftUI
import Combine

enum ThemePreference: String, CaseIterable, Hashable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var themePreference: ThemePreference = .system {
        didSet {
            print("🎨 Theme changed to: \(themePreference.rawValue)")
            UserDefaults.standard.set(themePreference.rawValue, forKey: "themePreference")
            print("🎨 Saved to UserDefaults: \(themePreference.rawValue)")
        }
    }

    init() {
        // Load saved theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: "themePreference"),
           let preference = ThemePreference(rawValue: savedTheme) {
            print("🎨 Loading saved theme: \(savedTheme)")
            themePreference = preference
        } else {
            print("🎨 No saved theme, using default: system")
        }
    }
}
