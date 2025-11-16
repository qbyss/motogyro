//
//  MotionManager.swift
//  motogyro
//
//  Created by Jack on 16/11/2025.
//

import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()

    @Published var roll: Double = 0.0 // Current roll angle in degrees
    @Published var maxLeanLeft: Double = 0.0 // Maximum left lean (positive value)
    @Published var maxLeanRight: Double = 0.0 // Maximum right lean (positive value)

    init() {
        startMotionUpdates()
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }

            // Get roll angle in radians and convert to degrees
            let rollRadians = motion.attitude.roll
            let rollDegrees = rollRadians * 180.0 / .pi

            // Update current roll (positive = right lean, negative = left lean)
            self.roll = rollDegrees

            // Track maximum lean angles
            if rollDegrees > 0 {
                // Right lean
                self.maxLeanRight = max(self.maxLeanRight, rollDegrees)
            } else {
                // Left lean
                self.maxLeanLeft = max(self.maxLeanLeft, abs(rollDegrees))
            }
        }
    }

    func resetMaxLeans() {
        maxLeanLeft = 0.0
        maxLeanRight = 0.0
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}
