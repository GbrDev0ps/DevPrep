//
//  QuestionRepository.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import Foundation

protocol QuestionRepository {
    func fetchQuestions() async throws -> [Question]
}
