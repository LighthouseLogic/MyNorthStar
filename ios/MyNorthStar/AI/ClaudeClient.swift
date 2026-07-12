import Foundation

/// Minimal client for the Anthropic Messages API. Data leaves the device only
/// through this call, and only when the user explicitly triggers it.
enum ClaudeClient {
    static let defaultModel = "claude-sonnet-5"

    enum ClientError: LocalizedError {
        case missingAPIKey
        case badResponse
        case api(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "No Anthropic API key is set. Add one in Settings."
            case .badResponse:
                "Unexpected response from the Anthropic API."
            case .api(let message):
                message
            }
        }
    }

    private struct Request: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]
    }

    private struct Response: Decodable {
        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
        let content: [ContentBlock]
    }

    private struct ErrorResponse: Decodable {
        struct APIError: Decodable {
            let message: String
        }
        let error: APIError
    }

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

    static func complete(
        prompt: String,
        model: String,
        apiKey: String,
        maxTokens: Int = 1500
    ) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(Request(
            model: model,
            max_tokens: maxTokens,
            system: systemPrompt,
            messages: [.init(role: "user", content: prompt)]
        ))

        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        guard let http = urlResponse as? HTTPURLResponse else {
            throw ClientError.badResponse
        }
        guard http.statusCode == 200 else {
            if let apiError = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ClientError.api(apiError.error.message)
            }
            throw ClientError.api("Request failed with status \(http.statusCode).")
        }
        let response = try JSONDecoder().decode(Response.self, from: data)
        let text = response.content.compactMap(\.text).joined(separator: "\n")
        guard !text.isEmpty else { throw ClientError.badResponse }
        return text
    }

    /// Sends a tiny request to verify the key and model are valid.
    static func testKey(model: String, apiKey: String) async throws {
        _ = try await complete(
            prompt: "Reply with the single word: ok",
            model: model,
            apiKey: apiKey,
            maxTokens: 16
        )
    }
}
