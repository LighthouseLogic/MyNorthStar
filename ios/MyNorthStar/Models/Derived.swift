import Foundation

// MARK: - Step 4: the five psychometric questions (verbatim from the reference)

struct PsychQuestion: Identifiable {
    let number: Int
    let text: String
    let targets: String
    let options: [(letter: String, text: String)]
    var id: Int { number }

    static let all: [PsychQuestion] = [
        PsychQuestion(
            number: 1,
            text: "When you face a hard decision, what do you most often regret?",
            targets: "Decision style · Risk tolerance · System 1 vs System 2",
            options: [
                ("a", "Acting too quickly without enough information"),
                ("b", "Waiting too long and missing the moment"),
                ("c", "Choosing what others expected instead of what I wanted"),
                ("d", "Not trusting my gut when it was right"),
            ]
        ),
        PsychQuestion(
            number: 2,
            text: "Which of these feels most true about change in your life?",
            targets: "Agency orientation · Courage · Resilience",
            options: [
                ("a", "I drive it — I initiate change deliberately"),
                ("b", "I adapt to it — I respond well when it comes"),
                ("c", "I endure it — change is hard but I get through it"),
                ("d", "I resist it — I prefer stability and proven paths"),
            ]
        ),
        PsychQuestion(
            number: 3,
            text: "When your values conflict with what's practical, you typically:",
            targets: "Values–action alignment · Stoic tension · Alignment category",
            options: [
                ("a", "Prioritize your values, even at real cost"),
                ("b", "Find a compromise that honors both partially"),
                ("c", "Do what's practical, but feel the tension"),
                ("d", "Avoid the situation until forced to choose"),
            ]
        ),
        PsychQuestion(
            number: 4,
            text: "What does \"a good life\" mean to you most fundamentally?",
            targets: "Purpose orientation · Tradition weighting · Content selection",
            options: [
                ("a", "Living according to clear personal principles"),
                ("b", "Making a meaningful contribution to others"),
                ("c", "Experiencing depth — beauty, love, growth"),
                ("d", "Building something that lasts beyond me"),
            ]
        ),
        PsychQuestion(
            number: 5,
            text: "When you're stuck, what's usually the real obstacle?",
            targets: "Action category · Self-knowledge · Intervention point",
            options: [
                ("a", "I don't know what I want"),
                ("b", "I know what I want but fear the cost"),
                ("c", "I know what to do but can't make myself start"),
                ("d", "I start but can't sustain the effort"),
            ]
        ),
    ]
}

// MARK: - Step 6: alignment insights

struct AlignmentInsights {
    let alignPercent: Int
    let totalChecked: Int
    let maxPossible: Int
    let richest: LifeArea
    let richestCount: Int
    let thinnest: LifeArea
    let thinnestCount: Int
    let broadestValue: String
    let broadestCount: Int
    let unlivedValue: String?   // a top-10 value present in no life area
}

extension Project {
    var alignmentInsights: AlignmentInsights? {
        guard !top10.isEmpty else { return nil }

        let areaCounts = LifeArea.all
            .map { (area: $0, count: valueCount(inArea: $0.index)) }
            .sorted { $0.count > $1.count }
        let valueCounts = top10
            .map { (name: $0, count: areaCount(for: $0)) }
            .sorted { $0.count > $1.count }

        guard let richest = areaCounts.first, let thinnest = areaCounts.last,
              let broadest = valueCounts.first, let narrowest = valueCounts.last
        else { return nil }

        let totalChecked = top10.reduce(0) { $0 + areaCount(for: $1) }
        let maxPossible = top10.count * LifeArea.all.count

        return AlignmentInsights(
            alignPercent: maxPossible > 0 ? Int((Double(totalChecked) / Double(maxPossible) * 100).rounded()) : 0,
            totalChecked: totalChecked,
            maxPossible: maxPossible,
            richest: richest.area,
            richestCount: richest.count,
            thinnest: thinnest.area,
            thinnestCount: thinnest.count,
            broadestValue: broadest.name,
            broadestCount: broadest.count,
            unlivedValue: narrowest.count == 0 ? narrowest.name : nil
        )
    }

