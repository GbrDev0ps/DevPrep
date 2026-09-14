//
//  SimulationScoringService.swift
//  DevPrep
//

import Foundation

struct SimulationQuestionResult: Codable, Equatable, Identifiable {
    let questionID: String
    let questionTitle: String
    let category: Category
    let score: Int
    let isCorrect: Bool

    var id: String {
        questionID
    }

    var needsReview: Bool {
        score < 7
    }
}

struct SimulationCategoryPerformance: Codable, Equatable, Identifiable {
    let category: Category
    let totalQuestions: Int
    let correctAnswers: Int

    var id: String {
        category.rawValue
    }

    var percentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctAnswers) / Double(totalQuestions) * 100).rounded())
    }
}

struct SimulationResult: Codable, Equatable, Identifiable {
    let id: UUID
    let simulationID: UUID
    let startedAt: Date
    let completedAt: Date
    let questionResults: [SimulationQuestionResult]
    let aiSummary: String?

    var totalQuestions: Int {
        questionResults.count
    }

    var correctAnswers: Int {
        questionResults.filter(\.isCorrect).count
    }

    var percentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctAnswers) / Double(totalQuestions) * 100).rounded())
    }

    var averageScore: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(questionResults.reduce(0) { $0 + $1.score }) / Double(totalQuestions)
    }

    var categoryPerformance: [SimulationCategoryPerformance] {
        Dictionary(grouping: questionResults, by: \.category)
            .map { category, results in
                SimulationCategoryPerformance(
                    category: category,
                    totalQuestions: results.count,
                    correctAnswers: results.filter(\.isCorrect).count
                )
            }
            .sorted { $0.category.rawValue < $1.category.rawValue }
    }

    var questionsToReview: [SimulationQuestionResult] {
        questionResults.filter(\.needsReview)
    }

    init(
        id: UUID = UUID(),
        simulationID: UUID,
        startedAt: Date,
        completedAt: Date,
        questionResults: [SimulationQuestionResult],
        aiSummary: String? = nil
    ) {
        self.id = id
        self.simulationID = simulationID
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.questionResults = questionResults
        self.aiSummary = aiSummary
    }
}

struct SimulationScoringService {

    func makeQuestionResult(
        for question: Question,
        selectedAnswer: String?
    ) -> SimulationQuestionResult {
        let isCorrect = selectedAnswer == question.answer

        return SimulationQuestionResult(
            questionID: question.id,
            questionTitle: question.title,
            category: question.category,
            score: isCorrect ? 10 : 0,
            isCorrect: isCorrect
        )
    }

    func makeQuestionResult(
        for question: Question,
        score: Int,
        isCorrect: Bool? = nil
    ) -> SimulationQuestionResult {
        let normalizedScore = min(max(score, 0), 10)

        return SimulationQuestionResult(
            questionID: question.id,
            questionTitle: question.title,
            category: question.category,
            score: normalizedScore,
            isCorrect: isCorrect ?? (normalizedScore >= 7)
        )
    }

    func makeResult(
        for simulation: Simulation,
        questionResults: [SimulationQuestionResult],
        completedAt: Date = Date(),
        aiSummary: String? = nil
    ) -> SimulationResult {
        SimulationResult(
            simulationID: simulation.id,
            startedAt: simulation.startedAt,
            completedAt: completedAt,
            questionResults: questionResults,
            aiSummary: aiSummary
        )
    }
}
