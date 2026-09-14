//
//  AnswerEvaluation.swift
//  DevPrep
//

import Foundation

enum AnswerClassification: String, Codable, CaseIterable {
    case correct
    case partiallyCorrect
    case incorrect

    var displayName: String {
        switch self {
        case .correct:
            return "Correta"
        case .partiallyCorrect:
            return "Parcialmente correta"
        case .incorrect:
            return "Incorreta"
        }
    }
}

struct AnswerEvaluation: Codable, Equatable, Sendable {
    let score: Int
    let classification: AnswerClassification
    let strengths: [String]
    let missingPoints: [String]
    let improvedAnswer: String
    let didacticExplanation: String

    init(
        score: Int,
        classification: AnswerClassification,
        strengths: [String] = [],
        missingPoints: [String] = [],
        improvedAnswer: String = "",
        didacticExplanation: String = ""
    ) {
        self.score = min(max(score, 0), 10)
        self.classification = classification
        self.strengths = strengths
        self.missingPoints = missingPoints
        self.improvedAnswer = improvedAnswer
        self.didacticExplanation = didacticExplanation
    }
}
