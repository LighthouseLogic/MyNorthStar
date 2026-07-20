import SwiftUI

/// Per-stage "Ask Claude" button. Presents a review sheet: the user sees the
/// exact prompt, explicitly sends it, then edits/accepts the response before
/// anything is written to a field. Never auto-writes.
struct AskClaudeButton: View {
    let title: String
    let acceptLabel: String
    let promptBuilder: () -> String
    let onAccept: (String) -> Void

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label(title, systemImage: "sparkles")
        }
        .buttonStyle(.bordered)
        .tint(.accentColor)
        .sheet(isPresented: $isPresented) {
            AskClaudeSheet(
                title: title,
                acceptLabel: acceptLabel,
                prompt: promptBuilder(),
                onAccept: onAccept
            )
        }
    }
}

private struct AskClaudeSheet: View {
    let title: String
    let acceptLabel: String
    let prompt: String
    let onAccept: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private enum Phase {
        case review
        case loading
        case response
        case failed(String)
    }

    @State private var phase = Phase.review
    @State private var responseText = ""
    @State private var showPrompt = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    if case .response = phase {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(acceptLabel) {
                                onAccept(responseText)
                                dismiss()
                            }
                            .disabled(responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 480)
        #endif
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .review:
            reviewView
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("Asking \(AIEngine.activeBackendLabel)…")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .response:
            responseView
        case .failed(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text(message)
                    .multilineTextAlignment(.center)
                Button("Try Again") { send() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var reviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let readinessMessage = AIEngine.readinessMessage {
                WarningBanner(text: readinessMessage)
            }
            Label(reviewDisclosureText, systemImage: "lock.shield")
                .font(.callout)
                .foregroundStyle(.secondary)
            DisclosureGroup("Review the exact prompt", isExpanded: $showPrompt) {
                ScrollView {
                    Text(prompt)
                        .font(.callout.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 260)
            }
            Spacer()
            Button {
                send()
            } label: {
                Label("Send to \(AIEngine.activeBackendLabel)", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!AIEngine.isReady)
        }
        .padding()
    }

    private var reviewDisclosureText: String {
        switch AIEngine.activeBackend {
        case .onDevice:
            "This request runs entirely on this device using Apple's on-device AFM 3 Core model. Nothing is sent anywhere."
        case .cloud(let provider?):
            "Sending this request will transmit the text below to \(provider.displayName)'s API. Nothing is sent until you tap Send."
        case .cloud(nil):
            "No cloud provider is configured. Add an API key in Settings first."
        }
    }

    private var responseView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Edit the suggestion below, then choose “\(acceptLabel)” to apply it — or Cancel to discard. Nothing is written until you accept.")
                .font(.callout)
                .foregroundStyle(.secondary)
            TextEditor(text: $responseText)
                .font(.body)
                .padding(6)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary))
        }
        .padding()
    }

    private func send() {
        if let readinessMessage = AIEngine.readinessMessage {
            phase = .failed(readinessMessage)
            return
        }
        phase = .loading
        let requestPrompt = prompt
        Task {
            do {
                let text = try await AIEngine.complete(prompt: requestPrompt)
                responseText = text
                phase = .response
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}

/// Shared UserDefaults keys (API keys themselves live in the Keychain only).
/// `useCloudAI` and `claudeModel` keep their pre-multi-provider raw names so
/// existing users' settings carry over.
enum SettingsKeys {
    static let claudeModel = "claudeModel"
    static let openAIModel = "openAIModel"
    static let googleModel = "googleModel"
    static let useCloudAI = "useClaudeBackend"
    static let preferredProvider = "preferredProvider"
}

/// Assembles scoped prompt context from upstream steps.
enum PromptContext {
    static func selectedValues(_ project: Project) -> String {
        var text = "MY SELECTED VALUES (\(project.selected.count) of \(ValuesCatalog.selectionTarget)):\n"
        text += project.selected.isEmpty ? "(none yet)" : project.selected.joined(separator: ", ")
        if !project.custom.isEmpty {
            text += "\nMY CUSTOM ADDITIONS: " + project.custom.joined(separator: ", ")
        }
        return text
    }

    static func groups(_ project: Project) -> String {
        guard !project.groups.isEmpty else { return "MY GROUPS: (none yet)" }
        let lines = project.groups.map { group in
            "• \(group.name.isEmpty ? "(unnamed group)" : group.name): \(group.values.joined(separator: ", "))"
        }
        var text = "MY GROUPS:\n" + lines.joined(separator: "\n")
        let ungrouped = project.ungroupedValues
        if !ungrouped.isEmpty {
            text += "\nUNGROUPED: " + ungrouped.joined(separator: ", ")
        }
        return text
    }

    static func topTen(_ project: Project) -> String {
        guard !project.top10.isEmpty else { return "MY TOP 10: (none chosen yet)" }
        let lines = project.top10.enumerated().map { index, value in
            let group = project.groupName(for: value).map { " [\($0)]" } ?? ""
            return "\(index + 1). \(value)\(group)"
        }
        return "MY TOP 10 CORE VALUES:\n" + lines.joined(separator: "\n")
    }

    static func answers(_ project: Project) -> String {
        let lines = PsychQuestion.all.map { question -> String in
            guard let letter = project.psychAnswers[question.number],
                  let option = question.options.first(where: { $0.letter == letter }) else {
                return "Q\(question.number): \(question.text)\n   → (unanswered)"
            }
            return "Q\(question.number): \(question.text)\n   → \(option.text)"
        }
        return "MY FIVE ANSWERS:\n" + lines.joined(separator: "\n")
    }

    static func alignmentSummary(_ project: Project) -> String {
        guard !project.top10.isEmpty else { return "ALIGNMENT MAP: (top 10 not chosen yet)" }
        var text = "MY ALIGNMENT MAP (value → life areas where it is active):\n"
        for value in project.top10 {
            let areas = LifeArea.all
                .filter { project.isAligned(value, area: $0.index) }
                .map(\.label)
            text += "• \(value): \(areas.isEmpty ? "(no areas)" : areas.joined(separator: ", "))\n"
        }
        for area in LifeArea.all {
            text += "\(area.label): \(project.valueCount(inArea: area.index))/\(project.top10.count) values present\n"
        }
        return text
    }
}

/// Binding variant of `appendAccepted(_:to:)` for fields nested in value types.
func appendAccepted(_ text: String, to binding: Binding<String>) {
    var value = binding.wrappedValue
    appendAccepted(text, to: &value)
    binding.wrappedValue = value
}

/// Appends accepted AI text to an existing field without clobbering user text.
func appendAccepted(_ text: String, to field: inout String) {
    let addition = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !addition.isEmpty else { return }
    if field.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        field = addition
    } else {
        field += "\n" + addition
    }
}
