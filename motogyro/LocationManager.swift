//
//  LocationManager.swift
//  motogyro
//
//  Created by Jack on 16/11/2025.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    @Published var speed: Double = 0.0 // Current speed in km/h
    @Published var isMoving: Bool = false // True if above speed threshold
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var speedThreshold: Double = 5.0 // Minimum speed in km/h to consider "moving"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = false

        checkAuthorizationStatus()
    }

    func requestPermissions() {
        locationManager.requestAlwaysAuthorization()
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    private func checkAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Speed is in m/s, convert to km/h
        let speedMetersPerSecond = max(0, location.speed)
        speed = speedMetersPerSecond * 3.6

        // Update moving status based on threshold
        isMoving = speed >= speedThreshold
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            startTracking()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}
