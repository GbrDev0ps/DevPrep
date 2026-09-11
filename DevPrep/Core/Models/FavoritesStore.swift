//
//  FavoritesStore.swift
//  DevPrep
//

import Foundation
import Observation

@MainActor
@Observable
final class FavoritesStore {

    private static let storageKey = "favoriteQuestionIDs"

    private let userDefaults: UserDefaults

    private(set) var favoriteQuestionIDs: Set<String>

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.favoriteQuestionIDs = Set(
            userDefaults.stringArray(forKey: Self.storageKey) ?? []
        )
    }

    func isFavorite(_ question: Question) -> Bool {
        favoriteQuestionIDs.contains(question.id)
    }

    func toggle(_ question: Question) {
        toggle(questionID: question.id)
    }

    func toggle(questionID: String) {
        if favoriteQuestionIDs.contains(questionID) {
            favoriteQuestionIDs.remove(questionID)
        } else {
            favoriteQuestionIDs.insert(questionID)
        }

        userDefaults.set(
            Array(favoriteQuestionIDs),
            forKey: Self.storageKey
        )
    }
}
