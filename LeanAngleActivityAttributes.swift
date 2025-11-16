//
//  LeanAngleActivityAttributes.swift
//  motogyro
//
//  Created by Jack on 16/11/2025.
//

import Foundation
import ActivityKit

struct LeanAngleWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Current lean angle (positive = right, negative = left)
        var currentAngle: Double

        // Maximum lean angles
        var maxLeanLeft: Double
        var maxLeanRight: Double

        // Current speed in km/h
        var speed: Double

        // Whether the bike is moving (above threshold)
        var isMoving: Bool
    }

    // Static attributes that don't change during the activity
    var speedThreshold: Double
}
