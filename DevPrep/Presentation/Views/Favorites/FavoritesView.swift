//
//  FavoritesView.swift
//  DevPrep
//

import SwiftUI

struct FavoritesView: View {

    @Environment(FavoritesStore.self)
    private var favoritesStore

    @State
    private var viewModel: FavoritesViewModel

    init() {
        _viewModel = State(
            initialValue: FavoritesViewModel(
                repository: JSONQuestionRepository()
            )
        )
    }

    var body: some View {
        content
            .navigationTitle(AppStrings.Home.favorites)
            .task {
                await viewModel.loadQuestions()
            }
    }
}

private extension FavoritesView {

    @ViewBuilder
    var content: some View {
        if viewModel.isLoading && viewModel.questions.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.hasLoadError {
            ContentUnavailableView {
                Label("Não foi possível carregar", systemImage: "exclamationmark.triangle")
            } description: {
                Text("Tente novamente em alguns instantes.")
            } actions: {
                Button("Tentar novamente") {
                    Task {
                        await viewModel.loadQuestions()
                    }
                }
            }
        } else if favoriteQuestions.isEmpty {
            ContentUnavailableView {
                Label("Nenhuma pergunta favorita", systemImage: "star")
            } description: {
                Text("Toque na estrela de uma pergunta para adicioná-la aos favoritos.")
            }
        } else {
            List(favoriteQuestions) { question in
                HStack(spacing: 12) {
                    NavigationLink {
                        QuestionDetailView(question: question)
                    } label: {
                        QuestionSummary(question: question)
                    }

                    FavoriteToggleButton(question: question)
                }
            }
        }
    }

    var favoriteQuestions: [Question] {
        viewModel.questions.filter { favoritesStore.isFavorite($0) }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environment(FavoritesStore())
}
