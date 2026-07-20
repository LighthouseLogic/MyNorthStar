import Foundation

/// Minimal client for the Google Gemini generateContent API. Data leaves the
/// device only through this call, and only when the user explicitly triggers
/// it. The key travels in a header, never in the URL.
enum GeminiClient {
    enum ClientError: LocalizedError {
        case missingAPIKey
        case badResponse
        case api(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                "No Google AI API key is set. Add one in Settings."
            case .badResponse:
                "Unexpected response from the Gemini API."
            case .api(let message):
                message
            }
        }
    }

    private struct Request: Encodable {
        struct Content: Encodable {
            struct Part: Encodable {
                let text: String
            }
            var role: String?
            let parts: [Part]
        }
        struct GenerationConfig: Encodable {
            let maxOutputTokens: Int
        }
        let systemInstruction: Content
        let contents: [Content]
        let generationConfig: GenerationConfig
    }

    private struct Response: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable {
                    let text: String?
                }
                let parts: [Part]?
            }
            let content: Content?
        }
        let candidates: [Candidate]?
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
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(Request(
            systemInstruction: .init(parts: [.init(text: AIEngine.systemPrompt)]),
            contents: [.init(role: "user", parts: [.init(text: prompt)])],
            generationConfig: .init(maxOutputTokens: maxTokens)
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
        let text = (response.candidates ?? [])
            .compactMap { $0.content?.parts?.compactMap(\.text).joined(separator: "\n") }
            .joined(separator: "\n")
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
