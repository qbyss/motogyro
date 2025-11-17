# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MotoGyro is an iOS application that tracks motorcycle lean angles and speed during rides. It uses the device's gyroscope to measure lean angles and GPS for speed tracking, with support for Live Activities to display real-time data in the Dynamic Island.

## Build & Development Commands

### Building the App
```bash
# Build the main app (Debug)
xcodebuild -scheme motogyro -configuration Debug build

# Build for Release
xcodebuild -scheme motogyro -configuration Release build

# Build the widget extension
xcodebuild -scheme MotoGyroWidgetExtension -configuration Debug build

# Clean build folder
xcodebuild clean -scheme motogyro
```

### Running Tests
```bash
# Run all tests
xcodebuild test -scheme motogyro -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run only unit tests
xcodebuild test -scheme motogyro -only-testing:motogyroTests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run only UI tests
xcodebuild test -scheme motogyro -only-testing:motogyroUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Code Analysis
```bash
# Analyze code for issues
xcodebuild analyze -scheme motogyro
```

## Architecture

### Pattern: MVVM with Observable Objects (SwiftUI + Combine)

The app uses **SwiftUI** for all UI with **Observable Managers** that serve as ViewModels:
- **MotionManager** - Gyroscope data via CoreMotion (60 Hz updates)
- **LocationManager** - GPS and speed tracking via CoreLocation
- **ThemeManager** - Appearance settings (Light/Dark/System)
- **LiveActivityManager** - Dynamic Island updates via ActivityKit

### Key Components

#### Main UI Flow
```
ContentView (Entry Point)
    └─ GyroscopeView (Main Screen)
        ├─ HorizonSphereView (Artificial horizon that rotates with device)
        ├─ AngleScaleView (Lean angle scale -50° to +50°)
        ├─ SpeedDisplay (Current lean, speed, max speed)
        ├─ MaxLeanDisplay (Max left/right lean angles)
        └─ SpeedSettingsView (Settings sheet)
```

#### Data Flow
```
Hardware Sensors → Observable Managers → GyroscopeView → Live Activity
    ↓                      ↓                    ↓              ↓
CoreMotion          @Published           UI Updates    Dynamic Island
CoreLocation        Properties
```

### Widget Extension Architecture

Located in `MotoGyroWidget/` directory:
- **MotoGyroWidgetLiveActivity.swift** - Dynamic Island UI (compact/expanded/minimal views)
- **MotoGyroWidgetAttributes.swift** (Shared/) - Data model shared between app and widget
- Uses **App Groups** (`group.net.spher.motogyro`) for data sharing

## Critical Implementation Details

### Orientation Lock
The app is **locked to portrait orientation only** via AppDelegate. This is enforced using `@UIApplicationDelegateAdaptor` in `motogyroApp.swift`. Do not remove this as it prevents UI layout issues.

### CoreLocation Threading
**IMPORTANT**: Always use `CLLocationManager.authorizationStatus()` as a **class method**, not as a property on an instance. Using it as a property causes UI unresponsiveness warnings. See `LocationManager.swift:XX` for correct usage.

### Speed-Based Tracking
The app only tracks maximum lean angles when speed exceeds a threshold (default: 30 km/h):
- Controlled by `LocationManager.speedThreshold` (saved in UserDefaults)
- Updates trigger `MotionManager.isTrackingEnabled`
- Settable via SpeedSettingsView (0-50 km/h range)

### Live Activity Updates
- Updates are throttled to **1 update per second maximum** in `LiveActivityManager`
- Activity state includes: speed, lean angle, max lean left/right, metric/imperial units
- Background location updates must be enabled for Live Activities to work while backgrounded
- Activity auto-restarts if dismissed from lock screen when `liveActivityEnabled` is true

### Gyroscope Calibration
- User taps CALIBRATE button → sets current angle as zero reference point
- Uses offset mechanism: `calibratedRoll = rollDegrees - calibrationOffset`
- Important for compensating when device is not perfectly upright in mount

## File Organization

```
motogyro/
├── Managers (Observable business logic)
│   ├── MotionManager.swift          # Gyroscope tracking
│   ├── LocationManager.swift        # GPS and speed
│   ├── ThemeManager.swift           # App appearance
│   ├── LiveActivityManager.swift   # Dynamic Island
│   └── Persistence.swift            # CoreData (minimal/unused)
├── Views
│   ├── motogyroApp.swift           # App entry + AppDelegate
│   ├── ContentView.swift           # Entry view wrapper
│   └── GyroscopeView.swift         # Main UI (761 lines)
│       └── Contains: HorizonSphereView, AngleScaleView, SpeedDisplay,
│           MaxLeanDisplay, SpeedSettingsView, FixedArrow components
├── Data Model
│   └── motogyro.xcdatamodeld/      # CoreData model (not actively used)
└── Configuration
    ├── Info.plist                   # UIBackgroundModes, NSSupportsLiveActivities
    └── motogyro.entitlements        # App Group capability

MotoGyroWidget/
├── MotoGyroWidgetLiveActivity.swift  # Dynamic Island UI
├── MotoGyroWidgetBundle.swift        # Widget entry point
├── MotoGyroWidget.swift              # Placeholder widget (minimal)
└── MotoGyroWidgetExtension.entitlements

Shared/
└── MotoGyroWidgetAttributes.swift    # Shared data model for Live Activities
```

## Dependencies & Frameworks

Pure Apple frameworks only - **no third-party dependencies**:
- **SwiftUI** - All UI
- **Combine** - Reactive data binding
- **CoreMotion** - Gyroscope/accelerometer
- **CoreLocation** - GPS and speed
- **ActivityKit** - Live Activities (iOS 16.1+)
- **WidgetKit** - Widget extension
- **CoreData** - Initialized but not actively used

## Required Capabilities & Permissions

- **Location Services** (When In Use) - For speed tracking
- **Background Location** - For Live Activity updates while app is backgrounded
- **Motion & Fitness** - For gyroscope access (implicit with CoreMotion)
- **Live Activities** - Enabled in Info.plist (`NSSupportsLiveActivities: true`)
- **App Groups** - For widget data sharing (`group.net.spher.motogyro`)

## Data Persistence

- **UserDefaults keys**:
  - `"speedThreshold"` - Speed threshold for tracking activation (Double, km/h)
  - `"useMetric"` - Unit preference (Bool)
  - `"theme"` - Theme selection (String: "system"/"light"/"dark")
  - `"liveActivityEnabled"` - Live Activity toggle state (Bool)
- **CoreData** - Currently only has unused "Item" entity
- **ActivityKit** - Live Activity state (ephemeral, system-managed)

## Unit Conversion

Speed conversions in codebase:
- GPS returns m/s
- To km/h: multiply by 3.6
- To mph: multiply by 0.621371
- Controlled by `LocationManager.useMetric` property

## Testing Notes

Both test targets (`motogyroTests`, `motogyroUITests`) are currently minimal/templated with no actual test implementations.

## Recent Bug Fixes

Recent commits addressed:
- Portrait orientation enforcement to prevent layout issues
- CoreLocation authorizationStatus() threading issues causing UI unresponsiveness
- Background GPS management for Live Activities
- Dynamic Island toggle functionality
- Default activation speed set to 30 km/h
