import Foundation

/// Routes "Ask AI" requests to the active backend. Apple's on-device
/// AFM 3 Core (via the Foundation Models framework) is the default and
/// requires no setup, no key, and no network access. The user can opt
/// into Anthropic's Claude API — their own key, entered in Settings —
/// any time they want a larger model for a harder step. Switching is
/// always a deliberate action in Settings; the app never silently
/// substitutes one backend for the other.
enum AIEngine {
    enum Backend {
        case onDevice
        case claude
    }

    /// Manual opt-in toggle. Defaults to `false`, i.e. on-device AFM 3 Core.
    static var useClaudeBackend: Bool {
        get { UserDefaults.standard.bool(forKey: SettingsKeys.useClaudeBackend) }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKeys.useClaudeBackend) }
    }

    static var activeBackend: Backend {
        useClaudeBackend ? .claude : .onDevice
    }

    private static var claudeModel: String {
        UserDefaults.standard.string(forKey: SettingsKeys.claudeModel) ?? ClaudeClient.defaultModel
    }

    /// Short label for the currently active backend, for UI display
    /// (loading states, Settings status line, etc.).
    static var activeBackendLabel: String {
        switch activeBackend {
        case .onDevice: "Apple On-Device (AFM 3 Core)"
        case .claude: "Claude (\(claudeModel))"
        }
    }

    /// If the active backend isn't ready to send a request, a short reason
    /// to show the user (and, for on-device, a hint to switch to Claude in
    /// Settings). Returns `nil` when ready to send.
    static var readinessMessage: String? {
        switch activeBackend {
        case .onDevice:
            let (isAvailable, reason) = FoundationModelsClient.availability
            guard !isAvailable else { return nil }
            return (reason ?? "The on-device model is unavailable.")
                + " You can switch to Claude in Settings if you'd like to continue."
        case .claude:
            guard KeychainStore.hasAPIKey else {
                return "No Anthropic API key is set. Add one in Settings before using Ask AI."
            }
            return nil
        }
    }

    static var isReady: Bool { readinessMessage == nil }

    static func complete(prompt: String, maxTokens: Int = 1500) async throws -> String {
        switch activeBackend {
        case .onDevice:
            return try await FoundationModelsClient.complete(prompt: prompt, maxTokens: maxTokens)
        case .claude:
            guard let apiKey = KeychainStore.loadAPIKey(), !apiKey.isEmpty else {
                throw ClaudeClient.ClientError.missingAPIKey
            }
            return try await ClaudeClient.complete(
                prompt: prompt,
                model: claudeModel,
                apiKey: apiKey,
                maxTokens: maxTokens
            )
        }
    }
}