    /// Q5 answer → how the Step 6 intro names the user's obstacle.
    var stuckLabel: String {
        switch psychAnswers[5] {
        case "a": "clarity about what you want"
        case "b": "the courage to pay the cost"
        case "c": "the threshold of beginning"
        case "d": "sustaining what you have started"
        default: "your specific obstacle"
        }
    }
}

// MARK: - Step 6: personalised reflection prompts (ported 1:1)

struct ReflectionPrompt: Identifiable {
    let index: Int
    let label: String
    let text: String
    var id: Int { index }
}

extension Project {
    var reflectionPrompts: [ReflectionPrompt] {
        var prompts: [(label: String, text: String)] = []

        prompts.append((
            "Abundance",
            "Which life areas have the most of your values present? What does this tell you about where you are currently most alive?"
        ))
        prompts.append((
            "The Gap",
            "Which life areas have the fewest — or none — of your values present? Is this by choice, by circumstance, or by neglect?"
        ))

        let stuckPrompts: [String: (String, String)] = [
            "a": ("What Do I Actually Want?", "Your answer suggests the real obstacle is clarity about desire, not capacity. Write down three things you want — not should want, not what others want for you. Then write the question: which of these is the one I keep circling back to when I'm alone?"),
            "b": ("The Price", "You know what you want but fear the cost. Name the cost precisely — not in vague terms, but in specific, concrete things you would lose or risk. Then ask: is this cost actually as large as it feels? What would I tell a friend who was weighing the same cost?"),
            "c": ("The Threshold", "The obstacle is beginning, not knowing or fearing. Write down the smallest possible version of the thing you cannot make yourself start. So small it would be embarrassing not to do it. Then: what has kept even that from happening?"),
            "d": ("The Sustaining Conditions", "You start but cannot sustain. What conditions were present the last time you sustained something for longer than expected? What conditions were absent the last time you stopped? The pattern in those two lists is your answer."),
        ]
        if let q5 = psychAnswers[5], let stuck = stuckPrompts[q5] {
            prompts.append(stuck)
        }

        switch psychAnswers[3] {
        case "c", "d":
            prompts.append((
                "The Compromise You Keep Making",
                "Your answer to the values-versus-practical question suggests a recurring compromise. Name one decision you made recently where you chose what was practical over what you actually valued. What did that cost you — not materially, but in how you felt about yourself afterward?"
            ))
        case "a":
            prompts.append((
                "What Loyalty Has Cost You",
                "You tend to prioritize your values even at real cost. Name a time when this was the right call. Now name a time when the cost was higher than you realized, and whether you would make the same choice again."
            ))
        default:
            prompts.append((
                "The Orphaned Value",
                "Are there any values that appear in only one area of your life — or none at all? What would it mean to bring that value into one more area, starting this week?"
            ))
        }

        prompts.append((
            "One Small Step",
            "If you could bring one more of your core values into one more area of your life — starting this week — what would that look like as a specific, datable action? Not a resolution. A thing you will do, on a day, at a time."
        ))
        prompts.append((
            "The Bigger Picture",
            "When you look at this map as a whole — your values, where they show up, where they don't, and what your five answers revealed — what does it tell you about the chapter of life you are currently in? What would the next chapter require?"
        ))

        return prompts.enumerated().map {
            ReflectionPrompt(index: $0.offset, label: $0.element.label, text: $0.element.text)
        }
    }
}

// MARK: - Step 7: constitution seeds and effective (seed-or-edited) content

struct ConstitutionSeeds {
    let lifePurpose: String
    let principles: [String]   // always 5 slots
    let guidelines: [String]   // always 5 slots
}

