//
//  JSONQuestionRepository.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import Foundation

final class JSONQuestionRepository: QuestionRepository {

    func fetchQuestions() async throws -> [Question] {

        guard let url = Bundle.main.url(
            forResource: "questions",
            withExtension: "json"
        ) else {

            print("JSON NÃO ENCONTRADO")
            throw RepositoryError.fileNotFound
        }

        print("JSON ENCONTRADO:", url)

        let data = try Data(contentsOf: url)

        let questions = try JSONDecoder()
            .decode([Question].self, from: data)

        print("QUESTIONS:", questions.count)

        return questions
    }
}
