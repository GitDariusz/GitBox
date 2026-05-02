import HealthKit
import SwiftUI

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    @Published var isAuthorized = false
    @Published var currentHeartRate: Double? = nil

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var workoutBuilder: HKWorkoutBuilder?
    private var workoutStartDate: Date?
    private var observerQuery: HKObserverQuery?

    private let hrType = HKQuantityType(.heartRate)
    private let hrUnit = HKUnit.count().unitDivided(by: .minute())

    func requestAuthorization() async {
        guard isAvailable else { return }
        let toShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        let toRead: Set<HKObjectType> = [
            hrType,
            HKQuantityType(.activeEnergyBurned),
            HKObjectType.workoutType()
        ]
        do {
            try await store.requestAuthorization(toShare: toShare, read: toRead)
            await MainActor.run { isAuthorized = true }
        } catch {}
    }

    // MARK: - Workout lifecycle

    func startWorkout() {
        guard isAvailable, isAuthorized else { return }
        workoutStartDate = Date()
        let config = HKWorkoutConfiguration()
        config.activityType = .boxing
        config.locationType = .indoor
        workoutBuilder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        workoutBuilder?.beginCollection(withStart: workoutStartDate!) { [weak self] _, _ in
            self?.startHeartRateObserver()
        }
    }

    // Kończy trening i zwraca statystyki HR (asynchronicznie)
    func finishWorkout() async -> (avgHR: Double?, maxHR: Double?) {
        guard let builder = workoutBuilder, let start = workoutStartDate else { return (nil, nil) }
        stopHeartRateObserver()
        let end = Date()
        workoutBuilder = nil
        workoutStartDate = nil

        do {
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {}

        return await fetchHRStats(from: start, to: end)
    }

    // Przerywa trening bez zapisu HR (gdy user kliknie ZAKOŃCZ)
    func cancelWorkout() {
        stopHeartRateObserver()
        workoutBuilder?.discardWorkout()
        workoutBuilder = nil
        workoutStartDate = nil
    }

    // MARK: - Live heart rate (z Apple Watch przez HealthKit)

    private func startHeartRateObserver() {
        let query = HKObserverQuery(sampleType: hrType, predicate: nil) { [weak self] _, _, _ in
            self?.fetchLatestHeartRate()
        }
        store.execute(query)
        observerQuery = query
        fetchLatestHeartRate()
    }

    private func stopHeartRateObserver() {
        if let q = observerQuery { store.stop(q); observerQuery = nil }
    }

    private func fetchLatestHeartRate() {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let self, let sample = samples?.first as? HKQuantitySample else { return }
            // Pomijamy stare próbki (starsze niż 10 minut)
            guard sample.startDate > Date().addingTimeInterval(-600) else { return }
            let hr = sample.quantity.doubleValue(for: self.hrUnit)
            DispatchQueue.main.async { self.currentHeartRate = hr }
        }
        store.execute(query)
    }

    // MARK: - Post-workout stats query

    private func fetchHRStats(from start: Date, to end: Date) async -> (avgHR: Double?, maxHR: Double?) {
        await withCheckedContinuation { continuation in
            let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let statsQuery = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: pred,
                options: [.discreteAverage, .discreteMax]
            ) { [weak self] _, stats, _ in
                guard let self else { continuation.resume(returning: (nil, nil)); return }
                // flatMap flattens HKQuantity?? → HKQuantity? przed wywołaniem doubleValue
                let avg: Double? = stats.flatMap { $0.averageQuantity() }.map { $0.doubleValue(for: self.hrUnit).rounded() }
                let max: Double? = stats.flatMap { $0.maximumQuantity() }.map { $0.doubleValue(for: self.hrUnit).rounded() }
                continuation.resume(returning: (avg, max))
            }
            self.store.execute(statsQuery)
        }
    }
}
