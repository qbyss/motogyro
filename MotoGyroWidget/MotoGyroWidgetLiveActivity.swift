//
//  MotoGyroWidgetLiveActivity.swift
//  MotoGyroWidget
//
//  Created by Jack on 16/11/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MotoGyroWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MotoGyroWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.3))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SPEED")
                            .font(.caption2)
                            .foregroundColor(.white)
                        HStack(spacing: 2) {
                            Text(String(format: "%.0f", context.state.currentSpeed))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(context.state.useMetric ? "km/h" : "mph")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("LEAN")
                            .font(.caption2)
                            .foregroundColor(.white)
                        HStack(spacing: 2) {
                            Text(String(format: "%.0f°", abs(context.state.currentLeanAngle)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Image(systemName: context.state.currentLeanAngle > 0 ? "arrow.right" : "arrow.left")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        VStack(spacing: 2) {
                            Text("MAX L")
                                .font(.caption2)
                                .foregroundColor(.white)
                            Text(String(format: "%.0f°", context.state.maxLeanLeft))
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }

                        VStack(spacing: 2) {
                            Text("MAX R")
                                .font(.caption2)
                                .foregroundColor(.white)
                            Text(String(format: "%.0f°", context.state.maxLeanRight))
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "speedometer")
            } compactTrailing: {
                Image(systemName: "arrow.left.and.right")
            } minimal: {
                Image(systemName: "motorcycle")
            }
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<MotoGyroWidgetAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                // Speed
                VStack(spacing: 4) {
                    Text("SPEED")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        Text(String(format: "%.0f", context.state.currentSpeed))
                            .font(.title)
                            .fontWeight(.bold)
                        Text(context.state.useMetric ? "km/h" : "mph")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Divider()
                    .frame(height: 40)

                // Current Lean
                VStack(spacing: 4) {
                    Text("LEAN")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        Text(String(format: "%.0f°", abs(context.state.currentLeanAngle)))
                            .font(.title)
                            .fontWeight(.bold)
                        Image(systemName: context.state.currentLeanAngle > 0 ? "arrow.right" : "arrow.left")
                            .foregroundColor(context.state.isTracking ? .green : .red)
                    }
                }
            }

            // Max Lean Angles
            HStack(spacing: 30) {
                VStack(spacing: 2) {
                    Text("MAX LEFT")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f°", context.state.maxLeanLeft))
                        .font(.headline)
                }

                VStack(spacing: 2) {
                    Text("MAX RIGHT")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f°", context.state.maxLeanRight))
                        .font(.headline)
                }
            }
        }
        .padding()
    }
}

extension MotoGyroWidgetAttributes {
    fileprivate static var preview: MotoGyroWidgetAttributes {
        MotoGyroWidgetAttributes(rideStartTime: Date())
    }
}

extension MotoGyroWidgetAttributes.ContentState {
    fileprivate static var riding: MotoGyroWidgetAttributes.ContentState {
        MotoGyroWidgetAttributes.ContentState(
            currentSpeed: 45,
            currentLeanAngle: 32,
            maxLeanLeft: 38,
            maxLeanRight: 42,
            useMetric: true,
            isTracking: true
        )
    }

    fileprivate static var stopped: MotoGyroWidgetAttributes.ContentState {
        MotoGyroWidgetAttributes.ContentState(
            currentSpeed: 0,
            currentLeanAngle: 2,
            maxLeanLeft: 38,
            maxLeanRight: 42,
            useMetric: true,
            isTracking: false
        )
    }
}

#Preview("Notification", as: .content, using: MotoGyroWidgetAttributes.preview) {
   MotoGyroWidgetLiveActivity()
} contentStates: {
    MotoGyroWidgetAttributes.ContentState.riding
    MotoGyroWidgetAttributes.ContentState.stopped
}
