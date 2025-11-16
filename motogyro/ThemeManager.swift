//
//  ThemeManager.swift
//  motogyro
//
//  Theme management for light/dark mode
//

import SwiftUI
import Combine

enum ThemePreference: String, CaseIterable {
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
            // Save synchronously - without the redundant onChange, this is fast enough
            UserDefaults.standard.set(themePreference.rawValue, forKey: "themePreference")
        }
    }

    init() {
        // Load saved theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: "themePreference"),
           let preference = ThemePreference(rawValue: savedTheme) {
            themePreference = preference
        }
    }
}
