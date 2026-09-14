//
//  SimulationHistoryStore.swift
//  DevPrep
//

import Foundation
import Observation

@MainActor
@Observable
final class SimulationHistoryStore {

    private static let storageKey = "simulationHistory"
    private static let maxStoredResults = 20

    private let userDefaults: UserDefaults
    private(set) var results: [SimulationResult]

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        guard let data = userDefaults.data(forKey: Self.storageKey),
              let storedResults = try? JSONDecoder().decode(
                  [SimulationResult].self,
                  from: data
              ) else {
            self.results = []
            return
        }

        self.results = storedResults
    }

    func save(_ result: SimulationResult) {
        results.insert(result, at: 0)
        results = Array(results.prefix(Self.maxStoredResults))

        if let data = try? JSONEncoder().encode(results) {
            userDefaults.set(data, forKey: Self.storageKey)
        }
    }
}
