import Foundation

/// A cloud AI provider the user can bring their own API key for.
/// `allCases` order is the automatic preference order when several
/// providers have keys: Anthropic → OpenAI → Google.
enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case anthropic
    case openai
    case google

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic: "Anthropic"
        case .openai: "OpenAI"
        case .google: "Google"
        }
    }

    /// Name of the assistant itself, for "Asking …" style labels.
    var assistantName: String {
        switch self {
        case .anthropic: "Claude"
        case .openai: "OpenAI"
        case .google: "Gemini"
        }
    }

    /// Hardcoded model lists — no live fetch.
    var models: [String] {
        switch self {
        case .anthropic: ["claude-sonnet-5", "claude-opus-4-8", "claude-haiku-4-5-20251001"]
        case .openai: ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo"]
        case .google: ["gemini-2.0-flash", "gemini-2.5-pro", "gemini-1.5-flash"]
        }
    }

    var defaultModel: String { models[0] }

    /// UserDefaults key holding the selected model. Anthropic keeps the
    /// pre-multi-provider key so existing users' selections carry over.
    var modelSettingsKey: String {
        switch self {
        case .anthropic: SettingsKeys.claudeModel
        case .openai: SettingsKeys.openAIModel
        case .google: SettingsKeys.googleModel
        }
    }

    /// Keychain account name. Anthropic keeps the pre-multi-provider
    /// account so existing users' stored keys carry over.
    var keychainAccount: String {
        switch self {
        case .anthropic: "anthropic-api-key"
        case .openai: "openai-api-key"
        case .google: "google-api-key"
        }
    }

    var selectedModel: String {
        UserDefaults.standard.string(forKey: modelSettingsKey) ?? defaultModel
    }

    var keyFieldPlaceholder: String {
        switch self {
        case .anthropic: "Anthropic API key (sk-ant-…)"
        case .openai: "OpenAI API key (sk-…)"
        case .google: "Google AI API key"
        }
    }

    /// Where the user gets a key, for Settings footers.
    var keySource: String {
        switch self {
        case .anthropic: "console.anthropic.com"
        case .openai: "platform.openai.com"
        case .google: "aistudio.google.com"
        }
    }
}
