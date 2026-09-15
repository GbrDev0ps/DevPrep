//
//  QuestionDetail.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import SwiftUI

struct QuestionDetailView: View {

    let question: Question
    @State private var isShowingAssistant = false

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text(question.title)
                    .font(.title)

                Text(question.answer)

                if let codeExample = question.codeExample {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exemplo")
                            .font(.headline)
                        Text(codeExample)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Button {
                    isShowingAssistant = true
                } label: {
                    Label("Perguntar à IA", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Pergunta")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                FavoriteToggleButton(question: question)
            }
        }
        .sheet(isPresented: $isShowingAssistant) {
            QuestionAssistantView(question: question)
        }
    }
}
