//
//  MotoGyroWidgetAttributes.swift
//  motogyro
//
//  Shared attributes for Live Activities
//

import Foundation
import ActivityKit

struct MotoGyroWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var currentSpeed: Double
        var currentLeanAngle: Double
        var maxLeanLeft: Double
        var maxLeanRight: Double
        var useMetric: Bool
        var isTracking: Bool
    }

    // Fixed non-changing properties about your activity go here!
    var rideStartTime: Date
}
