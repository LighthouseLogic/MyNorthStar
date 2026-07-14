import Foundation
import SwiftData

/// A named group of related values (Step 2).
struct ValueGroup: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String = ""
    var values: [String] = []
}

/// One run of the Know Your Values exercise. Mirrors the reference
/// implementation's state object: selected, custom, groups, top10, alignment,
/// psychAnswers, promptResponses, constitution, currentStep.
@Model
final class Project {
    var title: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var currentStep: Int = 1

    /// Step 1 — the (up to 25) values chosen from the catalog plus custom additions.
    var selected: [String] = []
    /// Step 1 — user-added values not in the built-in catalog.
    var custom: [String] = []
    /// Step 2 — named theme groups over the selected values.
    var groups: [ValueGroup] = []
    /// Step 3 — the 10 most important values, in pick order (order = rank).
    var top10: [String] = []
    /// Step 5 — value name → life-area indices where it is active.
    var alignment: [String: [Int]] = [:]
    /// Step 4 — question number (1–5) → answer letter ("a"–"d").
    var psychAnswers: [Int: String] = [:]
    /// Step 6 — prompt index → the user's written response.
    var promptResponses: [Int: String] = [:]

    /// Step 7 — user edits. nil means "not edited yet"; the derived seed shows instead.
    var lifePurposeEdit: String?
    var principlesEdit: [String]?
    var guidelinesEdit: [String]?

    /// Step 6 → Step 7 — passages saved into the constitution's
    /// "Passages That Spoke to Me" section. Each entry is the formatted
    /// block quote (text + attribution line).
    var savedPassages: [String] = []

    init(title: String) {
        self.title = title
    }

    func touch() {
        updatedAt = .now
    }

    /// Clears all exercise data ("Start Over").
    func reset() {
        selected = []
        custom = []
        groups = []
        top10 = []
        alignment = [:]
        psychAnswers = [:]
        promptResponses = [:]
        lifePurposeEdit = nil
        principlesEdit = nil
        guidelinesEdit = nil
        savedPassages = []
        currentStep = 1
        touch()
    }
}

extension Project {
    /// The clipboard/constitution text for a Step 6 passage: excerpt plus attribution.
    static func formattedPassage(text: String, authorLine: String) -> String {
        "“\(text)”\n— \(authorLine)"
    }

    /// Appends a passage to "Passages That Spoke to Me" (created on first use).
    /// Saving the same passage twice is a no-op.
    func savePassage(text: String, authorLine: String) {
        let formatted = Self.formattedPassage(text: text, authorLine: authorLine)
        guard !savedPassages.contains(formatted) else { return }
        savedPassages.append(formatted)
        touch()
    }
}

// MARK: - The built-in catalog and life areas

enum ValuesCatalog {
    static let allValues: [String] = {
        let raw = [
            "Acceptance", "Achievement", "Activism", "Adventure", "Ambition", "Analytical Thinking",
            "Arts & Culture", "Autonomy", "Authority", "Authenticity", "Balance", "Beauty & Aesthetics",
            "Belonging", "Big Picture", "Broad-Mindedness", "Calmness", "Caring", "Certainty", "Challenge",
            "Change", "Charity", "Cheerfulness", "Clarity", "Cleanliness", "Collaboration", "Conformity",
            "Community", "Compassion", "Competence", "Competitiveness", "Connectedness",
            "Contribution & Making a Difference", "Courage", "Creativity", "Cultural Diversity", "Curiosity",
            "Decisiveness", "Determination", "Discipline", "Diversity", "Economic Security", "Effectiveness",
            "Empathy", "Environmentally Conscious", "Equality", "Excellence", "Excitement", "Experimentation",
            "Expertise", "Fame", "Fashion", "Fairness", "Family Wellbeing & Happiness", "Feminism",
            "Financial Security", "Flexibility", "Forgiveness", "Frankness & Being Direct", "Freedom",
            "Free Choice", "Free Time", "Friendship", "Friendliness", "Fun", "Generosity", "Global Mindset",
            "Grounded & Knowing Yourself", "Happiness", "Harmony", "Having a Voice", "Having Dreams",
            "Health", "Helping Others & Society", "Honesty", "Honor", "Humor", "Hope", "Imagination",
            "Independence", "Influence", "Inner Peace", "Innovation", "Inspiring Others", "Integrity",
            "Intellectual Curiosity", "Intelligence", "Intuition", "Kindness", "Knowing Your Values",
            "Knowledge", "Laughter", "Leadership", "Learning", "Leisure", "Living Your Dreams", "Love",
            "Loving Others", "Masculinity", "Meaning & Purpose in Life", "Nature", "National Security",
            "Obedience", "Openness", "Optimism", "Order", "Passion", "Patience", "Patriotism",
            "Peace & Global Peace", "Persistence", "Personal Growth", "Professional Growth", "Play",
            "Pleasure", "Politeness", "Positive Attitude", "Power", "Precision", "Pride", "Professionalism",
            "Quality of Life", "Recognition", "Reflection", "Relational", "Relaxed Attitude", "Reliability",
            "Religion", "Respect", "Result-Orientation", "Risk Taking", "Safety", "Self-Control",
            "Self-Expression", "Self-Fulfillment", "Self-Reliance", "Sensuality", "Sincerity",
            "Social Justice", "Spirituality", "Spontaneity", "Social Responsibility", "Stability", "Status",
            "Standing Up for Yourself", "Style", "Teamwork", "Thoughtfulness", "Tidiness", "Tolerance",
            "Tranquility", "Trust & Trustworthiness", "Wealth", "Winning", "Wisdom", "Wonder and Awe",
        ]
        var seen = Set<String>()
        return raw.filter { seen.insert($0).inserted }.sorted()
    }()

