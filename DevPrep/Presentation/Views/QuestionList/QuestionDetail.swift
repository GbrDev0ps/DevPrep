//
//  QuestionDetail.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import SwiftUI

struct QuestionDetailView: View {

    let question: Question

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text(question.title)
                    .font(.title)

                Text(question.answer)
            }
            .padding()
        }
        .navigationTitle("Pergunta")
    }
}
