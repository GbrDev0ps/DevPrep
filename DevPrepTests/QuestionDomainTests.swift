//
//  QuestionDomainTests.swift
//  DevPrepTests
//

import XCTest
@testable import DevPrep

@MainActor
final class QuestionDomainTests: XCTestCase {

    func testLegacyQuestionUsesSafeDefaults() throws {
        let data = Data(
            """
            {
              "id": "legacy-1",
              "title": "O que é ARC?",
              "answer": "Gerenciamento automático de memória",
              "category": "Swift",
              "difficulty": "Junior"
            }
            """.utf8
        )

        let question = try JSONDecoder().decode(Question.self, from: data)

        XCTAssertEqual(question.questionType, .conceptual)
        XCTAssertEqual(question.responseType, .multipleChoice)
        XCTAssertNil(question.codeExample)
        XCTAssertNil(question.distractors)
    }

    func testEnrichedQuestionDecodesInterviewMetadata() throws {
        let data = Data(
            """
            {
              "id": "swift-1",
              "title": "Analise este acesso concorrente a um contador.",
              "answer": "Isolar o estado mutável com um actor",
              "category": "Swift",
              "difficulty": "Senior",
              "questionType": "codeAnalysis",
              "responseType": "freeText",
              "codeExample": "actor Counter { var value = 0 }",
              "evaluationCriteria": ["Identifica a corrida", "Propõe isolamento"],
              "followUpQuestions": ["Como testaria a solução?"]
            }
            """.utf8
        )

        let question = try JSONDecoder().decode(Question.self, from: data)

        XCTAssertEqual(question.questionType, .codeAnalysis)
        XCTAssertEqual(question.responseType, .freeText)
        XCTAssertEqual(question.codeExample, "actor Counter { var value = 0 }")
        XCTAssertEqual(question.evaluationCriteria?.count, 2)
        XCTAssertEqual(question.followUpQuestions?.first, "Como testaria a solução?")
    }

    func testBehavioralLegacyQuestionDefaultsToFreeText() throws {
        let data = Data(
            """
            {
              "id": "behavioral-1",
              "title": "Conte sobre um conflito técnico.",
              "answer": "Descrever contexto, ação e resultado.",
              "category": "Behavioral",
              "difficulty": "Mid"
            }
            """.utf8
        )

        let question = try JSONDecoder().decode(Question.self, from: data)

        XCTAssertEqual(question.questionType, .behavioral)
        XCTAssertEqual(question.responseType, .freeText)
    }
}

@MainActor
final class QuestionOptionBuilderTests: XCTestCase {

    private let builder = QuestionOptionBuilder()

    func testUsesSpecificDistractorsFromQuestion() throws {
        let question = makeQuestion(
            answer: "Usar um actor para proteger o estado",
            distractors: [
                "Adicionar um DispatchQueue global sem serialização",
                "Marcar a classe inteira como Observable",
                "Duplicar o estado em cada View"
            ]
        )

        let options = try builder.buildOptions(for: question)

        XCTAssertEqual(options.count, 4)
        XCTAssertEqual(options.filter(\.isCorrect).map(\.text), [question.answer])
        XCTAssertEqual(Set(options.map(\.text)).count, 4)
    }

    func testBuildsLegacyOptionsFromRelatedQuestions() throws {
        let question = makeQuestion(answer: "Resposta correta")
        let bank = [
            question,
            makeQuestion(id: "2", answer: "Distrator relacionado 1"),
            makeQuestion(id: "3", answer: "Distrator relacionado 2"),
            makeQuestion(id: "4", answer: "Distrator relacionado 3")
        ]

        let options = try builder.buildOptions(for: question, from: bank)

        XCTAssertEqual(options.count, 4)
        XCTAssertTrue(options.contains { $0.text == question.answer && $0.isCorrect })
        XCTAssertEqual(options.filter { !$0.isCorrect }.count, 3)
    }

    func testRejectsCorrectAnswerAsDistractor() {
        let question = makeQuestion(
            answer: "Resposta correta",
            distractors: ["Resposta correta", "Outra opção", "Mais uma opção"]
        )

        XCTAssertThrowsError(try builder.buildOptions(for: question)) { error in
            XCTAssertEqual(error as? QuestionOptionError, .correctAnswerUsedAsDistractor)
        }
    }

    func testRejectsFreeTextQuestion() {
        let question = makeQuestion(
            questionType: .behavioral,
            responseType: .freeText
        )

        XCTAssertThrowsError(try builder.buildOptions(for: question)) { error in
            XCTAssertEqual(error as? QuestionOptionError, .notMultipleChoice)
        }
    }
}

