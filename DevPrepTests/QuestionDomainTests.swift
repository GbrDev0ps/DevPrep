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

    func testFreeTextScoreOfSevenCountsAsCorrect() {
        let question = makeQuestion()

        let result = scoring.makeQuestionResult(
            for: question,
            score: 7
        )

        XCTAssertTrue(result.isCorrect)
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

    func testRecognizesTechnicalParaphrasesAcrossLanguages() async throws {
        let question = makeQuestion(
            questionType: .codeAnalysis,
            responseType: .freeText
        ).with(
            answer: "Isolar o estado mutável usando um actor.",
            evaluationCriteria: ["Identifica a corrida de dados"]
        )

        let evaluation = try await OfflineAIService().evaluate(
            answer: "There is a data race between concurrent writes.",
            for: question
        )

        XCTAssertEqual(evaluation.score, 10)
        XCTAssertEqual(evaluation.classification, .correct)
    }

    func testExplicitlyEmptyCriteriaUsesReferenceAnswerFallback() async throws {
        let question = makeQuestion(
            questionType: .openEnded,
            responseType: .freeText
        ).with(
            answer: "Explica o gerenciamento automático de memória.",
            evaluationCriteria: []
        )

        let evaluation = try await OfflineAIService().evaluate(
            answer: "O sistema faz gerenciamento automático de memória.",
            for: question
        )

        XCTAssertEqual(evaluation.score, 7)
        XCTAssertEqual(evaluation.classification, .partiallyCorrect)
    }
}

@MainActor
final class SimulationHistoryStoreTests: XCTestCase {

    func testSavesAndReloadsResultsUsingAnIsolatedDefaultsSuite() {
        let suiteName = makeSuiteName()
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create isolated UserDefaults suite")
            return
        }
        let result = makeSimulationResult()
        var store = SimulationHistoryStore(userDefaults: defaults)
        store.save(result)

        let reloadedStore = SimulationHistoryStore(userDefaults: defaults)

        XCTAssertEqual(reloadedStore.results, [result])
    }

    func testKeepsNewestResultsFirstAndCapsHistoryAtTwentyItems() {
        let suiteName = makeSuiteName()
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create isolated UserDefaults suite")
            return
        }
        var store = SimulationHistoryStore(userDefaults: defaults)
        let results = (0..<25).map { index in
            makeSimulationResult(
                completedAt: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        for result in results {
            store.save(result)
        }

        XCTAssertEqual(store.results.count, 20)
        XCTAssertEqual(store.results.first?.completedAt, results.last?.completedAt)
        XCTAssertEqual(store.results.last?.completedAt, results[5].completedAt)
    }

    func testCorruptStoredDataStartsWithEmptyHistory() {
        let suiteName = makeSuiteName()
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create isolated UserDefaults suite")
            return
        }
        defaults.set(Data("not-json".utf8), forKey: "simulationHistory")

        XCTAssertTrue(SimulationHistoryStore(userDefaults: defaults).results.isEmpty)
    }
}

@MainActor
final class SimulationViewModelTests: XCTestCase {

    func testEvaluationFailureCanBeRetriedAndThenSubmitted() async {
        let aiService = RetryingAIService()
        let viewModel = SimulationViewModel(
            repository: StubQuestionRepository(questions: makeFreeTextQuestions()),
            aiService: aiService,
            historyStore: isolatedHistoryStore()
        )

        await viewModel.start()
        viewModel.updateFreeTextAnswer("Minha resposta")

        await viewModel.submitFreeTextAnswer()
        XCTAssertFalse(viewModel.isAnswerSubmitted)
        XCTAssertNotNil(viewModel.evaluationError)

        await viewModel.submitFreeTextAnswer()
        XCTAssertTrue(viewModel.isAnswerSubmitted)
        XCTAssertNil(viewModel.evaluationError)
        XCTAssertEqual(viewModel.answerEvaluation?.score, 8)
        XCTAssertEqual(aiService.evaluateCallCount, 2)
    }

    func testCancellationDoesNotBecomeAnEvaluationError() async {
        let viewModel = SimulationViewModel(
            repository: StubQuestionRepository(questions: makeFreeTextQuestions()),
            aiService: CancellationAIService(),
            historyStore: isolatedHistoryStore()
        )

        await viewModel.start()
        viewModel.updateFreeTextAnswer("Minha resposta")

        await viewModel.submitFreeTextAnswer()

        XCTAssertFalse(viewModel.isAnswerSubmitted)
        XCTAssertNil(viewModel.evaluationError)
        XCTAssertFalse(viewModel.isEvaluatingAnswer)
    }

