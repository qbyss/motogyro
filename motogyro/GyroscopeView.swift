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
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Main gyroscope display
                ZStack {
                    // Horizon sphere
                    HorizonSphereView(rollAngle: motionManager.roll)
                        .frame(width: 350, height: 350)

                    // Angle scale and arrow
                    AngleScaleView(currentAngle: motionManager.roll)
                        .frame(width: 350, height: 350)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)

                Spacer()

                // Max lean display
                MaxLeanDisplay(
                    maxLeanLeft: motionManager.maxLeanLeft,
                    maxLeanRight: motionManager.maxLeanRight
                )
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
                // Circle background
                Circle()
                    .fill(Color.black)
                    .frame(width: size, height: size)

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

                // Outer circle border
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: size * 0.95, height: size * 0.95)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

struct AngleScaleView: View {
    let currentAngle: Double

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size * 0.48

            ZStack {
                // Curved scale arc
                ForEach([-50, -40, -30, -20, -10, 0, 10, 20, 30, 40, 50], id: \.self) { angle in
                    ScaleMarkView(
                        angle: angle,
                        radius: radius,
                        isMajor: angle % 10 == 0
                    )
                }

                // Angle labels
                ForEach([-50, -30, -10, 0, 10, 30, 50], id: \.self) { angle in
                    AngleLabelView(
                        angle: angle,
                        radius: radius,
                        size: size
                    )
                }

                // Triangle arrow pointing to current angle
                TriangleArrow(currentAngle: currentAngle, radius: radius)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

struct ScaleMarkView: View {
    let angle: Int
    let radius: CGFloat
    let isMajor: Bool

    var body: some View {
        // Convert angle to position on arc
        let angleInRadians = Double(angle) * .pi / 180.0
        let x = radius * sin(angleInRadians)
        let y = -radius * cos(angleInRadians)

        Rectangle()
            .fill(Color.white)
            .frame(width: 2, height: isMajor ? 20 : 12)
            .offset(y: -radius + (isMajor ? 10 : 6))
            .rotationEffect(.degrees(Double(angle)))
            .position(x: x, y: y)
    }
}

struct AngleLabelView: View {
    let angle: Int
    let radius: CGFloat
    let size: CGFloat

    var body: some View {
        let angleInRadians = Double(angle) * .pi / 180.0
        let labelRadius = radius - 40
        let x = labelRadius * sin(angleInRadians) + size / 2
        let y = -labelRadius * cos(angleInRadians) + size / 2

        Text("\(abs(angle))°")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .position(x: x, y: y)
    }
}

struct TriangleArrow: View {
    let currentAngle: Double
    let radius: CGFloat

    var body: some View {
        // Clamp angle to -50 to 50 for display
        let clampedAngle = max(-50, min(50, currentAngle))
        let angleInRadians = clampedAngle * .pi / 180.0
        let x = radius * sin(angleInRadians)
        let y = -radius * cos(angleInRadians)

        Triangle()
            .fill(Color.red)
            .frame(width: 20, height: 25)
            .rotationEffect(.degrees(clampedAngle))
            .offset(y: -radius + 30)
            .rotationEffect(.degrees(clampedAngle))
            .position(x: x, y: y)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubPath()
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
                .foregroundColor(.white)

            Text("MAX LEAN R: \(Int(maxLeanRight))°")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}

#Preview {
    GyroscopeView()
}
