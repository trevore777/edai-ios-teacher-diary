//
//  WeatherVM.swift
//  TeacherDiary
//
//  Created by Trevor Elliott on 10/11/2025.
//


import Foundation
import CoreLocation

/// ViewModel that provides 3-hourly weather via OpenWeatherMap to the splash screen.
/// Depends on `WeatherOWMService` and the data types in that file (HourlyPoint, TargetSlot, WeatherSlot).
final class WeatherVM: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published private var hourly: [HourlyPoint] = []
    @Published var statusNote: String = ""

    // Gold Coast fallback so the UI always shows something quickly
    private let fallback = CLLocationCoordinate2D(latitude: -28.0167, longitude: 153.4000)

    private let locator = Locator()
    private let service = WeatherOWMService()

    override init() {
        super.init()

        locator.onLocation = { [weak self] coord in
            guard let self else { return }
            Task { @MainActor in
                self.statusNote = "Got location, fetching OWM…"
                await self.fetchPreferReal(coord)
            }
        }
        locator.onStatus = { [weak self] s in
            Task { @MainActor in self?.statusNote = "Location: \(s.rawValue)" }
        }
        locator.onError = { [weak self] err in
            Task { @MainActor in
                self?.statusNote = "Location error: \(err.localizedDescription). Using fallback."
                self?.fetchFallback()
            }
        }
    }

    /// Show fallback immediately, then request GPS and upgrade the data if available.
    func start() {
        fetchFallback()
        locator.requestOnce()
    }

    func refresh() {
        statusNote = "Refreshing…"
        if let c = locator.lastCoordinate {
            Task { @MainActor in await fetchPreferReal(c) }
        } else {
            start()
        }
    }

    // MARK: - Internal fetch logic

    @MainActor
    private func fetchPreferReal(_ coord: CLLocationCoordinate2D) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await service.fetch3hForecast(lat: coord.latitude, lon: coord.longitude)
            if data.isEmpty {
                statusNote = "Empty GPS data. Fallback."
                try await Task.sleep(nanoseconds: 150_000_000)
                try await fetchUsing(self.fallback)
            } else {
                hourly = data
                statusNote = "Weather loaded (GPS)"
            }
        } catch {
            statusNote = "OWM error: \(error.localizedDescription). Fallback."
            try? await fetchUsing(self.fallback)
        }
    }

    private func fetchFallback() {
        Task { @MainActor in
            statusNote = "Loading fallback (Gold Coast)…"
            isLoading = true
            defer { isLoading = false }
            do {
                hourly = try await service.fetch3hForecast(lat: fallback.latitude, lon: fallback.longitude)
                statusNote = hourly.isEmpty ? "Fallback empty." : "Weather loaded (fallback)"
            } catch {
                statusNote = "Fallback error: \(error.localizedDescription)"
                hourly = []
            }
        }
    }

    @MainActor
    private func fetchUsing(_ coord: CLLocationCoordinate2D) async throws {
        hourly = try await service.fetch3hForecast(lat: coord.latitude, lon: coord.longitude)
    }

    /// Nearest temps/codes for the requested slots *today*
    func summary(for slots: [TargetSlot]) -> [WeatherSlot]? {
        guard !hourly.isEmpty else { return nil }
        let cal = Calendar.current
        let today = Date()
        return slots.compactMap { slot in
            var comps = cal.dateComponents([.year, .month, .day], from: today)
            comps.hour = slot.hour; comps.minute = slot.minute; comps.second = 0
            guard let targetDate = cal.date(from: comps) else { return nil }
            let best = hourly.min {
                abs($0.time.timeIntervalSince(targetDate)) < abs($1.time.timeIntervalSince(targetDate))
            }
            guard let p = best else { return WeatherSlot(label: slot.label, temp: .nan, code: 800) }
            return WeatherSlot(label: slot.label, temp: p.temperature, code: p.code)
        }
    }
}

// MARK: - Robust one-shot Locator (with timeout + fallback trigger)
final class Locator: NSObject, CLLocationManagerDelegate {
    enum Status: String { case notDetermined, denied, restricted, authorized, servicesDisabled }

    private let manager = CLLocationManager()
    var onLocation: ((CLLocationCoordinate2D) -> Void)?
    var onStatus: ((Status) -> Void)?
    var onError: ((Error) -> Void)?

    var lastCoordinate: CLLocationCoordinate2D?

    private var timeoutTimer: Timer?
    private let timeoutInterval: TimeInterval = 6.0
    private var didDeliverThisCycle = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestOnce() {
        cancelTimeout()
        didDeliverThisCycle = false

        guard CLLocationManager.locationServicesEnabled() else {
            onStatus?(.servicesDisabled)
            onError?(NSError(domain: "Locator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location services disabled"]))
            return
        }

        switch manager.authorizationStatus {
        case .notDetermined:
            onStatus?(.notDetermined)
            manager.requestWhenInUseAuthorization()
        case .restricted:
            onStatus?(.restricted)
            onError?(NSError(domain: "Locator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location restricted"]))
        case .denied:
            onStatus?(.denied)
            onError?(NSError(domain: "Locator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Location denied in Settings"]))
        case .authorizedWhenInUse, .authorizedAlways:
            onStatus?(.authorized)
            startTimedRequest()
        @unknown default:
            onStatus?(.restricted)
            onError?(NSError(domain: "Locator", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown location auth state"]))
        }
    }

    func refresh() {
        if let c = lastCoordinate { onLocation?(c) } else { requestOnce() }
    }

    private func startTimedRequest() {
        manager.requestLocation()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            guard let self, !self.didDeliverThisCycle else { return }
            self.onError?(NSError(domain: "Locator", code: 5, userInfo: [NSLocalizedDescriptionKey: "Timed out waiting for location"]))
        }
    }

    private func deliver(_ coord: CLLocationCoordinate2D) {
        didDeliverThisCycle = true
        cancelTimeout()
        lastCoordinate = coord
        onLocation?(coord)
    }

    private func cancelTimeout() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            onStatus?(.authorized)
            startTimedRequest()
        case .denied:
            onStatus?(.denied)
            onError?(NSError(domain: "Locator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Location denied in Settings"]))
        case .restricted:
            onStatus?(.restricted)
            onError?(NSError(domain: "Locator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location restricted"]))
        case .notDetermined:
            onStatus?(.notDetermined)
        @unknown default:
            onStatus?(.restricted)
            onError?(NSError(domain: "Locator", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown location auth state"]))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let c = locations.last?.coordinate { deliver(c) }
        else {
            onError?(NSError(domain: "Locator", code: 6, userInfo: [NSLocalizedDescriptionKey: "No locations returned"]))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError?(error)
    }
}
