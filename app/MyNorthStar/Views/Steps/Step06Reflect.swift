import SwiftUI

/// Step 6 — Corpus-informed reflection: matched passages plus personalised prompts.
struct ReflectStepView: View {
    @Bindable var project: Project
    let goTo: (Step) -> Void
    let onStartOver: () -> Void

    @State private var exportingReport = false

    var body: some View {
        StepContainer(step: .reflect) {
            VStack(alignment: .center, spacing: 8) {
                Text("📓")
                    .font(.largeTitle)
                Text("Your Reflection")
                    .font(.title2.bold())
                Text("Below you'll find passages selected from the Pathfinder corpus — matched to what your answers reveal about how you think, decide, and get stuck. Read slowly. One that lands is worth more than ten you skim.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            insights

            passages

            promptsList

            HStack {
                Button("← Back to Grid") { goTo(.alignment) }
                    .buttonStyle(.bordered)
                Button("Build My Constitution →") { goTo(.constitution) }
                    .buttonStyle(.borderedProminent)
                Button("Download Report") { exportingReport = true }
                    .buttonStyle(.bordered)
                Button("Start Over", role: .destructive, action: onStartOver)
                    .buttonStyle(.bordered)
            }

            DataNote("All data remains on your device. Nothing is sent anywhere.")
        }
        .fileExporter(
            isPresented: $exportingReport,
            document: TextExportDocument(text: project.reportText),
            contentType: .plainText,
            defaultFilename: "mynorthstar-report"
        ) { _ in }
    }

    @ViewBuilder
    private var insights: some View {
        if let insights = project.alignmentInsights {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Alignment at a Glance")
                    .font(.headline)
                InsightRow(icon: "📊", text: "Your values are active across **\(insights.alignPercent)%** of possible life-area intersections (\(insights.totalChecked) of \(insights.maxPossible)).")
                InsightRow(icon: insights.richest.icon, text: "**\(insights.richest.label)** is your most value-rich area — \(insights.richestCount) of your \(project.top10.count) core values show up there.")
                InsightRow(icon: insights.thinnest.icon, text: "**\(insights.thinnest.label)** has the fewest values present — only \(insights.thinnestCount). The passages below were chosen partly with this gap in mind.")
                InsightRow(icon: "⭐", text: "**\(insights.broadestValue)** is your most widely expressed value — present in \(insights.broadestCount) life area\(insights.broadestCount == 1 ? "" : "s").")
                if let unlived = insights.unlivedValue {
                    InsightRow(icon: "🔍", text: "**\(unlived)** does not appear in any life area yet — a value held but not yet lived. Several passages below speak directly to this.")
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var passages: some View {
        if let corpus = Corpus.shared {
            let selected = CorpusSelection.selectPassages(from: corpus, for: project)
            VStack(alignment: .leading, spacing: 14) {
                Text("Passages selected for you — matched to your answers and your alignment map")
                    .font(.headline)
                Text("These are drawn from the Pathfinder corpus — six traditions across 2,500 years. They were chosen because your answers suggest your current work involves **\(project.stuckLabel)**. Read the one that resists you most.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                ForEach(selected) { passage in
                    PassageCard(passage: passage, framing: corpus.framing(for: passage.tradition))
                }
            }
        } else {
            WarningBanner(text: "The bundled corpus could not be loaded — reflection passages are unavailable.")
        }
    }

    private var promptsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(project.reflectionPrompts) { prompt in
                PromptCard(project: project, prompt: prompt)
            }
        }
    }
}

private struct InsightRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(icon)
            Text(.init(text))
                .font(.callout)
        }
    }
}

private struct PassageCard: View {
    let passage: Corpus.Passage
    let framing: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let framing {
                Text(framing)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            Text("“\(passage.text)”")
                .font(.body.leading(.loose))
            HStack(alignment: .firstTextBaseline) {
                Text(passage.authorLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                FlowLayout(spacing: 6) {
                    ForEach(passage.themes, id: \.self) { theme in
                        Text(theme)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.quaternary.opacity(0.4), in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: 340, alignment: .trailing)
            }
            if let note = passage.curatorialNote, !note.isEmpty {
                Divider()
                Text(note)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct PromptCard: View {
    @Bindable var project: Project
    let prompt: ReflectionPrompt

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(prompt.index + 1)")
                .font(.headline)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.18), in: Circle())
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 8) {
                Text(prompt.label)
                    .font(.headline)
                Text(prompt.text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                BorderedTextEditor(
                    text: Binding(
                        get: { project.promptResponses[prompt.index] ?? "" },
                        set: {
                            project.promptResponses[prompt.index] = $0
                            project.touch()
                        }
                    ),
                    placeholder: "Write your thoughts here — this stays on your device only…",
                    minHeight: 80
                )
                AskClaudeButton(
                    title: "Help me go deeper",
                    acceptLabel: "Append to My Response",
                    promptBuilder: {
                        """
                        Reflection prompt — \(prompt.label): \(prompt.text)

                        MY RESPONSE SO FAR:
                        \((project.promptResponses[prompt.index] ?? "").isEmpty ? "(nothing yet)" : project.promptResponses[prompt.index]!)

                        \(PromptContext.topTen(project))

                        \(PromptContext.alignmentSummary(project))

                        Help me go deeper on this prompt: ask one probing follow-up \
                        question and offer one alternative angle I have not considered. \
                        Plain text, under 120 words.
                        """
                    },
                    onAccept: { response in
                        var current = project.promptResponses[prompt.index] ?? ""
                        appendAccepted(response, to: &current)
                        project.promptResponses[prompt.index] = current
                        project.touch()
                    }
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
