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
    let questionType: QuestionType
    let responseType: ResponseType
    let codeExample: String?
    let distractors: [String]?
    let evaluationCriteria: [String]?
    let followUpQuestions: [String]?

    init(
        id: String,
        title: String,
        answer: String,
        example: String? = nil,
        category: Category,
        difficulty: Difficulty,
        tags: [String]? = nil,
        questionType: QuestionType = .conceptual,
        responseType: ResponseType? = nil,
        codeExample: String? = nil,
        distractors: [String]? = nil,
        evaluationCriteria: [String]? = nil,
        followUpQuestions: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.answer = answer
        self.example = example
        self.category = category
        self.difficulty = difficulty
        self.tags = tags
        self.questionType = questionType
        self.responseType = responseType ?? questionType.defaultResponseType
        self.codeExample = codeExample
        self.distractors = distractors
        self.evaluationCriteria = evaluationCriteria
        self.followUpQuestions = followUpQuestions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        answer = try container.decode(String.self, forKey: .answer)
        example = try container.decodeIfPresent(String.self, forKey: .example)
        category = try container.decode(Category.self, forKey: .category)
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        codeExample = try container.decodeIfPresent(String.self, forKey: .codeExample)
        distractors = try container.decodeIfPresent([String].self, forKey: .distractors)
        evaluationCriteria = try container.decodeIfPresent(
            [String].self,
            forKey: .evaluationCriteria
        )
        followUpQuestions = try container.decodeIfPresent(
            [String].self,
            forKey: .followUpQuestions
        )

        let decodedQuestionType = try container.decodeIfPresent(
            QuestionType.self,
            forKey: .questionType
        ) ?? (category == .behavioral ? .behavioral : .conceptual)

        questionType = decodedQuestionType
        responseType = try container.decodeIfPresent(
            ResponseType.self,
            forKey: .responseType
        ) ?? decodedQuestionType.defaultResponseType
    }
}
