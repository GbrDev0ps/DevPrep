//
//  FavoritesViewModel.swift
//  DevPrep
//

import Foundation
import Observation

@MainActor
@Observable
final class FavoritesViewModel {

    private let repository: QuestionRepository

    private(set) var questions: [Question] = []
    private(set) var isLoading = false
    private(set) var hasLoadError = false

    init(repository: QuestionRepository) {
        self.repository = repository
    }

    func loadQuestions() async {
        guard questions.isEmpty else { return }

        isLoading = true
        hasLoadError = false

        defer {
            isLoading = false
        }

        do {
            questions = try await repository.fetchQuestions()
        } catch {
            hasLoadError = true
            dump(error)
        }
    }
}
