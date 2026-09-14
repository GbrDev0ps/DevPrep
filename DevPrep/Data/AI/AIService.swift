//
//  AIService.swift
//  DevPrep
//

import Foundation

enum AIServiceError: Error, Equatable {
    case unavailable
    case invalidResponse
}

protocol AIService {
    func evaluate(answer: String, for question: Question) async throws -> AnswerEvaluation
    func answer(question: Question, userPrompt: String) async throws -> String
    func summarize(result: SimulationResult) async throws -> String
}
