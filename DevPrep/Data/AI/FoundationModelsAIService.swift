//
//  FoundationModelsAIService.swift
//  DevPrep
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct FoundationModelsAIService: AIService {

    func evaluate(
        answer: String,
        for question: Question
    ) async throws -> AnswerEvaluation {
        let payload: FoundationModelEvaluation = try await respond(
            to: evaluationPrompt(answer: answer, question: question),
            generating: FoundationModelEvaluation.self
        )

        guard let classification = AnswerClassification(rawValue: payload.classification) else {
            throw AIServiceError.invalidResponse
        }

        return AnswerEvaluation(
            score: payload.score,
            classification: classification,
            strengths: payload.strengths,
            missingPoints: payload.missingPoints,
            improvedAnswer: payload.improvedAnswer,
            didacticExplanation: payload.didacticExplanation
        )
    }

    func answer(
        question: Question,
        userPrompt: String
    ) async throws -> String {
        try await respond(
            to: """
            Você é um mentor de entrevistas iOS. Explique a pergunta abaixo em português claro.
            Pedido do usuário: \(userPrompt)
            Pergunta: \(question.title)
            Resposta de referência: \(question.answer)
            Exemplo de código: \(question.codeExample ?? "não há")
            """
        )
    }

    func summarize(result: SimulationResult) async throws -> String {
        try await respond(
            to: """
            Resuma o resultado deste simulado de entrevista iOS em português, em no máximo três frases.
            Acertos: \(result.correctAnswers) de \(result.totalQuestions)
            Percentual: \(result.percentage)%
            Categorias: \(result.categoryPerformance.map { "\($0.category.rawValue): \($0.percentage)%" }.joined(separator: ", "))
            Perguntas para revisar: \(result.questionsToReview.map(\.questionTitle).joined(separator: " | "))
            """
        )
    }
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
private extension FoundationModelsAIService {

    @Generable
    struct FoundationModelEvaluation {
        @Guide(description: "Nota inteira de 0 a 10.")
        let score: Int
        @Guide(description: "Use exatamente: correct, partiallyCorrect ou incorrect.")
        let classification: String
        let strengths: [String]
        let missingPoints: [String]
        let improvedAnswer: String
        let didacticExplanation: String
    }

    func respond<Content: Generable>(
        to prompt: String,
        generating type: Content.Type = Content.self
    ) async throws -> Content {
        guard SystemLanguageModel.default.availability == .available else {
            throw AIServiceError.unavailable
        }

        let session = LanguageModelSession(
            instructions: "Responda sempre em português. Seja objetivo, didático e não invente fatos."
        )
        let response = try await session.respond(to: prompt, generating: type)
        return response.content
    }

    func respond(to prompt: String) async throws -> String {
        guard SystemLanguageModel.default.availability == .available else {
            throw AIServiceError.unavailable
        }

        let session = LanguageModelSession(
            instructions: "Responda sempre em português. Seja objetivo, didático e não invente fatos."
        )
        let response = try await session.respond(to: prompt)
        return response.content
    }

    func evaluationPrompt(answer: String, question: Question) -> String {
        """
        Avalie a resposta de um candidato a uma entrevista iOS.
        Pergunta: \(question.title)
        Resposta de referência: \(question.answer)
        Critérios: \(question.evaluationCriteria?.joined(separator: " | ") ?? "avaliar conceito, contexto e trade-offs")
        Resposta do candidato: \(answer)
        Gere uma nota de 0 a 10, a classificação solicitada e feedback acionável.
        """
    }
}
#endif
