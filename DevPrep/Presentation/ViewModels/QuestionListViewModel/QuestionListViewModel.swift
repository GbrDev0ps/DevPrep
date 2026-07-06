//
//  QuestionListViewModel.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import Foundation
import SwiftUI

@Observable
final class QuestionListViewModel {

    let category: Category

    private let repository: QuestionRepository

    var questions: [Question] = []

    init(
        category: Category,
        repository: QuestionRepository
    ) {
        self.category = category
        self.repository = repository
    }

    func loadQuestions() async {

        do {

            let allQuestions =
                try await repository.fetchQuestions()

            questions = allQuestions.filter {
                $0.category == category
            }

        } catch {
            dump(error)
        }
    }
}
