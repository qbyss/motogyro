//
//  LocationManager.swift
//  motogyro
//
//  GPS and speed tracking manager for motorcycle riding
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    /// Current speed in km/h
    @Published var currentSpeed: Double = 0.0

    /// Current speed in mph
    @Published var currentSpeedMPH: Double = 0.0

    /// Maximum speed reached in this session (km/h)
    @Published var maxSpeed: Double = 0.0

    /// Location authorization status
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Whether location services are available and authorized
    @Published var isLocationAvailable: Bool = false

    /// Current location accuracy (in meters)
    @Published var accuracy: Double = 0.0

    /// Current altitude (in meters)
    @Published var altitude: Double = 0.0

    /// Current heading/direction (in degrees, 0-360)
    @Published var heading: Double = 0.0

    // MARK: - Private Properties

    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?

    // MARK: - Configuration

    /// Speed threshold in km/h - lean angle tracking only activates above this speed
    var speedThreshold: Double = 10.0 {
        didSet {
            UserDefaults.standard.set(speedThreshold, forKey: "speedThreshold")
        }
    }

    /// Whether to use metric (km/h) or imperial (mph) units
    var useMetric: Bool = true {
        didSet {
            UserDefaults.standard.set(useMetric, forKey: "useMetric")
        }
    }

    /// Whether lean angle tracking is enabled based on speed threshold
    var isAboveSpeedThreshold: Bool {
        return currentSpeed >= speedThreshold
    }

    // MARK: - Initialization

    override init() {
        super.init()

        // Load saved preferences
        speedThreshold = UserDefaults.standard.double(forKey: "speedThreshold")
        if speedThreshold == 0 {
            speedThreshold = 30.0 // Default to 30 km/h
        }

        // Force metric by default for Europe
        // Check if we've migrated to new GPS version
        if !UserDefaults.standard.bool(forKey: "gpsVersionMigrated") {
            // First time with GPS feature - force metric
            useMetric = true
            UserDefaults.standard.set(true, forKey: "useMetric")
            UserDefaults.standard.set(true, forKey: "gpsVersionMigrated")
        } else {
            // Load saved preference
            if let savedMetric = UserDefaults.standard.object(forKey: "useMetric") as? Bool {
                useMetric = savedMetric
            } else {
                useMetric = true
                UserDefaults.standard.set(true, forKey: "useMetric")
            }
        }

        // Configure location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone // Get all updates
        locationManager.allowsBackgroundLocationUpdates = false // Only enable when Live Activity is active
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true

        // Authorization status will be updated via locationManagerDidChangeAuthorization delegate callback
    }

    // MARK: - Public Methods

    /// Request location permission
    func requestPermission() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    /// Request always authorization (for background tracking)
    func requestAlwaysAuthorization() {
        if authorizationStatus == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }

    /// Start location and speed tracking
    func startTracking() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services are not enabled")
            return
        }

        // Request permission if needed
        if authorizationStatus == .notDetermined {
            requestPermission()
        }

        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    /// Stop location and speed tracking
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    /// Enable background location updates (for Live Activity)
    func enableBackgroundUpdates() {
        locationManager.allowsBackgroundLocationUpdates = true
        print("📍 Background location updates enabled")
    }

    /// Disable background location updates
    func disableBackgroundUpdates() {
        locationManager.allowsBackgroundLocationUpdates = false
        print("📍 Background location updates disabled")
    }

    /// Reset max speed
    func resetMaxSpeed() {
        maxSpeed = 0.0
    }

    /// Reset all session data
    func resetSession() {
        currentSpeed = 0.0
        currentSpeedMPH = 0.0
        maxSpeed = 0.0
        accuracy = 0.0
        altitude = 0.0
        heading = 0.0
        lastLocation = nil
    }

    // MARK: - Private Helpers

    private func updateLocationAvailability() {
        isLocationAvailable = CLLocationManager.locationServicesEnabled() &&
            (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }

    private func convertToKmh(_ speedInMetersPerSecond: Double) -> Double {
        return speedInMetersPerSecond * 3.6
    }

    private func convertToMph(_ kmh: Double) -> Double {
        return kmh * 0.621371
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        lastLocation = location

        // Update speed
        if location.speed >= 0 { // -1 means invalid speed
            currentSpeed = convertToKmh(location.speed)
            currentSpeedMPH = convertToMph(currentSpeed)

            // Track max speed
            if currentSpeed > maxSpeed {
                maxSpeed = currentSpeed
            }
        } else {
            currentSpeed = 0.0
            currentSpeedMPH = 0.0
        }

        // Update accuracy
        accuracy = location.horizontalAccuracy

        // Update altitude
        if location.verticalAccuracy >= 0 {
            altitude = location.altitude
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        updateLocationAvailability()

        // Automatically start tracking if authorized
        if isLocationAvailable {
            startTracking()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}
