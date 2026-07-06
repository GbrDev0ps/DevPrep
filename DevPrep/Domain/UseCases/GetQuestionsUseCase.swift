//
//  GetQuestionsUseCase.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

protocol GetQuestionsUseCase {
    func execute() async throws -> [Question]
}


final class DefaultGetQuestionsUseCase: GetQuestionsUseCase {

    private let repository: QuestionRepository

    init(repository: QuestionRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Question] {
        try await repository.fetchQuestions()
    }
}
