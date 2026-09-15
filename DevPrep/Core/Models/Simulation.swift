//
//  Simulation.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import Foundation

struct Simulation: Codable, Identifiable {
    let id: UUID
    let questions: [Question]
    let startedAt: Date

    init(
        id: UUID = UUID(),
        questions: [Question],
        startedAt: Date = Date()
    ) {
        self.id = id
        self.questions = questions
        self.startedAt = startedAt
    }
}
