//
//  GyroscopeView.swift
//  motogyro
//
//  Created by Jack on 16/11/2025.
//

import SwiftUI
import CoreLocation

struct GyroscopeView: View {
    @StateObject private var motionManager = MotionManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var liveActivityManager = LiveActivityManager()
    @State private var showSpeedSettings = false
    @State private var speedThresholdEnabled = false
    @State private var liveActivityEnabled = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? .black : .white)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // GPS Speed Display at top
                SpeedDisplay(
                    currentLeanAngle: motionManager.roll,
                    currentSpeed: locationManager.useMetric ? locationManager.currentSpeed : locationManager.currentSpeedMPH,
                    maxSpeed: locationManager.maxSpeed,
                    useMetric: locationManager.useMetric,
                    isTracking: motionManager.isTrackingEnabled,
                    isLocationAvailable: locationManager.isLocationAvailable
                )
                .padding(.top, 20)

                Spacer()
                    .frame(height: 40)

                // Main gyroscope display
                ZStack {
                    // Horizon sphere
                    HorizonSphereView(rollAngle: motionManager.roll)
                        .frame(width: 350, height: 350)

                    // Angle scale (rotates with horizon)
                    AngleScaleView(rollAngle: motionManager.roll)
                        .frame(width: 350, height: 350)

                    // Fixed arrow pointing up
                    FixedArrow()
                        .frame(width: 350, height: 350)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)

                Spacer()

                // Max lean display and buttons
                VStack(spacing: 15) {
                    MaxLeanDisplay(
                        maxLeanLeft: motionManager.maxLeanLeft,
                        maxLeanRight: motionManager.maxLeanRight
                    )

                    HStack(spacing: 20) {
                        Button(action: {
                            motionManager.calibrate()
                        }) {
                            Text("CALIBRATE")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            motionManager.resetMaxLeans()
                            locationManager.resetMaxSpeed()
                        }) {
                            Text("RESET")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }

                    // Settings cogwheel button
                    Button(action: {
                        showSpeedSettings.toggle()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.gray)
                            .clipShape(Circle())
                    }
                    .padding(.top, 10)
                }
            }
        }
        .persistentSystemOverlays(.hidden)
        .statusBarHidden()
        .preferredColorScheme(themeManager.themePreference.colorScheme)
        .sheet(isPresented: $showSpeedSettings) {
            SpeedSettingsView(
                locationManager: locationManager,
                themeManager: themeManager,
                liveActivityManager: liveActivityManager,
                speedThresholdEnabled: $speedThresholdEnabled,
                liveActivityEnabled: $liveActivityEnabled
            )
        }
        .onAppear {
            // Load saved preferences
            speedThresholdEnabled = UserDefaults.standard.object(forKey: "speedThresholdEnabled") as? Bool ?? false
            liveActivityEnabled = UserDefaults.standard.object(forKey: "liveActivityEnabled") as? Bool ?? false
            locationManager.startTracking()
            updateTrackingState()

            // Start Live Activity if enabled
            if liveActivityEnabled {
                liveActivityManager.startActivity()
            }
        }
        .onChange(of: locationManager.currentSpeed) {
            updateTrackingState()
            updateLiveActivity()
        }
        .onChange(of: motionManager.roll) {
            updateLiveActivity()
        }
        .onChange(of: speedThresholdEnabled) {
            updateTrackingState()
        }
        .onChange(of: liveActivityEnabled) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "liveActivityEnabled")
            if newValue {
                liveActivityManager.startActivity()
                updateLiveActivity()
            } else {
                liveActivityManager.stopActivity()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background && liveActivityEnabled {
                updateLiveActivity()
            }
        }
    }

    private func updateTrackingState() {
        if speedThresholdEnabled {
            motionManager.isTrackingEnabled = locationManager.isAboveSpeedThreshold
        } else {
            motionManager.isTrackingEnabled = true
        }
    }

    private func updateLiveActivity() {
        guard liveActivityEnabled else { return }

        liveActivityManager.updateActivity(
            speed: locationManager.useMetric ? locationManager.currentSpeed : locationManager.currentSpeedMPH,
            leanAngle: motionManager.roll,
            maxLeanLeft: motionManager.maxLeanLeft,
            maxLeanRight: motionManager.maxLeanRight,
            useMetric: locationManager.useMetric,
            isTracking: motionManager.isTrackingEnabled
        )
    }
}

