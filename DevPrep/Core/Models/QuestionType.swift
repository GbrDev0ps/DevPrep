//
//  QuestionType.swift
//  DevPrep
//

import Foundation

enum QuestionType: String, Codable, CaseIterable {
    case conceptual
    case practicalScenario
    case codeAnalysis
    case bugFix
    case architectureDecision
    case behavioral
    case openEnded

    var defaultResponseType: ResponseType {
        switch self {
        case .codeAnalysis, .bugFix, .architectureDecision, .behavioral, .openEnded:
            return .freeText
        case .conceptual, .practicalScenario:
            return .multipleChoice
        }
    }
}
