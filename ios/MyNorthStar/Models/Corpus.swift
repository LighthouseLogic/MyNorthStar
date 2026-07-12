import Foundation

/// The bundled Pathfinder corpus — 253 passages from six philosophical
/// traditions across 2,500 years — plus the selection algorithm that matches
/// passages to the user's answers and alignment map (Step 6).
struct Corpus: Decodable, Sendable {
    struct Meta: Decodable, Sendable {
        struct Tradition: Decodable, Sendable {
            let register: String?
            let framing: String?
        }
        let description: String?
        let themes: [String]?
        let traditions: [String: Tradition]
    }

    struct Passage: Decodable, Sendable, Identifiable {
        struct Synthesis: Decodable, Sendable {
            let psychometricWeights: [String: Double]

            enum CodingKeys: String, CodingKey {
                case psychometricWeights = "psychometric_weights"
            }
        }

        let id: String
        let tradition: String
        let themes: [String]
        let text: String
        let sourceRef: String?
        let curatorialNote: String?
        let author: String
        let work: String?
        let hubbardPart: String?
        let synthesis: Synthesis

        enum CodingKeys: String, CodingKey {
            case id, tradition, themes, text, author, work, synthesis
            case sourceRef = "source_ref"
            case curatorialNote = "curatorial_note"
            case hubbardPart = "hubbard_part"
        }

        /// Attribution line; Hubbard's anthology parts are credited as editor.
        var authorLine: String {
            let source = sourceRef ?? work ?? ""
            if author == "Elbert Hubbard" && hubbardPart == "B" {
                return "\(author) (ed.) — \(source)"
            }
            return "\(author) — \(source)"
        }
    }

    let meta: Meta
    let passages: [Passage]

    func framing(for tradition: String) -> String? {
        meta.traditions[tradition]?.framing
    }

    /// Loaded once from the bundled corpus.json; nil only if the resource is damaged.
    static let shared: Corpus? = {
        guard let url = Bundle.main.url(forResource: "corpus", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Corpus.self, from: data)
    }()
}

// MARK: - Selection algorithm (ported 1:1 from the reference implementation)

enum CorpusSelection {
    /// Q4 answer → which traditions get a scoring bonus.
    static let q4TraditionBonus: [String: [String]] = [
        "a": ["Stoic", "Enlightenment"],
        "b": ["American Pragmatist", "Buddhist"],
        "c": ["Transcendentalist"],
        "d": ["Stoic"],
    ]

    /// Life-area index → corpus themes that address a thin area.
    static let areaThemeMap: [Int: [String]] = [
        0: ["Action — Beginning", "Purpose"],       // Work
        1: ["Resilience", "Action — Sustaining"],   // Physical Health
        2: ["Decision-Making", "Values Clarity"],   // Finances
        3: ["Letting Go", "Purpose"],               // Family/Love
        4: ["Alignment", "Values Clarity"],         // Friends/Social
        5: ["Purpose", "Courage"],                  // Community
        6: ["Letting Go", "Self-Knowledge"],        // Spiritual Practice
    ]

    /// Themes tied to the user's two thinnest life areas.
    static func gapThemes(for project: Project) -> [String] {
        let counts = LifeArea.all.map { area in
            (index: area.index, count: project.valueCount(inArea: area.index))
        }
        let thinnest = counts
            .sorted { $0.count == $1.count ? $0.index < $1.index : $0.count < $1.count }
            .prefix(2)
        var themes: [String] = []
        for entry in thinnest {
            for theme in areaThemeMap[entry.index] ?? [] where !themes.contains(theme) {
                themes.append(theme)
            }
        }
        return themes
    }

    static func score(
        _ passage: Corpus.Passage,
        answers: [Int: String],
        gapThemes: [String]
    ) -> Double {
        var score = 1.0

        // 1. Psychometric weights from the corpus metadata (keys like "q1_c")
        for (key, multiplier) in passage.synthesis.psychometricWeights {
            let parts = key.split(separator: "_")
            guard parts.count == 2,
                  parts[0].hasPrefix("q"),
                  let question = Int(parts[0].dropFirst()),
                  answers[question] == String(parts[1])
            else { continue }
            score *= multiplier
        }

        // 2. Alignment-gap bonus: themes overlapping the user's thinnest areas
        if !gapThemes.isEmpty, passage.themes.contains(where: gapThemes.contains) {
            score *= 1.4
        }

        // 3. Q4 tradition bonus
        if let q4 = answers[4], (q4TraditionBonus[q4] ?? []).contains(passage.tradition) {
            score *= 1.2
        }

        return score
    }

    /// Greedy selection maximising theme and tradition diversity: up to 6
    /// passages, tradition cap 2 (unless score > 1.6), require a new theme
    /// (unless score > 1.4), minimum 3.
    static func selectPassages(from corpus: Corpus, for project: Project) -> [Corpus.Passage] {
        let answers = project.psychAnswers
        let gaps = gapThemes(for: project)

        struct ScoredPassage {
            let index: Int
            let passage: Corpus.Passage
            let score: Double
        }
        var scored: [ScoredPassage] = []
        for (index, passage) in corpus.passages.enumerated() {
            let value = score(passage, answers: answers, gapThemes: gaps)
            scored.append(ScoredPassage(index: index, passage: passage, score: value))
        }
        scored.sort { $0.score == $1.score ? $0.index < $1.index : $0.score > $1.score }

        var selected: [Corpus.Passage] = []
        var themesUsed = Set<String>()
        var traditionCounts: [String: Int] = [:]

        for entry in scored {
            if selected.count >= 6 { break }

            let traditionCount = traditionCounts[entry.passage.tradition] ?? 0
            if traditionCount >= 2 && entry.score <= 1.6 { continue }

            let newThemes = entry.passage.themes.filter { !themesUsed.contains($0) }
            if newThemes.isEmpty && entry.score <= 1.4 { continue }

            selected.append(entry.passage)
            entry.passage.themes.forEach { themesUsed.insert($0) }
            traditionCounts[entry.passage.tradition] = traditionCount + 1
        }

        if selected.count < 3 {
            for entry in scored {
                if selected.count >= 3 { break }
                if !selected.contains(where: { $0.id == entry.passage.id }) {
                    selected.append(entry.passage)
                }
            }
        }

        return selected
    }
}