    func testCanSkipAfterEvaluationFailure() async {
        let viewModel = SimulationViewModel(
            repository: StubQuestionRepository(questions: makeFreeTextQuestions()),
            aiService: FailingAIService(),
            historyStore: isolatedHistoryStore()
        )

        await viewModel.start()
        viewModel.updateFreeTextAnswer("Minha resposta")
        await viewModel.submitFreeTextAnswer()

        viewModel.skipCurrentQuestion()

        XCTAssertTrue(viewModel.isAnswerSubmitted)
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertNil(viewModel.evaluationError)
    }

    func testFinishingFreeTextSimulationSavesResultToHistory() async {
        let suiteName = "SimulationViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let historyStore = SimulationHistoryStore(userDefaults: defaults)
        let viewModel = SimulationViewModel(
            repository: StubQuestionRepository(questions: makeFreeTextQuestions()),
            aiService: SuccessfulAIService(),
            historyStore: historyStore
        )

        await viewModel.start()

        for _ in 0..<SimulationViewModel.questionCount {
            viewModel.updateFreeTextAnswer("Resposta com contexto")
            await viewModel.submitFreeTextAnswer()
            XCTAssertTrue(viewModel.isAnswerSubmitted)
            await viewModel.nextQuestion()
        }

        XCTAssertTrue(viewModel.isFinished)
        XCTAssertEqual(viewModel.simulationResult?.totalQuestions, 10)
        XCTAssertEqual(viewModel.simulationResult?.percentage, 100)
        XCTAssertEqual(
            SimulationHistoryStore(userDefaults: defaults).results.count,
            1
        )
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

private func makeFreeTextQuestions(count: Int = 10) -> [Question] {
    (0..<count).map { index in
        Question(
            id: "free-\(index)",
            title: "Pergunta aberta \(index)",
            answer: "Resposta de referência",
            category: .swift,
            difficulty: .mid,
            questionType: .behavioral,
            responseType: .freeText,
            evaluationCriteria: ["Explica o contexto"]
        )
    }
}

private func makeSimulationResult(
    completedAt: Date = Date()
) -> SimulationResult {
    SimulationResult(
        simulationID: UUID(),
        startedAt: completedAt.addingTimeInterval(-60),
        completedAt: completedAt,
        questionResults: [
            SimulationQuestionResult(
                questionID: UUID().uuidString,
                questionTitle: "Pergunta de histórico",
                category: .swift,
                score: 10,
                isCorrect: true
            )
        ]
    )
}

@MainActor
private func isolatedHistoryStore() -> SimulationHistoryStore {
    let defaults = UserDefaults(suiteName: makeSuiteName())!
    return SimulationHistoryStore(userDefaults: defaults)
}

private func makeSuiteName() -> String {
    "br.com.gbrmartins.devprep.tests.\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
}

private final class StubQuestionRepository: QuestionRepository {

    let questions: [Question]

    init(questions: [Question]) {
        self.questions = questions
    }

    func fetchQuestions() async throws -> [Question] {
        questions
    }
}

private class SuccessfulAIService: AIService {

    func evaluate(
        answer: String,
        for question: Question
    ) async throws -> AnswerEvaluation {
        AnswerEvaluation(
            score: 8,
            classification: .correct,
            strengths: ["Incluiu contexto"],
            improvedAnswer: question.answer
        )
    }

    func answer(question: Question, userPrompt: String) async throws -> String {
        "Resposta local"
    }

    func summarize(result: SimulationResult) async throws -> String {
        "Resumo local"
    }
}

private final class FailingAIService: SuccessfulAIService {

    override func evaluate(
        answer: String,
        for question: Question
    ) async throws -> AnswerEvaluation {
        throw AIServiceError.unavailable
    }
}

private final class RetryingAIService: SuccessfulAIService {

    private(set) var evaluateCallCount = 0

    override func evaluate(
        answer: String,
        for question: Question
    ) async throws -> AnswerEvaluation {
        evaluateCallCount += 1
        if evaluateCallCount == 1 {
            throw AIServiceError.unavailable
        }

        return try await super.evaluate(answer: answer, for: question)
    }
}

private final class CancellationAIService: SuccessfulAIService {

    override func evaluate(
        answer: String,
        for question: Question
    ) async throws -> AnswerEvaluation {
        throw CancellationError()
    }
}
