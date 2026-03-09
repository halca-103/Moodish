//
//  HealthKitService.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/06.
//
import Foundation
import HealthKit

@Observable
class HealthKitService {
    enum AuthorizationState {
        case notAvailable
        case notDetermined
        case denied
        case authorized
    }

    private let store = HKHealthStore()
    private let hasRequestedKey = "healthkit_has_requested_authorization"
    var isAuthorized = false
    var authorizationState: AuthorizationState = .notDetermined

    private var readTypes: Set<HKObjectType> {
        [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        ]
    }

    // 権限リクエスト
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationState = .notAvailable
            print("HealthKit: このデバイスではHealthデータが利用できません（Simulatorの可能性あり）")
            return
        }

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            UserDefaults.standard.set(true, forKey: hasRequestedKey)
            isAuthorized = true
            authorizationState = .authorized
            print("HealthKit: requestAuthorization completed")
        } catch {
            print("HealthKit認証エラー: \(error)")
            refreshAuthorizationStatus()
        }
    }

    func refreshAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationState = .notAvailable
            isAuthorized = false
            return
        }

        store.getRequestStatusForAuthorization(toShare: [], read: readTypes) { [weak self] status, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                switch status {
                case .shouldRequest:
                    self.authorizationState = .notDetermined
                    self.isAuthorized = false
                case .unknown:
                    self.authorizationState = .notDetermined
                    self.isAuthorized = false
                case .unnecessary:
                    // Read権限の可否は厳密判定できないため、少なくとも許可フロー完了済みなら連携中として扱う
                    let hasRequested = UserDefaults.standard.bool(forKey: self.hasRequestedKey)
                    self.authorizationState = hasRequested ? .authorized : .notDetermined
                    self.isAuthorized = hasRequested
                @unknown default:
                    self.authorizationState = .notDetermined
                    self.isAuthorized = false
                }
            }
        }
    }

    // 直近の睡眠時間（時間単位）
    func fetchSleepHours() async -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let now = Date()
        guard let start = Calendar.current.date(byAdding: .hour, value: -36, to: now) else { return nil }
        let end = now

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                // asleep のみ合計
                let totalSeconds = samples
                    .filter { sample in
                        // iOSの睡眠ステージ表現を網羅して集計
                        sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                            || sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                            || sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                            || sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                if totalSeconds > 0 {
                    print("HealthKit: sleep samples=\(samples.count), totalHours=\(totalSeconds / 3600)")
                    continuation.resume(returning: totalSeconds / 3600)
                    return
                }

                // 一部データソースで asleep が無い場合のフォールバック
                let inBedSeconds = samples
                    .filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                print("HealthKit: asleep=0, fallback inBedHours=\(inBedSeconds / 3600), samples=\(samples.count)")
                continuation.resume(returning: inBedSeconds > 0 ? inBedSeconds / 3600 : nil)
            }
            self.store.execute(query)
            
            
        }
    }

    // 当日の歩数
    func fetchStepCount() async -> Int? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: steps.map { Int($0) })
            }
            self.store.execute(query)
        }
    }

    // 睡眠・歩数まとめて取得
    func fetchTodayData() async -> (sleepHours: Double?, stepCount: Int?) {
        async let sleep = fetchSleepHours()
        //async let steps = fetchStepCount()
        return await (sleep, nil)
    }
}
