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

            HStack(spacing: 12) {
                NavigationLink {
                    QuestionDetailView(question: question)
                } label: {
                    QuestionSummary(question: question)
                }

                FavoriteToggleButton(question: question)
            }
        }
        .navigationTitle(viewModel.category.rawValue)
        .task {
            await viewModel.loadQuestions()
        }
    }
}

struct QuestionSummary: View {

    let question: Question

    var body: some View {
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

struct FavoriteToggleButton: View {

    @Environment(FavoritesStore.self)
    private var favoritesStore

    let question: Question

    var body: some View {
        Button {
            favoritesStore.toggle(question)
        } label: {
            Image(systemName: favoritesStore.isFavorite(question) ? "star.fill" : "star")
                .foregroundStyle(.yellow)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(
            favoritesStore.isFavorite(question)
                ? "Remover dos favoritos"
                : "Adicionar aos favoritos"
        )
    }
}
