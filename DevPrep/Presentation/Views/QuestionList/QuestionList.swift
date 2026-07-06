//
//  QuestionList.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import SwiftUI

struct QuestionListView: View {

    @State
    private var viewModel: QuestionListViewModel

    init(category: Category) {

        _viewModel = State(
            initialValue: QuestionListViewModel(
                category: category,
                repository: JSONQuestionRepository()
            )
        )
    }

    var body: some View {

        List(viewModel.questions) { question in

            NavigationLink {
                QuestionDetailView(question: question)
            } label: {

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    Text(question.title)
                        .font(.headline)

                    Text(question.difficulty.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(viewModel.category.rawValue)
        .task {
            await viewModel.loadQuestions()
        }
    }
}
