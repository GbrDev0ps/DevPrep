//
//  Question.swift
//  DevPrep
//
//  Created by Gabriel Monte Olivio Martins on 07/06/26.
//

import Foundation

struct Question: Codable, Identifiable {
    let id: String
    let title: String
    let answer: String
    let example: String?    
    let category: Category
    let difficulty: Difficulty
    let tags: [String]?
}
