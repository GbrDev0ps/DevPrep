//
//  QuestionAssistantView.swift
//  DevPrep
//

import SwiftUI

struct QuestionAssistantView: View {

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var viewModel: QuestionAssistantViewModel

    init(question: Question) {
        _viewModel = State(
            initialValue: QuestionAssistantViewModel(question: question)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(viewModel.question.title)
                        .font(.headline)

                    Text("Peça uma explicação, um exemplo ou uma comparação.")
                        .foregroundStyle(.secondary)

                    TextEditor(
                        text: Binding(
                            get: { viewModel.prompt },
                            set: viewModel.updatePrompt
                        )
                    )
                    .frame(minHeight: 120)
                    .padding(8)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3))
                    }

                    Button {
                        Task {
                            await viewModel.ask()
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Perguntar", systemImage: "paperplane.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        viewModel.isLoading ||
                            viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )

                    if let response = viewModel.response {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Resposta", systemImage: "sparkles")
                                .font(.headline)
                            Text(response)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    if viewModel.hasError {
                        Text("Não foi possível responder agora. Tente novamente.")
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Perguntar à IA")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar", action: dismiss.callAsFunction)
                }
            }
        }
    }
}
