import SwiftUI
import Combine
import Foundation

/// App navigation states
enum AppRoute: Hashable {
    case login
    case register
    case home
    case diary
    case photos
    case community
    case health
    case shop
    case settings
}

private struct ChatRequestBody: Encodable {
    let message: String
    let session_id: String?
}

private struct ChatResponseBody: Decodable {
    let reply: String
    let quick_actions: [String]
}

private struct LoginRequestBody: Encodable {
    let email: String
    let password: String
}

private struct RegisterRequestBody: Encodable {
    let email: String
    let password: String
    let displayName: String?
}

private struct AuthUserBody: Decodable {
    let id: String
    let email: String
    let displayName: String
}

private struct AuthResponseBody: Decodable {
    let user: AuthUserBody
    let token: String
}

private struct StoredSession: Codable {
    let userId: String
    let token: String
    let petName: String?
}

@MainActor
class Router: ObservableObject {
    @Published var path = NavigationPath()
    @Published var currentTab: AppScreen = .home
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUserId: String?
    @Published private(set) var authToken: String?
    @Published var petName: String = MockData.pet.name
    @Published var isAuthenticating = false
    @Published var authError: String?

    @Published var chatMessages: [ChatMessage] = []
    @Published var suggestedChatActions: [String] = []
    @Published var isSendingChat = false
    @Published var chatError: String?

    private let chatStorageKey = "pocketpaws.chat.messages.v1"
    private let authStorageKey = "pocketpaws.auth.session.v1"
    private let gatewayBaseURL: URL
    private var chatSessionID: String = UUID().uuidString

    init() {
        gatewayBaseURL = Router.resolveGatewayBaseURL()
        restoreSession()

        if let restored = loadChatMessages(), !restored.isEmpty {
            chatMessages = restored
        } else {
            chatMessages = MockData.chatMessages
        }
    }

    func navigate(to route: AppRoute) {
        switch route {
        case .login:
            logout()
        case .home:
            popToRoot()
        default:
            path.append(route)
        }
    }

