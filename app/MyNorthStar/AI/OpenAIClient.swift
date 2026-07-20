import Foundation

/// Minimal client for the OpenAI Chat Completions API. Data leaves the device
/// only through this call, and only when the user explicitly triggers it.
enum OpenAIClient {
    enum ClientError: LocalizedError {
        case missingAPIKey
        case badResponse
        case api(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "No OpenAI API key is set. Add one in Settings."
            case .badResponse:
                "Unexpected response from the OpenAI API."
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
        let messages: [Message]
    }

    private struct Response: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }
            let message: Message
        }
        let choices: [Choice]
    }

    private struct ErrorResponse: Decodable {
        struct APIError: Decodable {
            let message: String
        }
        let error: APIError
    }

    static func complete(
        prompt: String,
        model: String,
        apiKey: String,
        maxTokens: Int = 1500
    ) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(Request(
            model: model,
            max_tokens: maxTokens,
            messages: [
                .init(role: "system", content: AIEngine.systemPrompt),
                .init(role: "user", content: prompt),
            ]
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
        let text = response.choices.compactMap(\.message.content).joined(separator: "\n")
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
