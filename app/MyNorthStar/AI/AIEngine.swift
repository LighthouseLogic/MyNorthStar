import Foundation

/// Routes "Ask AI" requests to the active backend. Apple's on-device
/// AFM 3 Core (via the Foundation Models framework) is the default and
/// requires no setup, no key, and no network access. The user can opt
/// into a cloud provider — Anthropic, OpenAI, or Google, with their own
/// key entered in Settings — any time they want a larger model for a
/// harder step. Switching is always a deliberate action in Settings;
/// the app never silently substitutes one backend for the other.
enum AIEngine {
    enum Backend {
        case onDevice
        case cloud(AIProvider?)   // nil: cloud selected but no key stored yet
    }

    /// Shared system prompt for every backend, on-device and cloud alike.
    static let systemPrompt = """
    You are a thinking partner inside MyNorthStar (Know Your Values), an app \
    that guides one person through a 7-step values-clarification exercise: \
    select 25 values, group them, choose a top 10, answer five self-knowledge \
    questions, map values to life areas, reflect, and draft a personal \
    constitution. Respond with concise, concrete, plain-text suggestions the \
    user can edit before accepting. Use short bullet lines starting with "•" \
    when listing items. Do not use markdown headers or code blocks. Never \
    invent facts about the user's situation; ground every suggestion in the \
    context provided.
    """

    /// Manual opt-in toggle. Defaults to `false`, i.e. on-device AFM 3 Core.
    /// (Stored under the pre-multi-provider key name for continuity.)
    static var useCloudAI: Bool {
        get { UserDefaults.standard.bool(forKey: SettingsKeys.useCloudAI) }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKeys.useCloudAI) }
    }

    /// The user's explicit provider choice, or nil for automatic order.
    static var preferredProvider: AIProvider? {
        UserDefaults.standard.string(forKey: SettingsKeys.preferredProvider)
            .flatMap(AIProvider.init(rawValue:))
    }

    /// The cloud provider that would serve a request: the preferred provider
    /// if it has a key, otherwise the first of Anthropic → OpenAI → Google
    /// with a stored key.
    static var activeCloudProvider: AIProvider? {
        if let preferred = preferredProvider, KeychainStore.hasAPIKey(for: preferred) {
            return preferred
        }
        return KeychainStore.providersWithKeys.first
    }

    static var activeBackend: Backend {
        useCloudAI ? .cloud(activeCloudProvider) : .onDevice
    }

    /// Short label for the currently active backend, for UI display
    /// (loading states, Settings status line, etc.).
    static var activeBackendLabel: String {
        switch activeBackend {
        case .onDevice:
            "Apple On-Device (AFM 3 Core)"
        case .cloud(let provider?):
            "\(provider.assistantName) (\(provider.selectedModel))"
        case .cloud(nil):
            "Cloud AI (no key set)"
        }
    }

    /// If the active backend isn't ready to send a request, a short reason
    /// to show the user. Returns `nil` when ready to send.
    static var readinessMessage: String? {
        switch activeBackend {
        case .onDevice:
            let (isAvailable, reason) = FoundationModelsClient.availability
            guard !isAvailable else { return nil }
            return (reason ?? "The on-device model is unavailable.")
                + " You can switch to a cloud provider in Settings if you'd like to continue."
        case .cloud(nil):
            return "No API key is set for any provider. Add one in Settings before using Ask AI."
        case .cloud(.some):
            return nil
        }
    }

    static var isReady: Bool { readinessMessage == nil }

    static func complete(prompt: String, maxTokens: Int = 1500) async throws -> String {
        switch activeBackend {
        case .onDevice:
            return try await FoundationModelsClient.complete(prompt: prompt, maxTokens: maxTokens)
        case .cloud(let provider):
            guard let provider,
                  let apiKey = KeychainStore.loadAPIKey(for: provider), !apiKey.isEmpty else {
                throw ClaudeClient.ClientError.missingAPIKey
            }
            let model = provider.selectedModel
            switch provider {
            case .anthropic:
                return try await ClaudeClient.complete(
                    prompt: prompt, model: model, apiKey: apiKey, maxTokens: maxTokens
                )
            case .openai:
                return try await OpenAIClient.complete(
                    prompt: prompt, model: model, apiKey: apiKey, maxTokens: maxTokens
                )
            case .google:
                return try await GeminiClient.complete(
                    prompt: prompt, model: model, apiKey: apiKey, maxTokens: maxTokens
                )
            }
        }
    }

    /// One-line key check against the given provider's API.
    static func testKey(provider: AIProvider, apiKey: String) async throws {
        let model = provider.selectedModel
        switch provider {
        case .anthropic:
            try await ClaudeClient.testKey(model: model, apiKey: apiKey)
        case .openai:
            try await OpenAIClient.testKey(model: model, apiKey: apiKey)
        case .google:
            try await GeminiClient.testKey(model: model, apiKey: apiKey)
        }
    }
}
