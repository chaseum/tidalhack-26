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

@MainActor
class Router: ObservableObject {
    @Published var path = NavigationPath()
    @Published var currentTab: AppScreen = .home
    @Published private(set) var isAuthenticated = false
    @Published var chatMessages: [ChatMessage] = []
    @Published var suggestedChatActions: [String] = []
    @Published var isSendingChat = false
    @Published var chatError: String?
    
    private let chatStorageKey = "pocketpaws.chat.messages.v1"
    private let gatewayBaseURL: URL
    private var chatSessionID: String = UUID().uuidString
    
    init() {
        gatewayBaseURL = Router.resolveGatewayBaseURL()
        
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
    
    func login() {
        isAuthenticated = true
        currentTab = .home
        popToRoot()
    }
    
    func logout() {
        currentTab = .home
        isAuthenticated = false
        popToRoot()
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
        
        do {
            let response = try await requestChatReply(message: message)
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
    
    private func requestChatReply(message: String) async throws -> ChatResponseBody {
        let chatURL = gatewayBaseURL.appending(path: "chat")
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 12
        
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
    
    private static func resolveGatewayBaseURL() -> URL {
        let fallback = URL(string: "http://127.0.0.1:8000")!
        guard let configured = Bundle.main.object(forInfoDictionaryKey: "GATEWAY_BASE_URL") as? String,
              !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let parsed = URL(string: configured)
        else {
            return fallback
        }
        return parsed
    }
}