extension Project {
    var constitutionSeeds: ConstitutionSeeds {
        let q4Orientations: [String: String] = [
            "a": "living by clear personal principles",
            "b": "making a meaningful contribution to others",
            "c": "experiencing depth — beauty, love, and growth",
            "d": "building something that lasts beyond me",
        ]
        let orientation = psychAnswers[4].flatMap { q4Orientations[$0] } ?? "a life of integrity"

        let richestArea = LifeArea.all
            .max { valueCount(inArea: $0.index) < valueCount(inArea: $1.index) }
            .map { $0.label.lowercased() } ?? "my relationships"

        let purpose: String = top10.count >= 2
            ? "I live to pursue \(orientation), expressed most fully through \(top10[0].lowercased()) and \(top10[1].lowercased()), above all in \(richestArea)."
            : "I live to pursue \(orientation)."

        var principles = top10.prefix(5).map {
            "I will honour \($0.lowercased()) in every significant decision I make."
        }
        while principles.count < 5 { principles.append("") }

        let q3Guidelines: [String: String] = [
            "a": "I will not compromise what I believe to avoid short-term discomfort.",
            "b": "When my values and practical needs conflict, I will name the tension explicitly before choosing.",
            "c": "I will not pretend the tension does not exist. I will act, and I will account for the cost.",
            "d": "I will not avoid hard choices by waiting for circumstances to change on their own.",
        ]
        let q5Guidelines: [String: String] = [
            "a": "Before acting, I will write down what I actually want — not what I think I should want.",
            "b": "I will name the cost of what I want before deciding it is too high.",
            "c": "I will begin with the smallest version of the thing rather than waiting for the right conditions.",
            "d": "I will identify the conditions that support my follow-through and protect them.",
        ]
        let q1Guidelines: [String: String] = [
            "a": "I will pause before acting on strong feeling.",
            "b": "I will act before the moment has fully resolved into certainty.",
            "c": "I will not let others' expectations be the default answer to my own questions.",
            "d": "I will trust my own judgment once I have honestly examined it.",
        ]

        var guidelines: [String] = []
        if let g = psychAnswers[3].flatMap({ q3Guidelines[$0] }) { guidelines.append(g) }
        if let g = psychAnswers[5].flatMap({ q5Guidelines[$0] }) { guidelines.append(g) }
        if let g = psychAnswers[1].flatMap({ q1Guidelines[$0] }) { guidelines.append(g) }

        // A blank slot invites translating their own written reflection into a rule.
        let hasWrittenReflection = promptResponses.values.contains {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).count > 20
        }
        if hasWrittenReflection { guidelines.append("") }
        while guidelines.count < 5 { guidelines.append("") }

        return ConstitutionSeeds(
            lifePurpose: purpose,
            principles: Array(principles.prefix(5)),
            guidelines: Array(guidelines.prefix(5))
        )
    }

    /// What Step 7 displays: the user's edit if one exists, otherwise the seed.
    var effectiveLifePurpose: String { lifePurposeEdit ?? constitutionSeeds.lifePurpose }
    var effectivePrinciples: [String] { padded(principlesEdit) ?? constitutionSeeds.principles }
    var effectiveGuidelines: [String] { padded(guidelinesEdit) ?? constitutionSeeds.guidelines }

    private func padded(_ items: [String]?) -> [String]? {
        guard var items else { return nil }
        while items.count < 5 { items.append("") }
        return Array(items.prefix(5))
    }

    func setPrinciple(_ text: String, at index: Int) {
        var items = effectivePrinciples
        guard items.indices.contains(index) else { return }
        items[index] = text
        principlesEdit = items
        touch()
    }

    func setGuideline(_ text: String, at index: Int) {
        var items = effectiveGuidelines
        guard items.indices.contains(index) else { return }
        items[index] = text
        guidelinesEdit = items
        touch()
    }
}

// MARK: - Exports (ported from the reference download formats)

