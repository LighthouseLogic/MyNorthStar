import Foundation

/// The 7 steps of the Know Your Values exercise, in order.
enum Step: Int, CaseIterable, Identifiable, Hashable {
    case selectValues = 1
    case group
    case topTen
    case fiveQuestions
    case alignment
    case reflect
    case constitution

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .selectValues: "Select 25"
        case .group: "Group"
        case .topTen: "Top 10"
        case .fiveQuestions: "5 Questions"
        case .alignment: "Alignment"
        case .reflect: "Reflect"
        case .constitution: "Constitution"
        }
    }

    var subtitle: String {
        switch self {
        case .selectValues: "Select the values that resonate with who you are"
        case .group: "Group values that feel related to each other"
        case .topTen: "Select your 10 most important values"
        case .fiveQuestions: "How you think and decide — there are no right answers"
        case .alignment: "Where do your values show up in your life?"
        case .reflect: "Passages and prompts matched to your answers"
        case .constitution: "Give your values a governing form"
        }
    }

    var systemImage: String {
        switch self {
        case .selectValues: "checklist"
        case .group: "square.grid.3x2"
        case .topTen: "star"
        case .fiveQuestions: "questionmark.circle"
        case .alignment: "tablecells"
        case .reflect: "book"
        case .constitution: "scroll"
        }
    }
}
