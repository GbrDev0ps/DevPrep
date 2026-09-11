//
//  SimulationViewModel.swift
//  DevPrep
//

import Foundation
import Observation

@MainActor
@Observable
final class SimulationViewModel {

    static let questionCount = 10

    private let repository: QuestionRepository

    private(set) var simulation: Simulation?
    private(set) var currentIndex = 0
    private(set) var isAnswerRevealed = false
    private(set) var isLoading = false
    private(set) var hasLoadError = false
    private(set) var isFinished = false

    init(repository: QuestionRepository) {
        self.repository = repository
    }

    var currentQuestion: Question? {
        guard let questions = simulation?.questions,
              questions.indices.contains(currentIndex) else {
            return nil
        }

        return questions[currentIndex]
    }

    var questionNumber: Int {
        currentIndex + 1
    }

    var progress: Double {
        guard let questionCount = simulation?.questions.count,
              questionCount > 0 else {
            return 0
        }

        return Double(questionNumber) / Double(questionCount)
    }

    func start() async {
        isLoading = true
        hasLoadError = false
        isFinished = false
        currentIndex = 0
        isAnswerRevealed = false

        defer {
            isLoading = false
        }

        do {
            let allQuestions = try await repository.fetchQuestions()
            let selectedQuestions = Array(
                allQuestions.shuffled().prefix(Self.questionCount)
            )

            simulation = Simulation(
                questions: selectedQuestions,
                startedAt: Date()
            )
        } catch {
            simulation = nil
            hasLoadError = true
            dump(error)
        }
    }

    func revealAnswer() {
        guard currentQuestion != nil else { return }
        isAnswerRevealed = true
    }

    func nextQuestion() {
        guard let questionCount = simulation?.questions.count,
              questionCount > 0 else {
            return
        }

        if currentIndex + 1 >= questionCount {
            isFinished = true
        } else {
            currentIndex += 1
            isAnswerRevealed = false
        }
    }
}
