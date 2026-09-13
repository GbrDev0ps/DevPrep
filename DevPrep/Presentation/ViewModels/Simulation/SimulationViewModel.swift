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
    private(set) var selectedAnswer: String?
    private(set) var isAnswerSubmitted = false
    private(set) var isLoading = false
    private(set) var hasLoadError = false
    private(set) var isFinished = false
    private(set) var score = 0

    private var answerChoicesByQuestionID: [String: [String]] = [:]

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

    var currentChoices: [String] {
        guard let questionID = currentQuestion?.id else { return [] }
        return answerChoicesByQuestionID[questionID] ?? []
    }

    var didAnswerCorrectly: Bool {
        guard let selectedAnswer,
              let currentQuestion else {
            return false
        }

        return selectedAnswer == currentQuestion.answer
    }

    func start() async {
        isLoading = true
        hasLoadError = false
        isFinished = false
        currentIndex = 0
        selectedAnswer = nil
        isAnswerSubmitted = false
        score = 0
        answerChoicesByQuestionID = [:]

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
            answerChoicesByQuestionID = Dictionary(
                uniqueKeysWithValues: selectedQuestions.map { question in
                    (
                        question.id,
                        makeChoices(for: question, from: allQuestions)
                    )
                }
            )
        } catch {
            simulation = nil
            hasLoadError = true
            dump(error)
        }
    }

    func selectAnswer(_ answer: String) {
        guard !isAnswerSubmitted,
              currentChoices.contains(answer),
              let currentQuestion else {
            return
        }

        selectedAnswer = answer
        isAnswerSubmitted = true

        if answer == currentQuestion.answer {
            score += 1
        }
    }

    func nextQuestion() {
        guard let questionCount = simulation?.questions.count,
              questionCount > 0,
              isAnswerSubmitted else {
            return
        }

        if currentIndex + 1 >= questionCount {
            isFinished = true
        } else {
            currentIndex += 1
            selectedAnswer = nil
            isAnswerSubmitted = false
        }
    }
}

private extension SimulationViewModel {

    func makeChoices(for question: Question, from allQuestions: [Question]) -> [String] {
        let sameLevelAndCategory = allQuestions.filter {
            $0.id != question.id &&
            $0.category == question.category &&
            $0.difficulty == question.difficulty
        }

        let sameCategory = allQuestions.filter {
            $0.id != question.id &&
            $0.category == question.category
        }

        let remainingQuestions = allQuestions.filter {
            $0.id != question.id
        }

        var choices = [question.answer]
        let candidates = (
            sameLevelAndCategory +
            sameCategory +
            remainingQuestions
        ).shuffled()

        for candidate in candidates where !choices.contains(candidate.answer) {
            choices.append(candidate.answer)

            if choices.count == 4 {
                break
            }
        }

        return choices.shuffled()
    }
}
