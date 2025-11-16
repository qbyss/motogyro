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
        print("🟢 WIDGET CONFIGURATION CALLED")
        return ActivityConfiguration(for: MotoGyroWidgetAttributes.self) { context in
            print("🟡 LOCK SCREEN CLOSURE CALLED")
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)

        } dynamicIsland: { context in
            print("🔵 DYNAMIC ISLAND CLOSURE CALLED")
            return DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    print("🟣 EXPANDED LEADING REGION")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SPEED")
                            .font(.caption2)
                        HStack(spacing: 2) {
                            Text(String(format: "%.0f", context.state.currentSpeed))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(context.state.useMetric ? "km/h" : "mph")
                                .font(.caption)
                        }
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
                            Image(systemName: context.state.currentLeanAngle > 0 ? "arrow.right" : "arrow.left")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
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
                        }

                        VStack(spacing: 2) {
                            Text("MAX R")
                                .font(.caption2)
                            Text(String(format: "%.0f°", context.state.maxLeanRight))
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                print("🟠 COMPACT LEADING")
                return HStack(spacing: 2) {
                    Image(systemName: "gauge.with.needle")
                        .font(.system(size: 12))
                    Text("\(Int(context.state.currentSpeed))")
                        .font(.system(size: 12, weight: .semibold))
                }
            } compactTrailing: {
                print("🟤 COMPACT TRAILING")
                return HStack(spacing: 2) {
                    Text("\(Int(abs(context.state.currentLeanAngle)))°")
                        .font(.system(size: 12, weight: .semibold))
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 10))
                }
            } minimal: {
                print("⚪ MINIMAL")
                return Image(systemName: "motorcycle")
                    .font(.system(size: 14))
            }
            .keylineTint(.green)
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<MotoGyroWidgetAttributes>

    var body: some View {
        let _ = print("🔴 LOCKSCREEN VIEW RENDERING - Speed: \(context.state.currentSpeed), Lean: \(context.state.currentLeanAngle)")
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
