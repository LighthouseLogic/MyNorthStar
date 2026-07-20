import SwiftUI
import UniformTypeIdentifiers

/// Step 7 — Personal Constitution: purpose, principles, and guidelines,
/// seeded from everything upstream and edited until it sounds like the user.
struct ConstitutionStepView: View {
    @Bindable var project: Project
    let goTo: (Step) -> Void
    let onStartOver: () -> Void

    @State private var exportingConstitution = false
    @State private var showingExportGuidance = false
    @State private var pendingFileExport = false
    @AppStorage("hasExportedConstitution") private var hasExportedConstitution = false

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
                Button("Export My Constitution") { showingExportGuidance = true }
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
        ) { result in
            if case .success = result { hasExportedConstitution = true }
        }
        .sheet(
            isPresented: $showingExportGuidance,
            onDismiss: {
                // The file dialog can only present after the sheet is fully gone.
                if pendingFileExport {
                    pendingFileExport = false
                    exportingConstitution = true
                }
            }
        ) {
            ExportGuidanceSheet(
                project: project,
                isReturningExporter: hasExportedConstitution,
                onSendComplete: { hasExportedConstitution = true },
                onSaveToFile: {
                    pendingFileExport = true
                    showingExportGuidance = false
                },
                onDone: { showingExportGuidance = false }
            )
        }
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

/// Post-export guidance: what the exported constitution is, with "Send to
/// Myself" as the prominent path, file-to-disk as the secondary one, and an
/// AI-context reformatting export.
private struct ExportGuidanceSheet: View {
    let project: Project
    let isReturningExporter: Bool
    let onSendComplete: () -> Void
    let onSaveToFile: () -> Void
    let onDone: () -> Void

    private enum AIFormatState {
        case idle
        case working
        case ready(AIContextShareItem)
        case failed(String)
    }

    @State private var aiFormatState = AIFormatState.idle

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("📜")
                    .font(.largeTitle)
                Text("Your constitution is ready")
                    .font(.title3.bold())
                Text("It's a simple text file you can open and edit anywhere — Notes, Pages, or any text editor. Send it to yourself so it's easy to find when you want it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ShareLink(
                    item: ConstitutionShareItem(text: project.constitutionText),
                    preview: SharePreview("My Personal Constitution")
                ) {
                    Label("Send to Myself", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .simultaneousGesture(TapGesture().onEnded { onSendComplete() })

                Button(action: onSaveToFile) {
                    Label("Save to a File Instead", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                aiFormatSection

                Button("Done", action: onDone)
                    .buttonStyle(.borderless)

                if isReturningExporter {
                    Text("You can also edit your constitution directly in the app at any time.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(28)
        }
        .frame(maxWidth: 420)
        .presentationDetents([.medium, .large])
    }

    // MARK: Format for AI

    @ViewBuilder
    private var aiFormatSection: some View {
        switch aiFormatState {
        case .idle:
            Button {
                formatForAI()
            } label: {
                Label("Format for AI Use", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            Text(aiFormatCaption)
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        case .working:
            HStack(spacing: 10) {
                ProgressView().controlSize(.small)
                Text("Formatting your constitution…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        case .ready(let item):
            ShareLink(
                item: item,
                preview: SharePreview("My AI Context")
            ) {
                Label("Share AI Context", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            Text("A version of your constitution written to sit at the top of an AI conversation as standing context about you.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        case .failed(let message):
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            Button("Use Standard Format Instead") {
                aiFormatState = .ready(AIContextShareItem(
                    text: templateAIContext,
                    fileName: aiContextFileName
                ))
            }
            .buttonStyle(.bordered)
        }
    }

    /// Transparency caption: says exactly where the formatting will happen
    /// before the user taps.
    private var aiFormatCaption: String {
        switch AIEngine.activeBackend {
        case .cloud(let provider?) where AIEngine.isReady:
            "Rewrites your constitution as context you can paste into AI chats. Tapping sends your constitution text to \(provider.displayName)."
        case .onDevice where AIEngine.isReady:
            "Rewrites your constitution as context you can paste into AI chats. Formatted entirely on this device."
        default:
            "Creates a version of your constitution formatted to paste into AI chats. Formatted on this device — no AI configured."
        }
    }

    private func formatForAI() {
        guard AIEngine.isReady else {
            // No backend available: the handwritten template stands alone.
            aiFormatState = .ready(AIContextShareItem(
                text: templateAIContext,
                fileName: aiContextFileName
            ))
            return
        }
        aiFormatState = .working
        let prompt = aiFormatPrompt
        Task {
            do {
                let text = try await AIEngine.complete(prompt: prompt, maxTokens: 800)
                aiFormatState = .ready(AIContextShareItem(
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                    fileName: aiContextFileName
                ))
            } catch {
                aiFormatState = .failed(error.localizedDescription)
            }
        }
    }

    /// Tightly scoped: reformat only, no reinterpretation, fixed structure.
    private var aiFormatPrompt: String {
        """
        Reformat my personal constitution below into a compact context block \
        I can paste at the top of conversations with an AI assistant.

        Requirements:
        - Preserve my purpose, principles, and guidelines faithfully. Do not \
        add, drop, soften, or reinterpret any of them.
        - Write in my first-person voice, as natural standing context about \
        who I am and how I want to be worked with — not as instructions to \
        perform a task.
        - Plain text only: no markdown headers, no code fences.
        - Use exactly this structure: one opening line saying what this block \
        is; "My north star:" followed by my purpose; "Core values:" as short \
        numbered lines; "How I work:" as short numbered lines; one closing \
        line asking the assistant to keep its suggestions consistent with \
        these values and to flag conflicts.
        - Keep the whole block under 250 words. Reply with the context block \
        only.

        MY PERSONAL CONSTITUTION:
        \(project.constitutionText)
        """
    }

    /// No-AI fallback — must stand alone as a well-formed context block.
    private var templateAIContext: String {
        let purpose = project.effectiveLifePurpose.trimmingCharacters(in: .whitespacesAndNewlines)
        let principles = project.effectivePrinciples
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let guidelines = project.effectiveGuidelines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var blocks: [String] = []
        blocks.append("""
        About me — standing context for our conversations. This comes from my \
        personal constitution, a set of values and rules I wrote for myself. \
        Treat it as background about who I am and how I want to be worked \
        with, not as a task to perform.
        """)
        if !purpose.isEmpty {
            blocks.append("My north star:\n\(purpose)")
        }
        if !principles.isEmpty {
            let lines = principles.enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            blocks.append("Core values:\n\(lines)")
        }
        if !guidelines.isEmpty {
            let lines = guidelines.enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
            blocks.append("How I work:\n\(lines)")
        }
        blocks.append("""
        Please keep your suggestions consistent with these values, and tell \
        me plainly when something I ask for seems to conflict with them.
        """)
        return blocks.joined(separator: "\n\n")
    }

    private var aiContextFileName: String {
        let title = project.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let safe = title
            .components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined(separator: "-")
        return "\(safe.isEmpty ? "MyNorthStar" : safe)_AI_Context.txt"
    }
}

/// Shares the AI-context block as a named text file, plain text fallback.
private struct AIContextShareItem: Transferable {
    let text: String
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { item in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(item.fileName)
            try Data(item.text.utf8).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
        ProxyRepresentation(exporting: \.text)
    }
}

/// Shares the constitution as a text file, with plain text as the fallback.
private struct ConstitutionShareItem: Transferable {
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { Data($0.text.utf8) }
            .suggestedFileName("my-personal-constitution.txt")
        ProxyRepresentation(exporting: \.text)
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
