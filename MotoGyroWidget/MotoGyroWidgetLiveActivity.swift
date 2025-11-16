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

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SPEED")
                            .font(.caption2)
                        HStack(spacing: 2) {
                            Text(String(format: "%.0f", context.state.currentSpeed))
                                .font(.title2)
                                .fontWeight(.bold)
                                .contentTransition(.identity)
                            Text(context.state.useMetric ? "km/h" : "mph")
                                .font(.caption)
                        }
                    }
                    .padding(.leading, 8)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("LEAN")
                            .font(.caption2)
                        HStack(spacing: 2) {
                            Text(String(format: "%.0f°", abs(context.state.currentLeanAngle)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .contentTransition(.identity)
                            Image(systemName: context.state.currentLeanAngle > 0 ? "arrow.right" : "arrow.left")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.trailing, 8)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        VStack(spacing: 2) {
                            Text("MAX L")
                                .font(.caption2)
                            Text(String(format: "%.0f°", context.state.maxLeanLeft))
                                .font(.callout)
                                .fontWeight(.semibold)
                                .contentTransition(.identity)
                        }

                        VStack(spacing: 2) {
                            Text("MAX R")
                                .font(.caption2)
                            Text(String(format: "%.0f°", context.state.maxLeanRight))
                                .font(.callout)
                                .fontWeight(.semibold)
                                .contentTransition(.identity)
                        }
                    }
                    .padding(.top, 4)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }
            } compactLeading: {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                    Text("\(Int(context.state.maxLeanLeft))")
                        .font(.system(size: 20, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                        .contentTransition(.identity)
                    Text("°")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.green)
                }
                .transaction { transaction in
                    transaction.animation = nil
                }
            } compactTrailing: {
                HStack(spacing: 2) {
                    Text("\(Int(context.state.maxLeanRight))")
                        .font(.system(size: 20, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(.red)
                        .contentTransition(.identity)
                    Text("°")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.red)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.red)
                }
                .transaction { transaction in
                    transaction.animation = nil
                }
            } minimal: {
                Image(systemName: "motorcycle")
                    .font(.system(size: 18, weight: .semibold))
            }
            .keylineTint(.green)
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<MotoGyroWidgetAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "motorcycle")
                    .font(.title2)
                Text("MOTO GYRO")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .foregroundColor(.white)

            HStack(spacing: 20) {
                // Speed
                VStack(alignment: .leading, spacing: 4) {
                    Text("SPEED")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        Text(String(format: "%.0f", context.state.currentSpeed))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(context.state.useMetric ? "km/h" : "mph")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Lean Angle
                VStack(alignment: .trailing, spacing: 4) {
                    Text("LEAN")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        Text(String(format: "%.0f°", abs(context.state.currentLeanAngle)))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Image(systemName: context.state.currentLeanAngle > 0 ? "arrow.right" : "arrow.left")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            // Max leans
            HStack(spacing: 30) {
                VStack(spacing: 2) {
                    Text("MAX L")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f°", context.state.maxLeanLeft))
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                VStack(spacing: 2) {
                    Text("MAX R")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f°", context.state.maxLeanRight))
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.8))
        .activitySystemActionForegroundColor(.white)
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