    func login(email: String, password: String) async {
        await authenticate(
            path: "auth/login",
            payload: LoginRequestBody(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        )
    }

    func register(displayName: String, email: String, password: String) async {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        await authenticate(
            path: "auth/register",
            payload: RegisterRequestBody(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                displayName: name.isEmpty ? nil : name
            )
        )
    }

    func clearAuthError() {
        authError = nil
    }

    func logout() {
        currentTab = .home
        isAuthenticated = false
        currentUserId = nil
        authToken = nil
        petName = MockData.pet.name
        authError = nil
        clearStoredSession()
        popToRoot()
    }

    func gatewayURL(path: String) -> URL {
        gatewayBaseURL.appending(path: path)
    }

    func gatewayAuthHeaders() -> [String: String] {
        var headers: [String: String] = [:]
        if let token = authToken, !token.isEmpty {
            headers["Authorization"] = "Bearer \(token)"
        }
        if let userId = currentUserId, !userId.isEmpty {
            headers["X-User-Id"] = userId
        }
        return headers
    }

    func open(screen: AppScreen) {
        switch screen {
        case .home, .diary, .community, .health, .settings:
            switchTab(to: screen)
        case .photos, .shop:
            currentTab = .home
            guard let route = route(for: screen) else { return }
            path.append(route)
        }
    }

    func switchTab(to screen: AppScreen) {
        currentTab = screen
        popToRoot()

        guard let route = route(for: screen) else { return }
        if route != .home {
            path.append(route)
        }
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        guard !path.isEmpty else { return }
        path.removeLast(path.count)
    }

    func clearChatHistory() {
        chatMessages = MockData.chatMessages
        suggestedChatActions = []
        chatSessionID = UUID().uuidString
        persistChatMessages()
    }

    func sendChatMessage(_ rawMessage: String) async {
        let message = rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        guard !isSendingChat else { return }

        chatError = nil
        appendChatMessage(
            ChatMessage(
                id: UUID(),
                senderId: "me",
                senderName: "You",
                text: message,
                timestamp: Date(),
                isMine: true
            )
        )

        isSendingChat = true
        defer { isSendingChat = false }
        let startedAt = Date()

        do {
            let response = try await requestChatReply(message: message)
            await ensureTypingVisible(since: startedAt)
            appendChatMessage(
                ChatMessage(
                    id: UUID(),
                    senderId: "assistant",
                    senderName: "Mogee Guide",
                    text: response.reply,
                    timestamp: Date(),
                    isMine: false
                )
            )
            suggestedChatActions = response.quick_actions
        } catch {
            await ensureTypingVisible(since: startedAt)
            chatError = "Could not reach the assistant service."
            appendChatMessage(
                ChatMessage(
                    id: UUID(),
                    senderId: "assistant",
                    senderName: "Mogee Guide",
                    text: "I could not reach the assistant right now. Please try again in a moment.",
                    timestamp: Date(),
                    isMine: false
                )
            )
            suggestedChatActions = []
        }
    }

    private func route(for screen: AppScreen) -> AppRoute? {
        switch screen {
        case .home: return .home
        case .diary: return .diary
        case .photos: return .photos
        case .community: return .community
        case .health: return .health
        case .shop: return .shop
        case .settings: return .settings
        }
    }

    private func appendChatMessage(_ message: ChatMessage) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            chatMessages.append(message)
        }
        persistChatMessages()
    }

    private func authenticate<Body: Encodable>(path: String, payload: Body) async {
        guard !isAuthenticating else { return }

        authError = nil
        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let endpoint = gatewayURL(path: path)
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 12
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw NSError(
                    domain: "RouterAuth",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: decodeErrorMessage(data: data, fallbackCode: httpResponse.statusCode)]
                )
            }

            let decoded = try JSONDecoder().decode(AuthResponseBody.self, from: data)
            let resolvedName = resolvedPetName(from: decoded.user.displayName)
            isAuthenticated = true
            currentUserId = decoded.user.id
            authToken = decoded.token
            petName = resolvedName
            persistSession(userId: decoded.user.id, token: decoded.token, petName: resolvedName)
            popToRoot()
            currentTab = .home
        } catch {
            isAuthenticated = false
            currentUserId = nil
            authToken = nil
            petName = MockData.pet.name
            clearStoredSession()
            authError = error.localizedDescription
        }
    }

    private func decodeErrorMessage(data: Data, fallbackCode: Int) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Request failed (\(fallbackCode))."
        }

        if let errorText = object["error"] as? String, !errorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return errorText
        }

        if let errorObject = object["error"] as? [String: Any] {
            if let message = errorObject["message"] as? String, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return message
            }
            if let code = errorObject["code"] as? String, !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return code
            }
        }

        return "Request failed (\(fallbackCode))."
    }

    private func requestChatReply(message: String) async throws -> ChatResponseBody {
        let chatURL = gatewayURL(path: "chat")
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        for (header, value) in gatewayAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: header)
        }

        let payload = ChatRequestBody(message: message, session_id: chatSessionID)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(ChatResponseBody.self, from: data)
    }

    private func ensureTypingVisible(since startedAt: Date) async {
        let minimumTypingDuration: TimeInterval = 0.8
        let elapsed = Date().timeIntervalSince(startedAt)
        guard elapsed < minimumTypingDuration else { return }
        let remaining = minimumTypingDuration - elapsed
        let nanos = UInt64(max(0, remaining) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanos)
    }

    private func persistChatMessages() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let encoded = try? encoder.encode(chatMessages) else { return }
        UserDefaults.standard.set(encoded, forKey: chatStorageKey)
    }

    private func loadChatMessages() -> [ChatMessage]? {
        guard let encoded = UserDefaults.standard.data(forKey: chatStorageKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([ChatMessage].self, from: encoded)
    }

    private func persistSession(userId: String, token: String, petName: String) {
        let session = StoredSession(userId: userId, token: token, petName: petName)
        guard let encoded = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(encoded, forKey: authStorageKey)
    }

    private func restoreSession() {
        guard let encoded = UserDefaults.standard.data(forKey: authStorageKey),
              let session = try? JSONDecoder().decode(StoredSession.self, from: encoded),
              !session.userId.isEmpty,
              !session.token.isEmpty
        else {
            return
        }

        currentUserId = session.userId
        authToken = session.token
        petName = resolvedPetName(from: session.petName ?? "")
        isAuthenticated = true
    }

    private func clearStoredSession() {
        UserDefaults.standard.removeObject(forKey: authStorageKey)
    }

    private static func resolveGatewayBaseURL() -> URL {
        let fallback = URL(string: "http://127.0.0.1:8080")!
        guard let configured = Bundle.main.object(forInfoDictionaryKey: "GATEWAY_BASE_URL") as? String,
              !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let parsed = URL(string: configured)
        else {
            return fallback
        }
        return parsed
    }

    private func resolvedPetName(from rawName: String) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? MockData.pet.name : trimmed
    }
}