struct HorizonSphereView: View {
    let rollAngle: Double
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Sky and ground hemispheres with graduations
                ZStack {
                    // Sky (blue) - top half
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)]),
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: size * 0.95, height: size * 0.95)
                        .mask(
                            Rectangle()
                                .frame(width: size, height: size / 2)
                                .offset(y: -size / 4)
                        )

                    // Ground (green) - bottom half
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green.opacity(0.6), Color.green.opacity(0.8)]),
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.95, height: size * 0.95)
                        .mask(
                            Rectangle()
                                .frame(width: size, height: size / 2)
                                .offset(y: size / 4)
                        )

                    // Horizon line
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: size * 0.95, height: 3)

                    // Horizon graduation marks - horizontal lines at different Y positions
                    ForEach([-80, -50, -20, 20, 50, 80], id: \.self) { yOffset in
                        HorizonGraduationMark(yOffset: yOffset, size: size)
                    }
                }
                .rotationEffect(.degrees(-rollAngle)) // Counter-rotate to keep level
                .clipShape(Circle())
                .frame(width: size * 0.95, height: size * 0.95)

                // Fixed airplane symbol (stays centered, doesn't rotate)
                AirplaneSymbol()
                    .frame(width: size * 0.4, height: size * 0.15)

                // Outer circle border (adaptive for theme)
                Circle()
                    .stroke(Color(colorScheme == .dark ? .white : .black).opacity(0.3), lineWidth: 3)
                    .frame(width: size * 0.95, height: size * 0.95)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

struct HorizonGraduationMark: View {
    let yOffset: Int  // Vertical offset from center in pixels
    let size: CGFloat

    var body: some View {
        // Pattern: long (±80), short (±50), long (±20)
        let absOffset = abs(yOffset)
        let markWidth: CGFloat = absOffset == 80 ? 120 : (absOffset == 50 ? 60 : 100)
        let markHeight: CGFloat = 3

        return Rectangle()
            .fill(Color.white)
            .frame(width: markWidth, height: markHeight)
            .offset(x: 0, y: CGFloat(yOffset))
    }
}

struct AirplaneSymbol: View {
    var body: some View {
        ZStack {
            // Center dot
            Circle()
                .fill(Color.orange)
                .frame(width: 12, height: 12)

            // Left wing
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.orange)
                .frame(width: 60, height: 8)
                .offset(x: -35, y: 0)

            // Right wing
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.orange)
                .frame(width: 60, height: 8)
                .offset(x: 35, y: 0)

            // Center vertical line
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.orange)
                .frame(width: 8, height: 20)
                .offset(y: 10)
        }
    }
}

struct AngleScaleView: View {
    let rollAngle: Double
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let arcRadius = size * 0.55 // Arc positioned outside the circle

            ZStack {
                // Draw the arc line
                ArcLine(radius: arcRadius)
                    .stroke(Color(colorScheme == .dark ? .white : .black), lineWidth: 3)

                // Graduation marks every 10 degrees
                ForEach(Array(stride(from: -50, through: 50, by: 10)), id: \.self) { angle in
                    ScaleMarkView(
                        angle: angle,
                        radius: arcRadius,
                        size: size
                    )
                }

                // Show labels at 0° and ±50°
                ForEach([-50, 0, 50], id: \.self) { angle in
                    AngleLabelView(
                        angle: angle,
                        radius: arcRadius,
                        size: size
                    )
                }
            }
            .rotationEffect(.degrees(-rollAngle)) // Rotate with horizon
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

struct ArcLine: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Draw arc from -50° to +50° (converting to radians and adjusting for coordinate system)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-140), // -50° from top (90° - 50° = 40°, but flipped = -140°)
            endAngle: .degrees(-40),    // +50° from top (90° + 50° = 140°, but flipped = -40°)
            clockwise: false
        )

        return path
    }
}

