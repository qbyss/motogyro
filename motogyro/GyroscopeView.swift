//
//  GyroscopeView.swift
//  motogyro
//
//  Created by Jack on 16/11/2025.
//

import SwiftUI
import Combine

struct GyroscopeView: View {
    @StateObject private var motionManager = MotionManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var activityManager = ActivityManager()

    @State private var cancellables = Set<AnyCancellable>()
    @State private var liveActivityEnabled = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Speed and Live Activity toggle
                VStack(spacing: 10) {
                    Text("\(Int(locationManager.speed)) km/h")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(locationManager.isMoving ? .green : .gray)

                    Toggle("Dynamic Island", isOn: $liveActivityEnabled)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal, 40)
                        .onChange(of: liveActivityEnabled) { newValue in
                            if newValue {
                                activityManager.startActivity()
                            } else {
                                activityManager.endActivity()
                            }
                        }
                }
                .padding(.top, 60)

                Spacer()

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
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            motionManager.resetMaxLeans()
                        }) {
                            Text("RESET")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Request location permissions and start tracking
            locationManager.requestPermissions()

            // Update Live Activity whenever motion or location data changes
            setupLiveActivityUpdates()
        }
        .onDisappear {
            // End Live Activity when view disappears
            if liveActivityEnabled {
                activityManager.endActivity()
            }
        }
    }

    private func setupLiveActivityUpdates() {
        // Combine publishers to update Live Activity
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if liveActivityEnabled && activityManager.isActivityActive {
                    activityManager.updateActivity(
                        angle: motionManager.roll,
                        maxLeft: motionManager.maxLeanLeft,
                        maxRight: motionManager.maxLeanRight,
                        speed: locationManager.speed,
                        isMoving: locationManager.isMoving
                    )
                }
            }
            .store(in: &cancellables)
    }
}

struct HorizonSphereView: View {
    let rollAngle: Double

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

                // Outer circle border (dark for visibility on white background)
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 3)
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

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let arcRadius = size * 0.55 // Arc positioned outside the circle

            ZStack {
                // Draw the arc line
                ArcLine(radius: arcRadius)
                    .stroke(Color.black, lineWidth: 3)

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

    var body: some View {
        let angleInRadians = Double(angle) * .pi / 180.0
        let center = CGPoint(x: size / 2, y: size / 2)

        // Special marks (0° and ±50°) extend through the arc
        let isSpecialMark = angle == 0 || angle == 50 || angle == -50

        if isSpecialMark {
            // Mark extends both inward and outward through the arc
            let innerMarkLength: CGFloat = 20
            let outerMarkLength: CGFloat = 10

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
            .stroke(Color.black, lineWidth: 2.5)
        } else {
            // Regular marks only extend inward
            let markLength: CGFloat = 20
            let innerRadius = radius - markLength

            let arcX = center.x + radius * sin(angleInRadians)
            let arcY = center.y - radius * cos(angleInRadians)
            let innerX = center.x + innerRadius * sin(angleInRadians)
            let innerY = center.y - innerRadius * cos(angleInRadians)

            Path { path in
                path.move(to: CGPoint(x: arcX, y: arcY))
                path.addLine(to: CGPoint(x: innerX, y: innerY))
            }
            .stroke(Color.black, lineWidth: 2.5)
        }
    }
}

struct AngleLabelView: View {
    let angle: Int
    let radius: CGFloat
    let size: CGFloat

    var body: some View {
        let angleInRadians = Double(angle) * .pi / 180.0
        let center = CGPoint(x: size / 2, y: size / 2)

        // Position labels outside the arc (further from center)
        let labelRadius = radius + 30
        let x = center.x + labelRadius * sin(angleInRadians)
        let y = center.y - labelRadius * cos(angleInRadians)

        Text(angle == 0 ? "0°" : "50°")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.black)
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

    var body: some View {
        VStack(spacing: 8) {
            Text("MAX LEAN")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            HStack(spacing: 40) {
                Text("L: \(Int(maxLeanLeft))°")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)

                Text("R: \(Int(maxLeanRight))°")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

#Preview {
    GyroscopeView()
}
