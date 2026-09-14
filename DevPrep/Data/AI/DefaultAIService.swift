//
//  DefaultAIService.swift
//  DevPrep
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct DefaultAIService: AIService {
    private let offlineService = OfflineAIService()

    func evaluate(
        answer: String,
        for question: Question
    ) async throws -> AnswerEvaluation {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *),
           SystemLanguageModel.default.availability == .available {
            do {
                return try await FoundationModelsAIService().evaluate(
                    answer: answer,
                    for: question
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // A falha do modelo local não interrompe o estudo offline.
            }
        }
        #endif

        return try await offlineService.evaluate(answer: answer, for: question)
    }

    func answer(
        question: Question,
        userPrompt: String
    ) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *),
           SystemLanguageModel.default.availability == .available {
            do {
                return try await FoundationModelsAIService().answer(
                    question: question,
                    userPrompt: userPrompt
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // A falha do modelo local não interrompe o estudo offline.
            }
        }
        #endif

        return try await offlineService.answer(
            question: question,
            userPrompt: userPrompt
        )
    }

    func summarize(result: SimulationResult) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *),
           SystemLanguageModel.default.availability == .available {
            do {
                return try await FoundationModelsAIService().summarize(result: result)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // A falha do modelo local não interrompe o estudo offline.
            }
        }
        #endif

        return try await offlineService.summarize(result: result)
    }
}
