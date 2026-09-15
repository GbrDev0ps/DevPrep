//
//  SimulationHistoryView.swift
//  DevPrep
//

import SwiftUI

struct SimulationHistoryView: View {

    @State
    private var historyStore = SimulationHistoryStore()

    var body: some View {
        Group {
            if historyStore.results.isEmpty {
                ContentUnavailableView(
                    "Nenhum simulado concluído",
                    systemImage: "clock",
                    description: Text("Seus resultados aparecerão aqui depois do primeiro simulado.")
                )
            } else {
                List(historyStore.results) { result in
                    NavigationLink {
                        SimulationHistoryDetailView(result: result)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.completedAt, style: .date)
                                    .font(.headline)
                                Text("\(result.correctAnswers)/\(result.totalQuestions) acertos")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(result.percentage)%")
                                .font(.headline)
                                .foregroundStyle(result.percentage >= 70 ? .green : .orange)
                        }
                    }
                }
            }
        }
        .navigationTitle("Histórico")
    }
}

private struct SimulationHistoryDetailView: View {

    let result: SimulationResult

    var body: some View {
        List {
            Section("Resultado") {
                LabeledContent("Pontuação", value: "\(result.correctAnswers)/\(result.totalQuestions)")
                LabeledContent("Percentual", value: "\(result.percentage)%")
                LabeledContent("Nota média", value: String(format: "%.1f/10", result.averageScore))
            }

            Section("Desempenho por categoria") {
                ForEach(result.categoryPerformance) { performance in
                    LabeledContent(
                        performance.category.rawValue,
                        value: "\(performance.percentage)%"
                    )
                }
            }

            if !result.questionsToReview.isEmpty {
                Section("Perguntas para revisar") {
                    ForEach(result.questionsToReview) { question in
                        Text(question.questionTitle)
                    }
                }
            }

            if let aiSummary = result.aiSummary {
                Section("Resumo") {
                    Text(aiSummary)
                }
            }
        }
        .navigationTitle("Detalhes")
    }
}