extension Project {
    /// The full report ("Download Report", Step 6).
    var reportText: String {
        var text = "LIGHTHOUSE LOGIC — VALUES, ALIGNMENT & REFLECTION REPORT\n"
        text += String(repeating: "=", count: 56) + "\n"
        text += "Generated: " + Date.now.formatted(date: .numeric, time: .omitted) + "\n"
        text += "All data processed locally. Nothing was transmitted.\n\n"

        text += "MY TOP 10 CORE VALUES:\n" + String(repeating: "-", count: 30) + "\n"
        for (index, value) in top10.enumerated() {
            let group = groupName(for: value).map { " [\($0)]" } ?? ""
            text += "\(index + 1). \(value)\(group)\n"
        }

        text += "\nFIVE QUESTIONS — MY ANSWERS:\n" + String(repeating: "-", count: 30) + "\n"
        for question in PsychQuestion.all {
            let answer = psychAnswers[question.number]
            text += "Q\(question.number): \(question.text)\n"
            text += "    → \(answer.map { "\($0.uppercased()) (selected)" } ?? "(unanswered)")\n"
        }

        text += "\nALIGNMENT MAP:\n" + String(repeating: "-", count: 30) + "\n"
        text += (["Value"] + LifeArea.all.map(\.label)).joined(separator: " | ") + "\n"
        for value in top10 {
            let row = [value] + LifeArea.all.map { isAligned(value, area: $0.index) ? "✓" : "·" }
            text += row.joined(separator: " | ") + "\n"
        }

        text += "\nCATEGORY TOTALS:\n"
        for area in LifeArea.all {
            text += "\(area.icon) \(area.label): \(valueCount(inArea: area.index))/\(top10.count) values present\n"
        }

        text += "\nREFLECTION PROMPTS & YOUR RESPONSES:\n" + String(repeating: "-", count: 30) + "\n"
        for prompt in reflectionPrompts {
            text += "\n\(prompt.index + 1). \(prompt.label)\n"
            text += "   \(prompt.text)\n"
            text += "\n   Your response:\n"
            let response = (promptResponses[prompt.index] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if response.isEmpty {
                text += "     (no response entered)\n"
            } else {
                for line in response.split(separator: "\n", omittingEmptySubsequences: false) {
                    text += "     \(line)\n"
                }
            }
            text += "\n"
        }

        text += "\n— Your data was processed locally and never transmitted. —\n"
        return text
    }

    /// The constitution document ("Download My Constitution", Step 7).
    var constitutionText: String {
        let principles = effectivePrinciples.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let guidelines = effectiveGuidelines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let purpose = effectiveLifePurpose.trimmingCharacters(in: .whitespacesAndNewlines)

        var text = "MY PERSONAL CONSTITUTION\n"
        text += String(repeating: "═", count: 50) + "\n"
        text += "Created with MyNorthStar · " + Date.now.formatted(date: .numeric, time: .omitted) + "\n"
        text += "Everything on this page is yours. It was built on your device and never transmitted.\n\n"

        text += "── LIFE PURPOSE ──────────────────────────────────\n\n"
        text += (purpose.isEmpty ? "(not yet written)" : purpose) + "\n\n"

        text += "── CORE PRINCIPLES ───────────────────────────────\n\n"
        if principles.isEmpty {
            text += "(not yet written)\n"
        } else {
            for (index, principle) in principles.enumerated() {
                text += "\(index + 1). \(principle)\n"
            }
        }

        text += "\n── DAILY GUIDELINES ──────────────────────────────\n\n"
        if guidelines.isEmpty {
            text += "(not yet written)\n"
        } else {
            for (index, guideline) in guidelines.enumerated() {
                text += "\(index + 1). \(guideline)\n"
            }
        }

        text += "\n── BUILT FROM ────────────────────────────────────\n\n"
        text += "Core values: " + top10.joined(separator: ", ") + "\n"
        text += "Generated by MyNorthStar · Your data stays yours.\n"
        return text
    }
}
