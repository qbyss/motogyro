//
//  LiveActivityManager.swift
//  motogyro
//
//  Live Activity management for Dynamic Island
//

import Foundation
import ActivityKit
import SwiftUI

class LiveActivityManager: ObservableObject {
    @Published var isActivityActive: Bool = false
    private var currentActivity: Activity<MotoGyroWidgetAttributes>?

    // Start the Live Activity
    func startActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("📱 Live Activities are not enabled")
            return
        }

        // Don't start if already active
        if currentActivity != nil {
            print("📱 Live Activity already active")
            return
        }

        let attributes = MotoGyroWidgetAttributes(rideStartTime: Date())
        let initialState = MotoGyroWidgetAttributes.ContentState(
            currentSpeed: 0,
            currentLeanAngle: 0,
            maxLeanLeft: 0,
            maxLeanRight: 0,
            useMetric: true,
            isTracking: false
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            isActivityActive = true
            print("📱 Live Activity started successfully")
        } catch {
            print("📱 Error starting Live Activity: \(error.localizedDescription)")
        }
    }

    // Update the Live Activity with new data
    func updateActivity(
        speed: Double,
        leanAngle: Double,
        maxLeanLeft: Double,
        maxLeanRight: Double,
        useMetric: Bool,
        isTracking: Bool
    ) {
        guard let activity = currentActivity else {
            print("📱 No active Live Activity to update")
            return
        }

        let updatedState = MotoGyroWidgetAttributes.ContentState(
            currentSpeed: speed,
            currentLeanAngle: leanAngle,
            maxLeanLeft: maxLeanLeft,
            maxLeanRight: maxLeanRight,
            useMetric: useMetric,
            isTracking: isTracking
        )

        Task {
            await activity.update(
                .init(
                    state: updatedState,
                    staleDate: nil
                )
            )
        }
    }

    // Stop the Live Activity
    func stopActivity() {
        guard let activity = currentActivity else {
            print("📱 No active Live Activity to stop")
            return
        }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            isActivityActive = false
            print("📱 Live Activity stopped")
        }
    }

    // Check if activities are supported
    var areActivitiesSupported: Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
}
