import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.claudeModel) private var model = ClaudeClient.defaultModel
    @AppStorage(SettingsKeys.useClaudeBackend) private var useClaudeBackend = false

    @State private var apiKeyField = ""
    @State private var keyIsStored = false
    @State private var customModel = ""
    @State private var usingCustomModel = false
    @State private var testState = TestState.idle
    @State private var saveError: String?

    private static let suggestedModels = [
        "claude-sonnet-5",
        "claude-opus-4-8",
        "claude-haiku-4-5-20251001",
    ]

    private enum TestState: Equatable {
        case idle
        case testing
        case success
        case failure(String)
    }

    private var onDeviceAvailability: (isAvailable: Bool, reason: String?) {
        FoundationModelsClient.availability
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Label("On-Device (AFM 3 Core)", systemImage: onDeviceAvailability.isAvailable ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(onDeviceAvailability.isAvailable ? .green : .orange)
                    Spacer()
                    if !useClaudeBackend {
                        Text("Active").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let reason = onDeviceAvailability.reason {
                    Text(reason).font(.caption).foregroundStyle(.secondary)
                }
                Toggle("Use Claude API instead", isOn: $useClaudeBackend)
                    .disabled(!keyIsStored && !useClaudeBackend)
                if !keyIsStored && !useClaudeBackend {
                    Text("Add a Claude API key below to enable this.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("AI Backend")
            } footer: {
                Text("MyNorthStar uses Apple's on-device AFM 3 Core model by default — nothing leaves this device. Turn this on to use Claude instead for any \"Ask AI\" action, using the key and model below.")
            }

            Section {
                SecureField("Anthropic API key (sk-ant-…)", text: $apiKeyField)
                    .textContentType(.password)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
                HStack {
                    Button("Save Key") { saveKey() }
                        .disabled(apiKeyField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if keyIsStored {
                        Button("Remove Key", role: .destructive) {
                            KeychainStore.deleteAPIKey()
                            keyIsStored = false
                            apiKeyField = ""
                            testState = .idle
                        }
                    }
                    Spacer()
                    if keyIsStored {
                        Label("Key stored in Keychain", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                if let saveError {
                    Text(saveError).font(.caption).foregroundStyle(.red)
                }
            } header: {
                Text("Claude API Key")
            } footer: {
                Text("Your key is stored only in the device Keychain — never in the app's database, preferences, or logs. You bring your own key from console.anthropic.com. Used only when \"Use Claude API instead\" is on above.")
            }

            Section {
                Picker("Model", selection: modelSelection) {
                    ForEach(Self.suggestedModels, id: \.self) { name in
                        Text(name).tag(name)
                    }
                    Text("Custom…").tag("custom")
                }
                if usingCustomModel {
                    TextField("Model ID (e.g. claude-sonnet-5)", text: $customModel)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                        .onSubmit { commitCustomModel() }
                    Button("Use This Model") { commitCustomModel() }
                        .disabled(customModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("Model")
            } footer: {
                Text("Default: \(ClaudeClient.defaultModel). Currently using: \(model)")
            }

            Section {
                Button {
                    testKey()
                } label: {
                    HStack {
                        Text("Test Key")
                        Spacer()
                        switch testState {
                        case .idle:
                            EmptyView()
                        case .testing:
                            ProgressView().controlSize(.small)
                        case .success:
                            Label("Key works", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        case .failure(let message):
                            Label(message, systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .lineLimit(2)
                        }
                    }
                }
                .disabled(!keyIsStored || testState == .testing)
            } footer: {
                Text("Sends a one-line test request to the Anthropic API using the stored key and selected model.")
            }

            Section("Privacy") {
                NavigationLink("Privacy Policy") {
                    PrivacyPolicyView()
                }
                Label("All framework data stays on this device. By default, Ask AI actions run entirely on-device (AFM 3 Core). Text is sent to Anthropic only if you turn on \"Use Claude API instead\" above and explicitly tap an Ask AI action.", systemImage: "lock.shield")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .onAppear {
            keyIsStored = KeychainStore.hasAPIKey
            usingCustomModel = !Self.suggestedModels.contains(model)
            if usingCustomModel { customModel = model }
        }
    }

    private var modelSelection: Binding<String> {
        Binding {
            usingCustomModel ? "custom" : model
        } set: { newValue in
            if newValue == "custom" {
                usingCustomModel = true
                customModel = model
            } else {
                usingCustomModel = false
                model = newValue
                testState = .idle
            }
        }
    }

    private func commitCustomModel() {
        let trimmed = customModel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        model = trimmed
        testState = .idle
    }

    private func saveKey() {
        do {
            try KeychainStore.saveAPIKey(apiKeyField)
            keyIsStored = KeychainStore.hasAPIKey
            apiKeyField = ""
            saveError = nil
            testState = .idle
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func testKey() {
        guard let apiKey = KeychainStore.loadAPIKey() else { return }
        testState = .testing
        let testModel = model
        Task {
            do {
                try await ClaudeClient.testKey(model: testModel, apiKey: apiKey)
                testState = .success
            } catch {
                testState = .failure(error.localizedDescription)
            }
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title.bold())
                Text("MyNorthStar — Lighthouse Logic")
                    .foregroundStyle(.secondary)

                Group {
                    Text("Your data stays on your device").font(.headline)
                    Text("Everything you enter in MyNorthStar — projects, selected values, groups, answers, alignment maps, reflections, and your personal constitution — is stored locally on this device using Apple's SwiftData. There is no account, no cloud sync, and no analytics. We do not collect, transmit, or have access to any of your content.")

                    Text("AI features are opt-in, per request").font(.headline)
                    Text("MyNorthStar includes optional \"Ask AI\" actions. By default these run entirely on this device using Apple's on-device AFM 3 Core model (part of the Foundation Models framework) — no data leaves your device. If you turn on \"Use Claude API instead\" in Settings and supply your own Anthropic API key, those same actions are powered by Anthropic's Claude API instead. Data leaves your device only when you explicitly trigger such a request while that setting is on, and only the text shown in the request preview is sent — directly to Anthropic over HTTPS, never through our servers. Responses are shown for your review and are written into your project only if you accept them. Anthropic's handling of API data is governed by Anthropic's own privacy policy.")

                    Text("Your API key").font(.headline)
                    Text("Your Anthropic API key is stored exclusively in the device Keychain and is only used when \"Use Claude API instead\" is turned on. It is never written to the app's database, preferences, exports, or logs.")

                    Text("Contact").font(.headline)
                    Text("Questions about this policy can be directed to the developer via the App Store listing.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .frame(maxWidth: 700, alignment: .leading)
        }
        .navigationTitle("Privacy Policy")
    }
}
