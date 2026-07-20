import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.useCloudAI) private var useCloudAI = false
    @AppStorage(SettingsKeys.preferredProvider) private var preferredProviderRaw = "auto"

    /// Bumped by provider sections when keys change, so the backend section
    /// re-reads Keychain state.
    @State private var keychainGeneration = 0
    @State private var anyKeyStored = false

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
                    if !useCloudAI {
                        Text("Active").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let reason = onDeviceAvailability.reason {
                    Text(reason).font(.caption).foregroundStyle(.secondary)
                }
                Toggle("Use a cloud provider instead", isOn: $useCloudAI)
                    .disabled(!anyKeyStored && !useCloudAI)
                if !anyKeyStored && !useCloudAI {
                    Text("Add an API key below to enable this.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if useCloudAI {
                    Picker("Preferred provider", selection: $preferredProviderRaw) {
                        Text("Automatic").tag("auto")
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider.rawValue)
                        }
                    }
                    HStack {
                        Text("Active for Ask AI")
                        Spacer()
                        Text(AIEngine.activeBackendLabel)
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }
            } header: {
                Text("AI Backend")
            } footer: {
                Text("MyNorthStar uses Apple's on-device AFM 3 Core model by default — nothing leaves this device. Turn this on to use a cloud provider instead for any \"Ask AI\" action. Automatic order prefers Anthropic, then OpenAI, then Google, among providers with a stored key; picking a preferred provider overrides that.")
            }
            .id(keychainGeneration)

            ForEach(AIProvider.allCases) { provider in
                ProviderSection(provider: provider) {
                    refreshKeyState()
                }
            }

            Section("Privacy") {
                NavigationLink("Privacy Policy") {
                    PrivacyPolicyView()
                }
                Label("All framework data stays on this device. By default, Ask AI actions run entirely on-device (AFM 3 Core). Text is sent to a cloud provider (Anthropic, OpenAI, or Google) only if you turn on \"Use a cloud provider instead\" above and explicitly tap an Ask AI action.", systemImage: "lock.shield")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .onAppear(perform: refreshKeyState)
    }

    private func refreshKeyState() {
        anyKeyStored = KeychainStore.anyProviderHasKey
        keychainGeneration += 1
    }
}

/// One provider's key + model management: secure key field, Keychain-backed
/// storage, hardcoded model picker, and a per-provider key test.
private struct ProviderSection: View {
    let provider: AIProvider
    let onKeysChanged: () -> Void

    @State private var keyField = ""
    @State private var keyIsStored = false
    @State private var saveError: String?
    @State private var testState = TestState.idle
    @State private var model = ""

    private enum TestState: Equatable {
        case idle
        case testing
        case success
        case failure(String)
    }

    var body: some View {
        Section {
            SecureField(provider.keyFieldPlaceholder, text: $keyField)
                .textContentType(.password)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
            HStack {
                Button("Save Key") { saveKey() }
                    .disabled(keyField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if keyIsStored {
                    Button("Remove Key", role: .destructive) {
                        KeychainStore.deleteAPIKey(for: provider)
                        keyIsStored = false
                        keyField = ""
                        testState = .idle
                        onKeysChanged()
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

            Picker("Model", selection: $model) {
                ForEach(modelOptions, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .onChange(of: model) {
                UserDefaults.standard.set(model, forKey: provider.modelSettingsKey)
                testState = .idle
            }

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
        } header: {
            Text(provider.displayName)
        } footer: {
            Text("Your own key from \(provider.keySource), stored only in the device Keychain — never in the app's database, preferences, or logs. Default model: \(provider.defaultModel).")
        }
        .onAppear {
            keyIsStored = KeychainStore.hasAPIKey(for: provider)
            model = provider.selectedModel
        }
    }

    /// Hardcoded list, plus the stored value if it isn't in the list (e.g. a
    /// custom model ID saved before multi-provider support).
    private var modelOptions: [String] {
        var options = provider.models
        if !model.isEmpty, !options.contains(model) {
            options.append(model)
        }
        return options
    }

    private func saveKey() {
        do {
            try KeychainStore.saveAPIKey(keyField, for: provider)
            keyIsStored = KeychainStore.hasAPIKey(for: provider)
            keyField = ""
            saveError = nil
            testState = .idle
            onKeysChanged()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func testKey() {
        guard let apiKey = KeychainStore.loadAPIKey(for: provider) else { return }
        testState = .testing
        let testedProvider = provider
        Task {
            do {
                try await AIEngine.testKey(provider: testedProvider, apiKey: apiKey)
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
                    Text("MyNorthStar includes optional \"Ask AI\" actions. By default these run entirely on this device using Apple's on-device AFM 3 Core model (part of the Foundation Models framework) — no data leaves your device. If you turn on \"Use a cloud provider instead\" in Settings and supply your own API key for Anthropic, OpenAI, or Google, those same actions are powered by that provider's API instead. Data leaves your device only when you explicitly trigger such a request while that setting is on, and only the text shown in the request preview is sent — directly to the provider over HTTPS, never through our servers. Responses are shown for your review and are written into your project only if you accept them. Each provider's handling of API data is governed by that provider's own privacy policy.")

                    Text("Your API keys").font(.headline)
                    Text("Your API keys are stored exclusively in the device Keychain and are only used when \"Use a cloud provider instead\" is turned on. They are never written to the app's database, preferences, exports, or logs.")

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
