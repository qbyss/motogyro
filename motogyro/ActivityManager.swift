//
//  ActivityManager.swift
//  motogyro
//
//  Created by Jack on 16/11/2025.
//

import Foundation
import ActivityKit
import Combine

class ActivityManager: ObservableObject {
    @Published var isActivityActive: Bool = false

    private var activity: Activity<LeanAngleWidgetAttributes>?
    private var cancellables = Set<AnyCancellable>()

    var speedThreshold: Double = 5.0 // km/h

    init() {
        // Monitor for existing activities on launch
        checkForExistingActivity()
    }

    func startActivity() {
        let authInfo = ActivityAuthorizationInfo()
        print("🔴 Starting activity - areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")

        guard authInfo.areActivitiesEnabled else {
            print("🔴 Live Activities are not enabled")
            return
        }

        // Don't start if already active
        guard activity == nil else {
            print("🔴 Activity already active")
            return
        }

        let attributes = LeanAngleWidgetAttributes(speedThreshold: speedThreshold)
        let initialState = LeanAngleWidgetAttributes.ContentState(
            currentAngle: 0.0,
            maxLeanLeft: 0.0,
            maxLeanRight: 0.0,
            speed: 0.0,
            isMoving: false
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
            isActivityActive = true
            print("✅ Live Activity started successfully - ID: \(activity?.id ?? "unknown")")
        } catch {
            print("❌ Error starting Live Activity: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
        }
    }

    func updateActivity(angle: Double, maxLeft: Double, maxRight: Double, speed: Double, isMoving: Bool) {
        guard let activity = activity else {
            print("⚠️ Cannot update - no active activity")
            return
        }

        let updatedState = LeanAngleWidgetAttributes.ContentState(
            currentAngle: angle,
            maxLeanLeft: maxLeft,
            maxLeanRight: maxRight,
            speed: speed,
            isMoving: isMoving
        )

        Task {
            await activity.update(
                ActivityContent<LeanAngleWidgetAttributes.ContentState>(
                    state: updatedState,
                    staleDate: nil
                )
            )
        }
    }

    func endActivity() {
        guard let activity = activity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
            self.isActivityActive = false
            print("Live Activity ended")
        }
    }

    private func checkForExistingActivity() {
        // Check if there's already an active activity
        if let existingActivity = Activity<LeanAngleWidgetAttributes>.activities.first {
            activity = existingActivity
            isActivityActive = true
        }
    }
}
