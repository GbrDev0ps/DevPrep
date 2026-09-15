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
    private let optionBuilder: QuestionOptionBuilder
    private let scoringService: SimulationScoringService
    private let aiService: AIService
    private var historyStore: SimulationHistoryStore

    private(set) var simulation: Simulation?
    private(set) var currentIndex = 0
    private(set) var selectedAnswer: String?
    private(set) var isAnswerSubmitted = false
    private(set) var freeTextAnswer = ""
    private(set) var answerEvaluation: AnswerEvaluation?
    private(set) var evaluationError: String?
    private(set) var isEvaluatingAnswer = false
    private(set) var isLoading = false
    private(set) var hasLoadError = false
    private(set) var isFinished = false
    private(set) var simulationResult: SimulationResult?

    private var answerChoicesByQuestionID: [String: [AnswerOption]] = [:]
    private var questionResults: [SimulationQuestionResult] = []

    init(
        repository: QuestionRepository,
        optionBuilder: QuestionOptionBuilder? = nil,
        scoringService: SimulationScoringService? = nil,
        aiService: AIService? = nil,
        historyStore: SimulationHistoryStore? = nil
    ) {
        self.repository = repository
        self.optionBuilder = optionBuilder ?? QuestionOptionBuilder()
        self.scoringService = scoringService ?? SimulationScoringService()
        self.aiService = aiService ?? DefaultAIService()
        self.historyStore = historyStore ?? SimulationHistoryStore()
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

    var currentChoices: [AnswerOption] {
        guard let questionID = currentQuestion?.id else { return [] }
        return answerChoicesByQuestionID[questionID] ?? []
    }

    var didAnswerCorrectly: Bool {
        answerEvaluation?.classification == .correct ||
            (selectedAnswer != nil && selectedAnswer == currentQuestion?.answer)
    }

    var score: Int {
        questionResults.filter(\.isCorrect).count
    }

    func start() async {
        isLoading = true
        hasLoadError = false
        isFinished = false
        currentIndex = 0
        selectedAnswer = nil
        isAnswerSubmitted = false
        freeTextAnswer = ""
        answerEvaluation = nil
        evaluationError = nil
        isEvaluatingAnswer = false
        simulationResult = nil
        answerChoicesByQuestionID = [:]
        questionResults = []

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

            for question in selectedQuestions where question.responseType == .multipleChoice {
                answerChoicesByQuestionID[question.id] = try optionBuilder.buildOptions(
                    for: question,
                    from: allQuestions
                )
            }
        } catch is CancellationError {
            return
        } catch {
            simulation = nil
            hasLoadError = true
            dump(error)
        }
    }

    func selectAnswer(_ answer: String) {
        guard !isAnswerSubmitted,
              currentChoices.contains(where: { $0.text == answer }),
              let currentQuestion else {
            return
        }

        selectedAnswer = answer
        isAnswerSubmitted = true

        questionResults.append(
            scoringService.makeQuestionResult(
                for: currentQuestion,
                selectedAnswer: answer
            )
        )
    }

    func updateFreeTextAnswer(_ answer: String) {
        guard !isAnswerSubmitted else { return }
        freeTextAnswer = answer
    }

    func submitFreeTextAnswer() async {
        guard !isAnswerSubmitted,
              !isEvaluatingAnswer,
              let currentQuestion,
              !freeTextAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isEvaluatingAnswer = true
        evaluationError = nil
        defer {
            isEvaluatingAnswer = false
        }

        do {
            let evaluation = try await aiService.evaluate(
                answer: freeTextAnswer,
                for: currentQuestion
            )
            answerEvaluation = evaluation
            isAnswerSubmitted = true
            questionResults.append(
                scoringService.makeQuestionResult(
                    for: currentQuestion,
                    score: evaluation.score
                )
            )
        } catch is CancellationError {
            return
        } catch {
            answerEvaluation = nil
            evaluationError = "Não foi possível avaliar sua resposta."
        }
    }

    func skipCurrentQuestion() {
        guard !isAnswerSubmitted,
              let currentQuestion else {
            return
        }

        evaluationError = nil
        isAnswerSubmitted = true
        questionResults.append(
            scoringService.makeQuestionResult(
                for: currentQuestion,
                score: 0
            )
        )
    }

    func nextQuestion() async {
        guard let questionCount = simulation?.questions.count,
              questionCount > 0,
              isAnswerSubmitted else {
            return
        }

        if currentIndex + 1 >= questionCount {
            await completeSimulation()
        } else {
            currentIndex += 1
            selectedAnswer = nil
            isAnswerSubmitted = false
            freeTextAnswer = ""
            answerEvaluation = nil
            evaluationError = nil
        }
    }

    private func completeSimulation() async {
        guard let simulation else { return }

        let baseResult = scoringService.makeResult(
            for: simulation,
            questionResults: questionResults
        )

        let summary: String?
        do {
            summary = try await aiService.summarize(result: baseResult)
        } catch is CancellationError {
            return
        } catch {
            summary = nil
        }

        let finalResult = scoringService.makeResult(
            for: simulation,
            questionResults: questionResults,
            aiSummary: summary
        )

        simulationResult = finalResult
        historyStore.save(finalResult)
        isFinished = true
    }
}
