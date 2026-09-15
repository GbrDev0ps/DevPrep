//
//  QuestionOptionBuilder.swift
//  DevPrep
//

import Foundation

enum QuestionOptionError: Error, Equatable {
    case notMultipleChoice
    case insufficientOptions
    case duplicateDistractors
    case correctAnswerUsedAsDistractor
}

struct AnswerOption: Identifiable, Equatable {
    let text: String
    let isCorrect: Bool

    var id: String {
        text
    }
}

struct QuestionOptionBuilder {
    let requiredOptionCount = 4

    func buildOptions(
        for question: Question,
        from questionBank: [Question] = []
    ) throws -> [AnswerOption] {
        guard question.responseType == .multipleChoice else {
            throw QuestionOptionError.notMultipleChoice
        }

        let explicitDistractors = question.distractors ?? []
        let normalizedExplicitDistractors = explicitDistractors.map(normalize)

        if Set(normalizedExplicitDistractors).count != normalizedExplicitDistractors.count {
            throw QuestionOptionError.duplicateDistractors
        }

        if normalizedExplicitDistractors.contains(normalize(question.answer)) {
            throw QuestionOptionError.correctAnswerUsedAsDistractor
        }

        var distractors = explicitDistractors
        if distractors.count < requiredOptionCount - 1 {
            let fallbackCandidates = fallbackCandidates(
                for: question,
                from: questionBank
            )

            for candidate in fallbackCandidates where !contains(candidate.answer, in: distractors + [question.answer]) {
                distractors.append(candidate.answer)

                if distractors.count == requiredOptionCount - 1 {
                    break
                }
            }
        }

        guard distractors.count >= requiredOptionCount - 1 else {
            throw QuestionOptionError.insufficientOptions
        }

        let options = [AnswerOption(text: question.answer, isCorrect: true)] +
            distractors.prefix(requiredOptionCount - 1).map {
                AnswerOption(text: $0, isCorrect: false)
            }

        return options.shuffled()
    }
}

private extension QuestionOptionBuilder {

    func fallbackCandidates(
        for question: Question,
        from questionBank: [Question]
    ) -> [Question] {
        let availableQuestions = questionBank.filter {
            $0.id != question.id &&
            $0.responseType == .multipleChoice
        }

        let sameLevelAndCategory = availableQuestions.filter {
            $0.category == question.category &&
            $0.difficulty == question.difficulty
        }

        let sameCategory = availableQuestions.filter {
            $0.category == question.category
        }

        return (sameLevelAndCategory + sameCategory + availableQuestions).shuffled()
    }

    func contains(_ answer: String, in answers: [String]) -> Bool {
        answers.map(normalize).contains(normalize(answer))
    }

    func normalize(_ value: String) -> String {
        value
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
