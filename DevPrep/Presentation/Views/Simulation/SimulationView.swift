//
//  SimulationView.swift
//  DevPrep
//

import SwiftUI

struct SimulationView: View {

    @State
    private var viewModel: SimulationViewModel

    init() {
        _viewModel = State(
            initialValue: SimulationViewModel(
                repository: JSONQuestionRepository()
            )
        )
    }

    var body: some View {
        content
            .navigationTitle(AppStrings.Home.simulations)
            .task {
                await viewModel.start()
            }
    }
}

private extension SimulationView {

    @ViewBuilder
    var content: some View {
        if viewModel.isLoading || viewModel.simulation == nil && !viewModel.hasLoadError {
            ProgressView("Preparando simulado...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.hasLoadError {
            ContentUnavailableView {
                Label("Não foi possível carregar", systemImage: "exclamationmark.triangle")
            } description: {
                Text("Tente novamente em alguns instantes.")
            } actions: {
                Button("Tentar novamente") {
                    Task {
                        await viewModel.start()
                    }
                }
            }
        } else if viewModel.isFinished {
            SimulationCompletionView(
                questionCount: viewModel.simulation?.questions.count ?? 0,
                onRestart: {
                    Task {
                        await viewModel.start()
                    }
                }
            )
        } else if let question = viewModel.currentQuestion,
                  let questionCount = viewModel.simulation?.questions.count {
            SimulationQuestionView(
                question: question,
                questionNumber: viewModel.questionNumber,
                questionCount: questionCount,
                progress: viewModel.progress,
                isAnswerRevealed: viewModel.isAnswerRevealed,
                onRevealAnswer: viewModel.revealAnswer,
                onNextQuestion: viewModel.nextQuestion
            )
        }
    }
}

private struct SimulationQuestionView: View {

    let question: Question
    let questionNumber: Int
    let questionCount: Int
    let progress: Double
    let isAnswerRevealed: Bool
    let onRevealAnswer: () -> Void
    let onNextQuestion: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                progressSection

                Text(question.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Divider()

                if isAnswerRevealed {
                    answerSection
                } else {
                    Button(action: onRevealAnswer) {
                        Label("Mostrar resposta", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button(action: onNextQuestion) {
                    Text(questionNumber == questionCount ? "Finalizar simulado" : "Próxima pergunta")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}

private extension SimulationQuestionView {

    var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Pergunta \(questionNumber) de \(questionCount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(question.difficulty.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(.accentColor)
        }
    }

    var answerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Resposta", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.green)

            Text(question.answer)

            if let example = question.example {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exemplo")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(example)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct SimulationCompletionView: View {

    @Environment(\.dismiss)
    private var dismiss

    let questionCount: Int
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Simulado concluído!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Você revisou \(questionCount) perguntas. Continue praticando para chegar cada vez mais preparado.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Fazer novamente", action: onRestart)
                .buttonStyle(.borderedProminent)

            Button("Voltar", action: dismiss.callAsFunction)
                .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        SimulationView()
    }
}
