//
//  OfflineAIService.swift
//  DevPrep
//

import Foundation

struct OfflineAIService: AIService {

    func evaluate(
        answer: String,
        for question: Question
    ) async throws -> AnswerEvaluation {
        let criteria = question.evaluationCriteria ?? defaultCriteria(for: question)
        let normalizedAnswer = normalize(answer)
        let answerTokens = Set(tokens(from: normalizedAnswer))
        let referenceTokens = Set(tokens(from: normalize(question.answer)))

        let matchedCriteria = criteria.filter { criterion in
            let criterionTokens = Set(tokens(from: normalize(criterion)))
            let referenceOverlap = criterionTokens.intersection(referenceTokens).count
            let answerOverlap = criterionTokens.intersection(answerTokens).count

            return answerOverlap > 0 || (
                referenceOverlap > 0 &&
                !answerTokens.intersection(referenceTokens).isEmpty &&
                answerOverlap >= max(1, min(2, referenceOverlap / 2))
            )
        }

        let missingCriteria = criteria.filter { !matchedCriteria.contains($0) }
        let score: Int

        if normalizedAnswer.isEmpty {
            score = 0
        } else if criteria.isEmpty {
            score = answerTokens.intersection(referenceTokens).isEmpty ? 0 : 7
        } else {
            score = Int(
                (Double(matchedCriteria.count) / Double(criteria.count) * 10).rounded()
            )
        }

        let classification: AnswerClassification
        switch score {
        case 8...10:
            classification = .correct
        case 5...7:
            classification = .partiallyCorrect
        default:
            classification = .incorrect
        }

        let strengths = matchedCriteria.map {
            "Você abordou: \($0.lowercased())."
        }
        let missingPoints = missingCriteria.map {
            "Faltou abordar: \($0.lowercased())."
        }

        return AnswerEvaluation(
            score: score,
            classification: classification,
            strengths: strengths,
            missingPoints: missingPoints,
            improvedAnswer: question.answer,
            didacticExplanation: explanation(for: question)
        )
    }

    func answer(
        question: Question,
        userPrompt: String
    ) async throws -> String {
        let prompt = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let answer = question.answer

        if prompt.isEmpty {
            return answer
        }

        return """
        Resposta curta: \(answer)

        Para aprofundar “\(prompt)”: este é um ponto importante em entrevistas porque a resposta deve relacionar o conceito ao contexto do aplicativo. Um bom próximo passo é comparar essa explicação com o exemplo da pergunta e testar o comportamento em um pequeno projeto Swift.
        """
    }

    func summarize(result: SimulationResult) async throws -> String {
        guard result.totalQuestions > 0 else {
            return "O simulado ainda não possui perguntas respondidas."
        }

        if result.percentage >= 80 {
            return "Bom desempenho: você acertou \(result.correctAnswers) de \(result.totalQuestions) perguntas. Revise os itens sinalizados para consolidar os detalhes."
        }

        if result.percentage >= 50 {
            return "Desempenho intermediário: você acertou \(result.correctAnswers) de \(result.totalQuestions) perguntas. Reforce as categorias com menor percentual e tente o simulado novamente."
        }

        return "Este resultado mostra oportunidades de revisão: você acertou \(result.correctAnswers) de \(result.totalQuestions) perguntas. Estude as explicações e refaça as perguntas sinalizadas."
    }
}

private extension OfflineAIService {

    func defaultCriteria(for question: Question) -> [String] {
        [
            "Explica o conceito principal da pergunta",
            "Relaciona a resposta ao contexto de desenvolvimento iOS"
        ]
    }

    func explanation(for question: Question) -> String {
        switch question.questionType {
        case .codeAnalysis, .bugFix:
            return "Em perguntas de código, procure explicar o comportamento observado, a causa raiz e por que a correção evita o problema."
        case .architectureDecision:
            return "Em decisões de arquitetura, conecte a escolha aos requisitos, às restrições do produto e aos trade-offs de manutenção e testes."
        case .behavioral:
            return "Em perguntas comportamentais, organize a resposta em contexto, ação e resultado, incluindo o que você aprendeu."
        default:
            return "Uma resposta forte combina o conceito, o motivo da escolha e um exemplo concreto de uso no desenvolvimento iOS."
        }
    }

    func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    func tokens(from value: String) -> [String] {
        value
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 }
    }
}
