//
//  QuestionAssistantViewModel.swift
//  DevPrep
//

import Foundation
import Observation

@MainActor
@Observable
final class QuestionAssistantViewModel {

    let question: Question

    private let aiService: AIService

    private(set) var prompt = ""
    private(set) var response: String?
    private(set) var isLoading = false
    private(set) var hasError = false

    init(
        question: Question,
        aiService: AIService? = nil
    ) {
        self.question = question
        self.aiService = aiService ?? DefaultAIService()
    }

    func updatePrompt(_ prompt: String) {
        self.prompt = prompt
    }

    func ask() async {
        guard !isLoading,
              !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isLoading = true
        hasError = false
        defer {
            isLoading = false
        }

        do {
            response = try await aiService.answer(
                question: question,
                userPrompt: prompt
            )
        } catch {
            hasError = true
        }
    }
}
