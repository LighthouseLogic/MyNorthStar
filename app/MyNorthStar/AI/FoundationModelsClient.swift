import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Wraps Apple's on-device Foundation Models framework running AFM 3 Core —
/// the default AI backend. Nothing sent through this path ever leaves the
/// device; there is no network request and no API key involved.
enum FoundationModelsClient {
    enum ClientError: LocalizedError {
        case unsupportedPlatform
        case unavailable(String)
        case emptyResponse
        case generationFailed(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedPlatform:
                "On-device AI requires a newer OS with Apple Intelligence support."
            case .unavailable(let reason):
                reason
            case .emptyResponse:
                "The on-device model returned an empty response."
            case .generationFailed(let message):
                message
            }
        }
    }

    /// Whether AFM 3 Core is ready to use on this device right now, and if
    /// not, a human-readable reason suitable for display in Settings or
    /// next to a disabled "Ask AI" action.
    static var availability: (isAvailable: Bool, reason: String?) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return (true, nil)
            case .unavailable(.deviceNotEligible):
                return (false, "This device doesn't support Apple Intelligence.")
            case .unavailable(.appleIntelligenceNotEnabled):
                return (false, "Turn on Apple Intelligence in Settings to use the on-device model.")
            case .unavailable(.modelNotReady):
                return (false, "The on-device model is still downloading. Try again shortly.")
            case .unavailable(let other):
                return (false, "On-device model unavailable (\(other)).")
            }
        } else {
            return (false, "Requires iOS 26 / macOS 26 or later.")
        }
        #else
        return (false, "On-device AI isn't supported in this build.")
        #endif
    }

    /// Runs one prompt through the on-device AFM 3 Core model and returns
    /// its plain-text response. Mirrors `ClaudeClient.complete`'s shape so
    /// the two backends are interchangeable behind `AIEngine`.
    static func complete(prompt: String, maxTokens: Int = 1500) async throws -> String {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 26.0, *) else {
            throw ClientError.unsupportedPlatform
        }
        let (isAvailable, reason) = availability
        guard isAvailable else {
            throw ClientError.unavailable(reason ?? "On-device model is unavailable.")
        }
        let session = LanguageModelSession(instructions: AIEngine.systemPrompt)
        do {
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw ClientError.emptyResponse }
            return text
        } catch let error as ClientError {
            throw error
        } catch {
            throw ClientError.generationFailed(error.localizedDescription)
        }
        #else
        throw ClientError.unsupportedPlatform
        #endif
    }
}
