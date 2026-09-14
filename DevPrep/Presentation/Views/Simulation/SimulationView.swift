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
        } else if viewModel.isFinished,
                  let result = viewModel.simulationResult {
            SimulationCompletionView(
                result: result,
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
                freeTextAnswer: viewModel.freeTextAnswer,
                answerEvaluation: viewModel.answerEvaluation,
                isAnswerSubmitted: viewModel.isAnswerSubmitted,
                isEvaluatingAnswer: viewModel.isEvaluatingAnswer,
                didAnswerCorrectly: viewModel.didAnswerCorrectly,
                onSelectAnswer: viewModel.selectAnswer,
                onUpdateFreeTextAnswer: viewModel.updateFreeTextAnswer,
                onSubmitFreeTextAnswer: {
                    Task {
                        await viewModel.submitFreeTextAnswer()
                    }
                },
                onNextQuestion: {
                    Task {
                        await viewModel.nextQuestion()
                    }
                }
            )
        }
    }
}

private struct SimulationQuestionView: View {

    let question: Question
    let questionNumber: Int
    let questionCount: Int
    let progress: Double
    let choices: [AnswerOption]
    let selectedAnswer: String?
    let freeTextAnswer: String
    let answerEvaluation: AnswerEvaluation?
    let isAnswerSubmitted: Bool
    let isEvaluatingAnswer: Bool
    let didAnswerCorrectly: Bool
    let onSelectAnswer: (String) -> Void
    let onUpdateFreeTextAnswer: (String) -> Void
    let onSubmitFreeTextAnswer: () -> Void
    let onNextQuestion: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                progressSection

                Text(question.title)
                    .font(.title2)
                    .fontWeight(.bold)

                if let codeExample = question.codeExample {
                    Text(codeExample)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Divider()

                if question.responseType == .multipleChoice {
                    choicesSection
                } else {
                    freeTextSection
                }

                if isAnswerSubmitted {
                    feedbackSection
                }

                Button(action: onNextQuestion) {
                    Text(questionNumber == questionCount ? "Finalizar simulado" : "Próxima pergunta")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isAnswerSubmitted || isEvaluatingAnswer)
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

            ForEach(Array(choices.enumerated()), id: \.element.id) { index, option in
                Button {
                    onSelectAnswer(option.text)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Text(optionLabel(for: index))
                            .fontWeight(.bold)
                            .frame(width: 28, height: 28)
                            .background(optionColor(for: option))
                            .clipShape(Circle())

                        Text(option.text)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)

                        if isAnswerSubmitted && option.isCorrect {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if isAnswerSubmitted && option.text == selectedAnswer {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(optionBackground(for: option))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(optionBorder(for: option), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isAnswerSubmitted)
            }
        }
    }

    var freeTextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Responda livremente")
                .font(.headline)

            TextEditor(
                text: Binding(
                    get: { freeTextAnswer },
                    set: onUpdateFreeTextAnswer
                )
            )
            .frame(minHeight: 150)
            .padding(8)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray.opacity(0.3))
            }
            .disabled(isAnswerSubmitted || isEvaluatingAnswer)

            Button(action: onSubmitFreeTextAnswer) {
                if isEvaluatingAnswer {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Enviar resposta")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                freeTextAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    isAnswerSubmitted ||
                    isEvaluatingAnswer
            )
        }
    }

    var feedbackSection: some View {
        Group {
            if let answerEvaluation {
                evaluationFeedback(answerEvaluation)
            } else {
                multipleChoiceFeedback
            }
        }
    }

    var multipleChoiceFeedback: some View {
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
        .feedbackContainer(color: didAnswerCorrectly ? .green : .red)
    }

    func evaluationFeedback(_ evaluation: AnswerEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    evaluation.classification.displayName,
                    systemImage: evaluation.classification == .correct
                        ? "checkmark.circle.fill"
                        : "exclamationmark.circle.fill"
                )
                .font(.headline)

                Spacer()

                Text("\(evaluation.score)/10")
                    .font(.headline)
            }

            feedbackList(title: "Pontos positivos", items: evaluation.strengths)
            feedbackList(title: "Pontos ausentes", items: evaluation.missingPoints)

            Text("Resposta de referência")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(evaluation.improvedAnswer)
                .font(.callout)

            Text(evaluation.didacticExplanation)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .feedbackContainer(color: evaluation.classification == .correct ? .green : .orange)
    }

    @ViewBuilder
    func feedbackList(title: String, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .font(.callout)
                }
            }
        }
    }

    func optionLabel(for index: Int) -> String {
        String(UnicodeScalar(65 + index)!)
    }

    func optionColor(for option: AnswerOption) -> Color {
        if isAnswerSubmitted && option.isCorrect {
            return .green.opacity(0.2)
        }

        if isAnswerSubmitted && option.text == selectedAnswer {
            return .red.opacity(0.2)
        }

        return .accentColor.opacity(0.12)
    }

    func optionBackground(for option: AnswerOption) -> Color {
        if isAnswerSubmitted && option.isCorrect {
            return .green.opacity(0.1)
        }

        if isAnswerSubmitted && option.text == selectedAnswer {
            return .red.opacity(0.1)
        }

        return .gray.opacity(0.08)
    }

    func optionBorder(for option: AnswerOption) -> Color {
        if isAnswerSubmitted && option.isCorrect {
            return .green
        }

        if isAnswerSubmitted && option.text == selectedAnswer {
            return .red
        }

        return .gray.opacity(0.25)
    }
}

private extension View {

    func feedbackContainer(color: Color) -> some View {
        padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct SimulationCompletionView: View {

    @Environment(\.dismiss)
    private var dismiss

    let result: SimulationResult
    let onRestart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: result.percentage >= 70 ? "checkmark.circle.fill" : "book.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(result.percentage >= 70 ? .green : .orange)
                    .frame(maxWidth: .infinity)

                Text("Simulado concluído!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)

                Text("Você acertou \(result.correctAnswers) de \(result.totalQuestions) perguntas.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)

                HStack {
                    resultMetric(title: "Acertos", value: "\(result.percentage)%")
                    resultMetric(title: "Nota média", value: String(format: "%.1f/10", result.averageScore))
                }

                if !result.categoryPerformance.isEmpty {
                    Text("Desempenho por categoria")
                        .font(.headline)

                    ForEach(result.categoryPerformance) { performance in
                        HStack {
                            Text(performance.category.rawValue)
                            Spacer()
                            Text("\(performance.correctAnswers)/\(performance.totalQuestions) • \(performance.percentage)%")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !result.questionsToReview.isEmpty {
                    Text("Perguntas para revisar")
                        .font(.headline)

                    ForEach(result.questionsToReview) { question in
                        Label(question.questionTitle, systemImage: "arrow.uturn.forward.circle")
                            .font(.callout)
                    }
                }

                if let aiSummary = result.aiSummary {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Resumo do seu desempenho", systemImage: "sparkles")
                            .font(.headline)
                        Text(aiSummary)
                            .font(.callout)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button("Fazer novamente", action: onRestart)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                Button("Voltar", action: dismiss.callAsFunction)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
    }

    private func resultMetric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        SimulationView()
    }
}
