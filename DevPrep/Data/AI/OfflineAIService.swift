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
        // nil means that the legacy question has no rubric and receives the
        // default criteria. An explicit [] intentionally opts into reference
        // answer matching instead.
        let criteria = question.evaluationCriteria ?? defaultCriteria(for: question)
        let normalizedAnswer = normalize(answer)
        let answerTokens = Set(tokens(from: normalizedAnswer))
        let referenceTokens = Set(tokens(from: normalize(question.answer)))

        let matchedCriteria = criteria.filter { criterion in
            criteriaIsCovered(
                criterion,
                answer: normalizedAnswer,
                referenceAnswer: normalize(question.answer),
                answerTokens: answerTokens,
                referenceTokens: referenceTokens
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
        var normalized = value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        let phraseAliases = [
            "data race": "corrida de dados",
            "race condition": "corrida de dados",
            "thread safe": "seguro concorrente",
            "thread safety": "seguranca concorrencia",
            "retain cycle": "ciclo de retencao",
            "memory leak": "vazamento memoria",
            "copy on write": "copia sob escrita",
            "value type": "tipo valor",
            "reference type": "tipo referencia",
            "dependency injection": "injecao dependencia",
            "low coupling": "baixo acoplamento",
            "high cohesion": "alta coesao",
            "optional binding": "desembrulho opcional",
            "force unwrap": "force unwrap",
            "async await": "async await",
            "diffable data source": "fonte dados diferencial",
            "compositional layout": "layout composicional",
            "hosting controller": "controlador hospedagem"
        ]

        for (alias, canonicalValue) in phraseAliases {
            normalized = normalized.replacingOccurrences(
                of: alias,
                with: canonicalValue
            )
        }

        return normalized
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func tokens(from value: String) -> [String] {
        value
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 }
    }

    func criteriaIsCovered(
        _ criterion: String,
        answer: String,
        referenceAnswer: String,
        answerTokens: Set<String>,
        referenceTokens: Set<String>
    ) -> Bool {
        let criterionGroups = matchedKeywordGroups(in: criterion)
        let answerGroups = matchedKeywordGroups(in: answer)

        if !criterionGroups.isDisjoint(with: answerGroups) {
            return true
        }

        let criterionTokens = Set(tokens(from: normalize(criterion)))
        let meaningfulTokens = criterionTokens.subtracting(commonWords)
        let answerOverlap = meaningfulTokens.intersection(answerTokens).count

        guard !meaningfulTokens.isEmpty else {
            return false
        }

        if answerOverlap > 0 {
            return true
        }

        let referenceGroups = matchedKeywordGroups(in: referenceAnswer)
        let referenceOverlap = meaningfulTokens.intersection(referenceTokens).count
        return (referenceOverlap > 0 || !criterionGroups.isDisjoint(with: referenceGroups)) &&
            !answerTokens.intersection(referenceTokens).isEmpty &&
            answerOverlap >= max(1, min(2, referenceOverlap / 2))
    }

    func matchedKeywordGroups(in value: String) -> Set<String> {
        let valueTokens = Set(tokens(from: normalize(value)))

        return Set(
            technicalKeywordGroups.compactMap { group in
                let normalizedGroup = group.map(normalize)
                guard normalizedGroup.contains(where: { phrase in
                    Set(tokens(from: phrase)).isSubset(of: valueTokens)
                }) else {
                    return nil
                }

                return normalizedGroup[0]
            }
        )
    }

    var technicalKeywordGroups: [[String]] {
        [
            ["corrida de dados", "data race", "race condition"],
            ["actor", "ator", "atores"],
            ["concorrencia", "concurrency", "concurrent"],
            ["async await", "async/await"],
            ["ciclo de retencao", "retain cycle"],
            ["vazamento memoria", "memory leak"],
            ["copia sob escrita", "copy on write"],
            ["tipo valor", "value type"],
            ["tipo referencia", "reference type"],
            ["injecao dependencia", "dependency injection"],
            ["baixo acoplamento", "low coupling"],
            ["alta coesao", "high cohesion"],
            ["desembrulho opcional", "optional binding"],
            ["force unwrap", "desembrulho forcado"],
            ["layout composicional", "compositional layout"],
            ["fonte dados diferencial", "diffable data source"],
            ["controlador hospedagem", "hosting controller"]
        ]
    }

    var commonWords: Set<String> {
        [
            "que", "uma", "um", "para", "com", "sem", "das", "dos",
            "de", "do", "da", "ao", "e", "ou", "como", "sobre",
            "identifica", "explica", "menciona", "propoe", "aborda",
            "relaciona", "considera", "demonstra", "inclui", "cita"
        ]
    }
}
