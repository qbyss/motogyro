//
//  GyroscopeView.swift
//  motogyro
//
//  Created by Jack on 16/11/2025.
//

import SwiftUI

struct GyroscopeView: View {
    @StateObject private var motionManager = MotionManager()

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 20) {
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

                // Max lean display and reset button
                VStack(spacing: 15) {
                    MaxLeanDisplay(
                        maxLeanLeft: motionManager.maxLeanLeft,
                        maxLeanRight: motionManager.maxLeanRight
                    )

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
                .padding(.bottom, 50)
            }
        }
    }
}

struct HorizonSphereView: View {
    let rollAngle: Double

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Sky and ground hemispheres
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
                }
                .rotationEffect(.degrees(-rollAngle)) // Counter-rotate to keep level
                .clipShape(Circle())
                .frame(width: size * 0.95, height: size * 0.95)

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

                // Graduation marks every 5 degrees
                ForEach(Array(stride(from: -50, through: 50, by: 5)), id: \.self) { angle in
                    ScaleMarkView(
                        angle: angle,
                        radius: arcRadius,
                        isMajor: angle % 10 == 0,
                        isLabeled: [0, 10, 20, 30, 40, 50, -10, -20, -30, -40, -50].contains(angle)
                    )
                }

                // Angle labels
                ForEach([0, 10, 20, 30, 40, 50, -10, -20, -30, -40, -50], id: \.self) { angle in
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
    let isMajor: Bool
    let isLabeled: Bool

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)

            // Convert angle to position on arc
            let angleInRadians = Double(angle) * .pi / 180.0
            let x = center.x + radius * sin(angleInRadians)
            let y = center.y - radius * cos(angleInRadians)

            let markHeight: CGFloat = isLabeled ? 25 : (isMajor ? 18 : 12)

            // Draw mark pointing inward (toward circle center)
            Rectangle()
                .fill(Color.black)
                .frame(width: 2.5, height: markHeight)
                .position(x: x, y: y - markHeight / 2)
                .rotationEffect(.degrees(Double(angle)), anchor: UnitPoint(x: 0.5, y: 1))
        }
    }
}

struct AngleLabelView: View {
    let angle: Int
    let radius: CGFloat
    let size: CGFloat

    var body: some View {
        let angleInRadians = Double(angle) * .pi / 180.0
        // Position labels outside the arc (further from center)
        let labelRadius = radius + 35
        let x = labelRadius * sin(angleInRadians) + size / 2
        let y = -labelRadius * cos(angleInRadians) + size / 2

        Text("\(abs(angle))°")
            .font(.system(size: 16, weight: .bold))
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
        HStack(spacing: 40) {
            Text("MAX LEAN L: \(Int(maxLeanLeft))°")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)

            Text("MAX LEAN R: \(Int(maxLeanRight))°")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

#Preview {
    GyroscopeView()
}
