//
//  LiveActivityManager.swift
//  motogyro
//
//  Live Activity management for Dynamic Island
//

import Foundation
import ActivityKit
import SwiftUI
import Combine

class LiveActivityManager: ObservableObject {
    @Published var isActivityActive: Bool = false
    private var currentActivity: Activity<MotoGyroWidgetAttributes>?
    private var lastUpdateTime: Date?
    private let updateInterval: TimeInterval = 0.5 // Update at most twice per second

    // Start the Live Activity
    func startActivity() {
        print("📱 startActivity() called")
        print("📱 Activities enabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("📱 Live Activities are not enabled")
            return
        }

        // End all existing activities first to prevent duplicates
        endAllActivities()

        let attributes = MotoGyroWidgetAttributes(rideStartTime: Date())
        let initialState = MotoGyroWidgetAttributes.ContentState(
            currentSpeed: 0,
            currentLeanAngle: 0,
            maxLeanLeft: 0,
            maxLeanRight: 0,
            useMetric: true,
            isTracking: false
        )

        print("📱 Attempting to request Live Activity...")

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            isActivityActive = true
            print("📱 Live Activity started successfully! ID: \(currentActivity?.id ?? "unknown")")
            if let activity = currentActivity {
                print("📱 Activity state: \(activity.activityState)")
            }
        } catch {
            print("📱 Error starting Live Activity: \(error)")
            print("📱 Error details: \(error.localizedDescription)")
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
            return
        }

        // Throttle updates to avoid spamming
        let now = Date()
        if let lastUpdate = lastUpdateTime,
           now.timeIntervalSince(lastUpdate) < updateInterval {
            return
        }

        lastUpdateTime = now

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

    // End all existing Live Activities (prevents duplicates)
    private func endAllActivities() {
        let activities = Activity<MotoGyroWidgetAttributes>.activities
        print("📱 Found \(activities.count) existing activities")

        for activity in activities {
            print("📱 Ending existing activity: \(activity.id)")
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }

        currentActivity = nil
        isActivityActive = false
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
