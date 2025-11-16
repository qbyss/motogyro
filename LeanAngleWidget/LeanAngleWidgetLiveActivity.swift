//
//  LeanAngleWidgetLiveActivity.swift
//  LeanAngleWidget
//
//  Created by Jack on 16/11/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LeanAngleWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LeanAngleWidgetAttributes.self) { context in
            // Lock Screen view
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LEAN ANGLE")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(formatAngle(context.state.currentAngle))
                        .font(.title2.bold())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 15) {
                        VStack {
                            Text("L")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(Int(context.state.maxLeanLeft))°")
                                .font(.caption.bold())
                        }

                        VStack {
                            Text("R")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(Int(context.state.maxLeanRight))°")
                                .font(.caption.bold())
                        }
                    }

                    Text("\(Int(context.state.speed)) km/h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MAX L")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(context.state.maxLeanLeft))°")
                            .font(.title3.bold())
                            .foregroundColor(.orange)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("MAX R")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(context.state.maxLeanRight))°")
                            .font(.title3.bold())
                            .foregroundColor(.orange)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(formatAngle(context.state.currentAngle))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("\(Int(context.state.speed)) km/h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    LeanIndicatorBar(angle: context.state.currentAngle)
                        .padding(.horizontal)
                }
            } compactLeading: {
                // Left side of compact view
                Text(formatAngle(context.state.currentAngle))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } compactTrailing: {
                // Right side of compact view
                Text("\(Int(context.state.speed))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            } minimal: {
                // Minimal view (when multiple activities)
                Text(formatAngle(context.state.currentAngle))
                    .font(.system(size: 12, weight: .bold))
            }
        }
    }

    private func formatAngle(_ angle: Double) -> String {
        let absAngle = abs(angle)
        let direction = angle > 0 ? "R" : (angle < 0 ? "L" : "")
        return "\(Int(absAngle))°\(direction)"
    }
}

// Visual lean indicator bar
struct LeanIndicatorBar: View {
    let angle: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Background bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)

                // Center marker
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 12)

                // Angle indicator
                Circle()
                    .fill(angle > 0 ? Color.green : Color.blue)
                    .frame(width: 16, height: 16)
                    .offset(x: offsetForAngle(angle, width: geometry.size.width))
            }
        }
        .frame(height: 16)
    }

    private func offsetForAngle(_ angle: Double, width: CGFloat) -> CGFloat {
        // Map -50° to 50° to the width of the bar
        let maxAngle: Double = 50.0
        let clampedAngle = max(-maxAngle, min(maxAngle, angle))
        let normalizedAngle = clampedAngle / maxAngle // -1 to 1
        return normalizedAngle * (width / 2 - 20) // Leave margin for the circle
    }
}

extension LeanAngleWidgetAttributes {
    fileprivate static var preview: LeanAngleWidgetAttributes {
        LeanAngleWidgetAttributes(speedThreshold: 5.0)
    }
}

extension LeanAngleWidgetAttributes.ContentState {
    fileprivate static var leaning: LeanAngleWidgetAttributes.ContentState {
        LeanAngleWidgetAttributes.ContentState(
            currentAngle: 35.0,
            maxLeanLeft: 42.0,
            maxLeanRight: 38.0,
            speed: 65.0,
            isMoving: true
        )
     }

     fileprivate static var straight: LeanAngleWidgetAttributes.ContentState {
         LeanAngleWidgetAttributes.ContentState(
            currentAngle: 0.0,
            maxLeanLeft: 15.0,
            maxLeanRight: 12.0,
            speed: 30.0,
            isMoving: true
         )
     }
}

#Preview("Notification", as: .content, using: LeanAngleWidgetAttributes.preview) {
   LeanAngleWidgetLiveActivity()
} contentStates: {
    LeanAngleWidgetAttributes.ContentState.leaning
    LeanAngleWidgetAttributes.ContentState.straight
}