struct ScaleMarkView: View {
    let angle: Int
    let radius: CGFloat
    let size: CGFloat
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let angleInRadians = Double(angle) * .pi / 180.0
        let center = CGPoint(x: size / 2, y: size / 2)

        // Special marks (0° and ±50°) extend through the arc
        let isSpecialMark = angle == 0 || angle == 50 || angle == -50

        if isSpecialMark {
            // Mark extends both inward and outward through the arc
            let innerMarkLength: CGFloat = 20
            let outerMarkLength: CGFloat = 15

            let innerRadius = radius - innerMarkLength
            let outerRadius = radius + outerMarkLength

            let innerX = center.x + innerRadius * sin(angleInRadians)
            let innerY = center.y - innerRadius * cos(angleInRadians)
            let outerX = center.x + outerRadius * sin(angleInRadians)
            let outerY = center.y - outerRadius * cos(angleInRadians)

            Path { path in
                path.move(to: CGPoint(x: outerX, y: outerY))
                path.addLine(to: CGPoint(x: innerX, y: innerY))
            }
            .stroke(Color(colorScheme == .dark ? .white : .black), lineWidth: 5.5)
        } else {
            // Regular marks only extend inward
            let markLength: CGFloat = 15
            let innerRadius = radius - markLength

            let arcX = center.x + radius * sin(angleInRadians)
            let arcY = center.y - radius * cos(angleInRadians)
            let innerX = center.x + innerRadius * sin(angleInRadians)
            let innerY = center.y - innerRadius * cos(angleInRadians)

            Path { path in
                path.move(to: CGPoint(x: arcX, y: arcY))
                path.addLine(to: CGPoint(x: innerX, y: innerY))
            }
            .stroke(Color(colorScheme == .dark ? .white : .black), lineWidth: 2.5)
        }
    }
}

struct AngleLabelView: View {
    let angle: Int
    let radius: CGFloat
    let size: CGFloat
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let angleInRadians = Double(angle) * .pi / 180.0
        let center = CGPoint(x: size / 2, y: size / 2)

        // Position labels outside the arc (further from center)
        let labelRadius = radius + 30
        let x = center.x + labelRadius * sin(angleInRadians)
        let y = center.y - labelRadius * cos(angleInRadians)

        Text(angle == 0 ? "0°" : "50°")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color(colorScheme == .dark ? .white : .black))
            .position(x: x, y: y)
    }
}

struct FixedArrow: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            Triangle()
                .fill(Color.red)
                .frame(width: 30, height: 35)
                .position(x: size / 2, y: 20)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct MaxLeanDisplay: View {
    let maxLeanLeft: Double
    let maxLeanRight: Double
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Text("MAX LEAN")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(colorScheme == .dark ? .white : .black))

            HStack(spacing: 40) {
                Text("L: \(Int(maxLeanLeft))°")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(colorScheme == .dark ? .white : .black))

                Text("R: \(Int(maxLeanRight))°")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(colorScheme == .dark ? .white : .black))
            }
        }
        .padding()
        .background(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
        .cornerRadius(10)
    }
}

