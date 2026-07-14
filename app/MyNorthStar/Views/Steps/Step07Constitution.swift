import SwiftUI

/// Step 7 — Personal Constitution: purpose, principles, and guidelines,
/// seeded from everything upstream and edited until it sounds like the user.
struct ConstitutionStepView: View {
    @Bindable var project: Project
    let goTo: (Step) -> Void
    let onStartOver: () -> Void

    @State private var exportingConstitution = false

    var body: some View {
        StepContainer(step: .constitution) {
            VStack(alignment: .center, spacing: 8) {
                Text("📜")
                    .font(.largeTitle)
                Text("Your Personal Constitution")
                    .font(.title2.bold())
                Text("A personal constitution gives your values a governing form — the same way a national constitution gives a country's values a legal form. It is not a wish list. It is a set of rules you have chosen to live by, drawn from what you actually know about yourself.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            Text("The outline below has been drafted from your values, your alignment map, and your Step 6 reflections. It is a starting point — edit every field until it sounds like you, not like a template. When it does, it will be worth keeping.")
                .font(.callout)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

            lifePurposeSection
            principlesSection
            guidelinesSection
            passagesSection

            HStack {
                Button("← Back to Reflection") { goTo(.reflect) }
                    .buttonStyle(.bordered)
                Button("Download My Constitution") { exportingConstitution = true }
                    .buttonStyle(.borderedProminent)
                Button("Start Over", role: .destructive, action: onStartOver)
                    .buttonStyle(.bordered)
            }

            DataNote("Your constitution is built and stored on your device only. Nothing is transmitted.")
        }
        .fileExporter(
            isPresented: $exportingConstitution,
            document: TextExportDocument(text: project.constitutionText),
            contentType: .plainText,
            defaultFilename: "my-personal-constitution"
        ) { _ in }
    }

    private var lifePurposeSection: some View {
        ConstitutionSection(
            icon: "🌟",
            title: "Life Purpose",
            subtitle: "A single statement of why you exist"
        ) {
            Text("My Purpose Statement")
                .font(.subheadline.weight(.semibold))
            BorderedTextEditor(
                text: Binding(
                    get: { project.effectiveLifePurpose },
                    set: {
                        project.lifePurposeEdit = $0
                        project.touch()
                    }
                ),
                placeholder: "I live to…",
                minHeight: 110
            )
            Text("This should complete the sentence \"I live to…\" in a way that is specific enough to be a real filter for decisions, and broad enough to apply across all areas of your life. Edit the draft above until it sounds like you.")
                .font(.caption)
                .foregroundStyle(.secondary)
            AskClaudeButton(
                title: "Refine my purpose statement",
                acceptLabel: "Use as Purpose Statement",
                promptBuilder: {
                    """
                    MY DRAFT PURPOSE STATEMENT:
                    \(project.effectiveLifePurpose)

                    \(PromptContext.topTen(project))

                    \(PromptContext.answers(project))

                    Refine my draft into a single sentence beginning "I live to…" — \
                    specific enough to be a real filter for decisions, broad enough to \
                    apply across all areas of my life, and in my own plain voice. Reply \
                    with the sentence only.
                    """
                },
                onAccept: { response in
                    let sentence = response.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !sentence.isEmpty else { return }
                    project.lifePurposeEdit = sentence
                    project.touch()
                }
            )
        }
    }

    private var principlesSection: some View {
        ConstitutionSection(
            icon: "⚖️",
            title: "Core Principles",
            subtitle: "Rules that are non-negotiable for your life"
        ) {
            Text("These are the standing rules from which you do not negotiate — not aspirations, but commitments. Each one should be specific enough that you would know immediately if you had violated it.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(0..<5, id: \.self) { index in
                NumberedEditor(
                    number: index + 1,
                    text: Binding(
                        get: { project.effectivePrinciples[index] },
                        set: { project.setPrinciple($0, at: index) }
                    ),
                    placeholder: "I will always… / I will never… / I commit to…"
                )
            }
        }
    }

    /// Shown only once the user has bookmarked at least one Step 6 passage.
    @ViewBuilder
    private var passagesSection: some View {
        if !project.savedPassages.isEmpty {
            ConstitutionSection(
                icon: "📖",
                title: "Passages That Spoke to Me",
                subtitle: "Saved from your reflection"
            ) {
                ForEach(Array(project.savedPassages.enumerated()), id: \.offset) { _, passage in
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor.opacity(0.5))
                            .frame(width: 3)
                        Text(passage)
                            .font(.callout.leading(.loose))
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var guidelinesSection: some View {
        ConstitutionSection(
            icon: "📋",
            title: "Daily Guidelines",
            subtitle: "Actionable rules that govern how you show up"
        ) {
            Text("These are the practical behavioural rules that follow from your principles — specific enough to be actionable on any given day. Examples: \"I will not seek revenge.\" \"I will read before I react.\" \"I will say no to commitments that contradict my top values.\"")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(0..<5, id: \.self) { index in
                NumberedEditor(
                    number: index + 1,
                    text: Binding(
                        get: { project.effectiveGuidelines[index] },
                        set: { project.setGuideline($0, at: index) }
                    ),
                    placeholder: "I will… / I will not…"
                )
            }
        }
    }
}

private struct ConstitutionSection<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(icon)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct NumberedEditor: View {
    let number: Int
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.subheadline.bold())
                .frame(width: 26, height: 26)
                .background(Color.accentColor.opacity(0.18), in: Circle())
                .foregroundStyle(Color.accentColor)
            BorderedTextEditor(text: $text, placeholder: placeholder, minHeight: 56)
        }
    }
}
