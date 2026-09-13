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
                score: viewModel.score,
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
                choices: viewModel.currentChoices,
                selectedAnswer: viewModel.selectedAnswer,
                isAnswerSubmitted: viewModel.isAnswerSubmitted,
                didAnswerCorrectly: viewModel.didAnswerCorrectly,
                onSelectAnswer: viewModel.selectAnswer,
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
    let choices: [String]
    let selectedAnswer: String?
    let isAnswerSubmitted: Bool
    let didAnswerCorrectly: Bool
    let onSelectAnswer: (String) -> Void
    let onNextQuestion: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                progressSection

                Text(question.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Divider()

                choicesSection

                if isAnswerSubmitted {
                    feedbackSection
                }

                Button(action: onNextQuestion) {
                    Text(questionNumber == questionCount ? "Finalizar simulado" : "Próxima pergunta")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isAnswerSubmitted)
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

    var choicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Escolha uma resposta")
                .font(.headline)

            ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                Button {
                    onSelectAnswer(choice)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Text(optionLabel(for: index))
                            .fontWeight(.bold)
                            .frame(width: 28, height: 28)
                            .background(optionColor(for: choice))
                            .clipShape(Circle())

                        Text(choice)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)

                        if isAnswerSubmitted && choice == question.answer {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if isAnswerSubmitted && choice == selectedAnswer {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(optionBackground(for: choice))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(optionBorder(for: choice), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isAnswerSubmitted)
            }
        }
    }

    var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                didAnswerCorrectly ? "Resposta correta!" : "Resposta incorreta",
                systemImage: didAnswerCorrectly ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.headline)
            .foregroundStyle(didAnswerCorrectly ? .green : .red)

            if !didAnswerCorrectly {
                Text("Resposta correta")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(question.answer)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((didAnswerCorrectly ? Color.green : Color.red).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func optionLabel(for index: Int) -> String {
        String(UnicodeScalar(65 + index)!)
    }

    func optionColor(for choice: String) -> Color {
        if isAnswerSubmitted && choice == question.answer {
            return .green.opacity(0.2)
        }

        if isAnswerSubmitted && choice == selectedAnswer {
            return .red.opacity(0.2)
        }

        return .accentColor.opacity(0.12)
    }

    func optionBackground(for choice: String) -> Color {
        if isAnswerSubmitted && choice == question.answer {
            return .green.opacity(0.1)
        }

        if isAnswerSubmitted && choice == selectedAnswer {
            return .red.opacity(0.1)
        }

        return .gray.opacity(0.08)
    }

    func optionBorder(for choice: String) -> Color {
        if isAnswerSubmitted && choice == question.answer {
            return .green
        }

        if isAnswerSubmitted && choice == selectedAnswer {
            return .red
        }

        return .gray.opacity(0.25)
    }
}

private struct SimulationCompletionView: View {

    @Environment(\.dismiss)
    private var dismiss

    let questionCount: Int
    let score: Int
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Simulado concluído!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Você acertou \(score) de \(questionCount) perguntas.")
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