struct SpeedDisplay: View {
    let currentLeanAngle: Double
    let currentSpeed: Double
    let maxSpeed: Double
    let useMetric: Bool
    let isTracking: Bool
    let isLocationAvailable: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 25) {
                // Current lean angle
                VStack(spacing: 2) {
                    Text("LEAN")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f", abs(currentLeanAngle)))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(colorScheme == .dark ? .white : .black))
                    Text("deg")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }

                Divider()
                    .frame(height: 50)

                // Current speed
                VStack(spacing: 2) {
                    Text("SPEED")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f", currentSpeed))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(isLocationAvailable ? Color(colorScheme == .dark ? .white : .black) : .red)
                    Text(useMetric ? "km/h" : "mph")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }

                Divider()
                    .frame(height: 50)

                // Max speed
                VStack(spacing: 2) {
                    Text("MAX")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f", maxSpeed))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(colorScheme == .dark ? .white : .black))
                    Text(useMetric ? "km/h" : "mph")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            if !isLocationAvailable {
                Text("GPS Not Available - Enable Location Services")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .background(isTracking ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SpeedSettingsView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @Binding var speedThresholdEnabled: Bool
    @Binding var liveActivityEnabled: Bool
    @Environment(\.dismiss) var dismiss
    @State private var localTheme: ThemePreference = .system

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $localTheme) {
                        ForEach(ThemePreference.allCases, id: \.self) { preference in
                            Text(preference.rawValue).tag(preference)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Dynamic Island")) {
                    Toggle("Enable Live Activity", isOn: $liveActivityEnabled)

                    if liveActivityManager.areActivitiesSupported {
                        Text("Shows your speed and lean angle in the Dynamic Island when the app is in background")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("Live Activities are not available on this device")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if liveActivityManager.isActivityActive {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Live Activity is running")
                                .font(.caption)
                        }
                    }
                }

                Section(header: Text("Speed Threshold")) {
                    Toggle("Enable Speed Threshold", isOn: $speedThresholdEnabled)
                        .onChange(of: speedThresholdEnabled) { _, newValue in
                            // Save preference
                            UserDefaults.standard.set(newValue, forKey: "speedThresholdEnabled")
                        }

                    if speedThresholdEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Minimum Speed: \(Int(locationManager.speedThreshold)) km/h")
                                .font(.headline)
                            Slider(value: $locationManager.speedThreshold, in: 0...50, step: 5)
                            Text("Lean angle tracking only activates above this speed")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section(header: Text("Units")) {
                    Toggle("Use Metric (km/h)", isOn: $locationManager.useMetric)
                }

                Section(header: Text("Location Permission")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Status:")
                                .font(.headline)
                            Text(authorizationStatusText)
                                .foregroundColor(statusColor)
                        }

                        if locationManager.authorizationStatus == .notDetermined {
                            Button("Request Permission") {
                                locationManager.requestPermission()
                            }
                        } else if locationManager.authorizationStatus == .authorizedWhenInUse {
                            Button("Enable Background Tracking") {
                                locationManager.requestAlwaysAuthorization()
                            }
                        }

                        if locationManager.authorizationStatus == .denied {
                            Text("Please enable location services in Settings")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                Section(header: Text("GPS Info")) {
                    HStack {
                        Text("Accuracy:")
                        Spacer()
                        Text(String(format: "±%.1fm", locationManager.accuracy))
                    }

                    HStack {
                        Text("Altitude:")
                        Spacer()
                        Text(String(format: "%.0fm", locationManager.altitude))
                    }

                    HStack {
                        Text("Heading:")
                        Spacer()
                        Text(String(format: "%.0f°", locationManager.heading))
                    }
                }
            }
            .navigationTitle("GPS Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                localTheme = themeManager.themePreference
                print("🎨 Sheet loaded with theme: \(localTheme.rawValue)")
            }
            .onChange(of: localTheme) { oldValue, newValue in
                print("🎨 localTheme changed from \(oldValue.rawValue) to \(newValue.rawValue)")
                themeManager.themePreference = newValue
            }
        }
    }

    private var authorizationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Not Requested"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always (Background)"
        case .authorizedWhenInUse:
            return "When In Use"
        @unknown default:
            return "Unknown"
        }
    }

    private var statusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .orange
        }
    }
}

#Preview {
    GyroscopeView()
}