@MainActor
final class SimulationScoringTests: XCTestCase {

    private let scoring = SimulationScoringService()

    func testMultipleChoiceScoringProducesTenOrZero() {
        let question = makeQuestion(category: .swift)

        let correct = scoring.makeQuestionResult(
            for: question,
            selectedAnswer: question.answer
        )
        let incorrect = scoring.makeQuestionResult(
            for: question,
            selectedAnswer: "Outra resposta"
        )

        XCTAssertEqual(correct.score, 10)
        XCTAssertTrue(correct.isCorrect)
        XCTAssertEqual(incorrect.score, 0)
        XCTAssertFalse(incorrect.isCorrect)
    }

    func testResultCalculatesPercentageAndCategoryPerformance() {
        let swiftQuestion = makeQuestion(id: "swift", category: .swift)
        let uiQuestion = makeQuestion(id: "ui", category: .swiftUI)
        let simulation = Simulation(questions: [swiftQuestion, uiQuestion])
        let results = [
            scoring.makeQuestionResult(for: swiftQuestion, selectedAnswer: swiftQuestion.answer),
            scoring.makeQuestionResult(for: uiQuestion, selectedAnswer: "Resposta errada")
        ]

        let result = scoring.makeResult(for: simulation, questionResults: results)

        XCTAssertEqual(result.correctAnswers, 1)
        XCTAssertEqual(result.percentage, 50)
        XCTAssertEqual(result.categoryPerformance.count, 2)
        XCTAssertEqual(result.questionsToReview.map(\.questionID), ["ui"])
    }

    func testFreeTextScoreIsClampedAndReviewUsesSevenAsThreshold() {
        let question = makeQuestion()

        let result = scoring.makeQuestionResult(
            for: question,
            score: 14,
            isCorrect: true
        )

        XCTAssertEqual(result.score, 10)
        XCTAssertFalse(result.needsReview)
    }
}

@MainActor
final class OfflineAIServiceTests: XCTestCase {

    func testEvaluatesAnAnswerUsingTheQuestionCriteria() async throws {
        let question = makeQuestion(
            questionType: .codeAnalysis,
            responseType: .freeText
        ).with(
            answer: "Isolar o estado com actor",
            evaluationCriteria: [
                "Identifica a corrida de dados",
                "Propõe actor para proteger o estado"
            ]
        )

        let evaluation = try await OfflineAIService().evaluate(
            answer: "Existe uma corrida de dados; eu usaria actor para proteger o estado.",
            for: question
        )

        XCTAssertEqual(evaluation.score, 10)
        XCTAssertEqual(evaluation.classification, .correct)
        XCTAssertFalse(evaluation.strengths.isEmpty)
        XCTAssertTrue(evaluation.missingPoints.isEmpty)
    }

    func testEmptyAnswerIsIncorrect() async throws {
        let question = makeQuestion(
            questionType: .behavioral,
            responseType: .freeText
        ).with(
            evaluationCriteria: ["Explica o contexto"]
        )

        let evaluation = try await OfflineAIService().evaluate(
            answer: "   ",
            for: question
        )

        XCTAssertEqual(evaluation.score, 0)
        XCTAssertEqual(evaluation.classification, .incorrect)
    }
}

private func makeQuestion(
    id: String = "1",
    title: String = "Pergunta de teste",
    answer: String = "Resposta de teste",
    category: DevPrep.Category = .swift,
    difficulty: Difficulty = .mid,
    questionType: QuestionType = .conceptual,
    responseType: ResponseType? = .multipleChoice,
    distractors: [String]? = nil
) -> Question {
    Question(
        id: id,
        title: title,
        answer: answer,
        category: category,
        difficulty: difficulty,
        questionType: questionType,
        responseType: responseType,
        distractors: distractors
    )
}

private extension Question {

    func with(
        answer: String? = nil,
        evaluationCriteria: [String]? = nil
    ) -> Question {
        Question(
            id: id,
            title: title,
            answer: answer ?? self.answer,
            example: example,
            category: category,
            difficulty: difficulty,
            tags: tags,
            questionType: questionType,
            responseType: responseType,
            codeExample: codeExample,
            distractors: distractors,
            evaluationCriteria: evaluationCriteria ?? self.evaluationCriteria,
            followUpQuestions: followUpQuestions
        )
    }
}
