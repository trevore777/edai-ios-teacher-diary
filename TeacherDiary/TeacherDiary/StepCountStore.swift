import Foundation
import HealthKit

/// Handles authorization and fetching today's step count from HealthKit, safely.
final class StepCountStore: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var stepsToday: Int = 0
    @Published var permissionGranted = false
    @Published var statusMessage: String = ""

    init() {
        Task {
            await safeAuthorizeThenFetch()
        }
    }

    // MARK: - Public

    @MainActor
    func refresh() async {
        await safeAuthorizeThenFetch()
    }

    // MARK: - Private

    @MainActor
    private func safeAuthorizeThenFetch() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Health data not available on this device."
            permissionGranted = false
            return
        }

        // Prevents the OS crash if Info.plist key is missing
        guard Bundle.main.object(forInfoDictionaryKey: "NSHealthShareUsageDescription") != nil else {
            statusMessage = "Add NSHealthShareUsageDescription to Info.plist to read steps."
            permissionGranted = false
            return
        }

        do {
            try await requestAuthorization()
            await fetchSteps()
        } catch {
            statusMessage = "Health authorization failed: \(error.localizedDescription)"
            permissionGranted = false
        }
    }

    @MainActor
    private func requestAuthorization() async throws {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        try await healthStore.requestAuthorization(toShare: [], read: [stepType])
        permissionGranted = true
        statusMessage = "Health permission granted."
    }

    @MainActor
    private func fetchSteps() async {
        guard permissionGranted else { return }
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    self.statusMessage = "Step query error: \(error.localizedDescription)"
                    self.stepsToday = 0
                    return
                }
                let steps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                self.stepsToday = steps
                self.statusMessage = "Steps loaded."
            }
        }
        healthStore.execute(query)
    }
}