    static let selectionTarget = 25
    static let minimumSelection = 10
    static let topCount = 10
}

/// The seven fixed life areas of the alignment grid (Step 5).
struct LifeArea: Identifiable, Hashable {
    let index: Int
    let label: String
    let icon: String
    var id: Int { index }

    static let all: [LifeArea] = [
        LifeArea(index: 0, label: "Work", icon: "💼"),
        LifeArea(index: 1, label: "Physical Health", icon: "🏃"),
        LifeArea(index: 2, label: "Finances", icon: "💰"),
        LifeArea(index: 3, label: "Family / Love / Intimacy", icon: "❤️"),
        LifeArea(index: 4, label: "Friends / Social", icon: "🤝"),
        LifeArea(index: 5, label: "Community / Volunteering", icon: "🌱"),
        LifeArea(index: 6, label: "Spiritual Practice", icon: "✨"),
    ]
}

// MARK: - Basic derived state (each step reads upstream steps; nothing is duplicated)

extension Project {
    /// Catalog plus this project's custom values — the Step 1 grid contents.
    var allSelectableValues: [String] { ValuesCatalog.allValues + custom }

    var groupedValues: Set<String> {
        Set(groups.flatMap(\.values))
    }

    /// Selected values not yet placed in any group (Step 2 pool).
    var ungroupedValues: [String] {
        let grouped = groupedValues
        return selected.filter { !grouped.contains($0) }
    }

    /// The named group a value belongs to, if any (shown in Step 3).
    func groupName(for value: String) -> String? {
        for group in groups where group.values.contains(value) && !group.name.isEmpty {
            return group.name
        }
        return nil
    }

    func isAligned(_ value: String, area: Int) -> Bool {
        alignment[value]?.contains(area) ?? false
    }

    func toggleAlignment(_ value: String, area: Int) {
        var areas = alignment[value] ?? []
        if let existing = areas.firstIndex(of: area) {
            areas.remove(at: existing)
        } else {
            areas.append(area)
        }
        alignment[value] = areas
        touch()
    }

    /// How many life areas a value is active in.
    func areaCount(for value: String) -> Int {
        alignment[value]?.count ?? 0
    }

    /// How many top-10 values are active in a life area.
    func valueCount(inArea area: Int) -> Int {
        top10.filter { isAligned($0, area: area) }.count
    }

    /// Steps 2/3 need at least 10 selected; Step 6 needs all five answers.
    /// (Step 7 is not gated — its seeds degrade gracefully, as in the reference.)
    func canEnter(_ step: Step) -> Bool {
        switch step {
        case .group, .topTen:
            selected.count >= ValuesCatalog.minimumSelection
        case .reflect:
            psychAnswers.count >= 5
        default:
            true
        }
    }
}
