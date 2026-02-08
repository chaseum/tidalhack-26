import SwiftUI
import PhotosUI
import UIKit

private struct ChatPhotoUploadRequest: Encodable {
    let petId: String?
    let fileName: String
    let mimeType: String
    let base64Data: String
    let caption: String
    let date: String
}

private struct ChatUploadedPhoto: Decodable {
    let objectUrl: String
}

private struct ChatPhotoUploadResponse: Decodable {
    let photo: ChatUploadedPhoto?
}

struct CommunityChatView: View {
    @EnvironmentObject var router: Router
    @State private var messageText = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var attachedChatImage: UIImage?
    @State private var chatPhotoUploadError: String?
    @State private var isUploadingChatPhoto = false
    @FocusState private var composerFocused: Bool

    var body: some View {
        ZStack {
            PetPalBackground()

            VStack(spacing: 0) {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mogee Assistant")
                            .font(DesignTokens.Typography.headline)
                        Text("Powered by Featherless AI")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }

                    Spacer()

                    Button {
                        router.clearChatHistory()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                .padding()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(router.chatMessages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }

                            if router.isSendingChat {
                                HStack {
                                    TypingIndicatorBubble()
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .padding(.bottom, 10)
                    }
                    .onChange(of: router.chatMessages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy)
                    }
                }

                if !router.suggestedChatActions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(router.suggestedChatActions, id: \.self) { action in
                                Button {
                                    messageText = action
                                    composerFocused = true
                                } label: {
                                    Text(action)
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(DesignTokens.Colors.surface)
                                        .overlay(
                                            Capsule().stroke(DesignTokens.Colors.border, lineWidth: 1)
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                Text(attachedChatImage == nil ? "Add photo" : "Change")
                            }
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(DesignTokens.Colors.surface)
                            .overlay(
                                Capsule()
                                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
                            )
                            .clipShape(Capsule())
                        }

                        if let image = attachedChatImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(DesignTokens.Colors.border, lineWidth: 1)
                                    )

                                Button {
                                    attachedChatImage = nil
                                    selectedPhotoItem = nil
                                    chatPhotoUploadError = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.45), in: Circle())
                                }
                                .offset(x: 6, y: -6)
                                .buttonStyle(.plain)
                            }
                        }

                        Spacer()

                        if isUploadingChatPhoto {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Uploading...")
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                        }
                    }

                    if let uploadError = chatPhotoUploadError {
                        Text(uploadError)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.accentDestructive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 10) {
                        TextField("Ask about your pet's care...", text: $messageText, axis: .vertical)
                            .lineLimit(1...4)
                            .padding(12)
                            .background(DesignTokens.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
                            )
                            .focused($composerFocused)

                        Button {
                            send()
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(DesignTokens.Colors.primary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSendMessage)
                        .opacity(canSendMessage ? 1 : 0.5)
                    }

                    if let chatError = router.chatError {
                        Text(chatError)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.accentDestructive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                BottomNavBar(selectedTab: $router.currentTab) { screen in
                    router.switchTab(to: screen)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await loadSelectedPhoto(item: newItem)
            }
        }
        .navigationBarHidden(true)
    }

    private var canSendMessage: Bool {
        if router.isSendingChat || isUploadingChatPhoto {
            return false
        }

        if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        return attachedChatImage != nil
    }

    private func send() {
        let outgoing = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageToUpload = attachedChatImage
        guard !outgoing.isEmpty || imageToUpload != nil else { return }

        messageText = ""
        chatPhotoUploadError = nil
        router.chatError = nil

        Task {
            var composedMessage = outgoing

            if let imageToUpload {
                do {
                    isUploadingChatPhoto = true
                    defer { isUploadingChatPhoto = false }

                    let uploadedImageURL = try await uploadPhotoForChat(image: imageToUpload)
                    let attachmentContext = "Photo URL: \(uploadedImageURL)"
                    if composedMessage.isEmpty {
                        composedMessage = "Please review this pet photo and share care guidance.\n\n\(attachmentContext)"
                    } else {
                        composedMessage += "\n\n\(attachmentContext)"
                    }

                    withAnimation(.easeOut(duration: 0.2)) {
                        attachedChatImage = nil
                    }
                    selectedPhotoItem = nil
                } catch {
                    let message = error.localizedDescription
                    if outgoing.isEmpty {
                        chatPhotoUploadError = message
                        return
                    }
                    chatPhotoUploadError = "\(message) Sending text only."
                }
            }

            let finalMessage = composedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !finalMessage.isEmpty else { return }
            await router.sendChatMessage(finalMessage)
        }
    }

    private func loadSelectedPhoto(item: PhotosPickerItem) async {
        chatPhotoUploadError = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                throw NSError(
                    domain: "CommunityChatView",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Could not read that photo. Try another one."]
                )
            }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                attachedChatImage = image
            }
        } catch {
            attachedChatImage = nil
            chatPhotoUploadError = "Could not load selected photo."
        }
    }

    private func uploadPhotoForChat(image: UIImage) async throws -> String {
        guard router.isAuthenticated else {
            throw NSError(
                domain: "CommunityChatView",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Please sign in to upload photos in chat."]
            )
        }

        guard let jpegData = optimizedJPEGData(
            from: image,
            maxDimension: 720,
            maxBytes: 55_000
        ) else {
            throw NSError(
                domain: "CommunityChatView",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Photo is too large to upload right now. Try a different photo."]
            )
        }

        let dateStamp = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let fileName = "ios-chat-\(UUID().uuidString).jpg"

        let payload = ChatPhotoUploadRequest(
            petId: nil,
            fileName: fileName,
            mimeType: "image/jpeg",
            base64Data: jpegData.base64EncodedString(),
            caption: "Uploaded from iOS chat",
            date: String(dateStamp)
        )

        var request = URLRequest(url: router.gatewayURL(path: "photos/upload"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (header, value) in router.gatewayAuthHeaders() {
            request.setValue(value, forHTTPHeaderField: header)
        }

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw NSError(
                domain: "CommunityChatView",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: decodeGatewayError(data: data, statusCode: http.statusCode)]
            )
        }

        let decoded = try JSONDecoder().decode(ChatPhotoUploadResponse.self, from: data)
        guard let objectUrl = decoded.photo?.objectUrl,
              !objectUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw NSError(
                domain: "CommunityChatView",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Upload succeeded but no photo URL was returned."]
            )
        }

        return objectUrl
    }

    private func optimizedJPEGData(from image: UIImage, maxDimension: CGFloat, maxBytes: Int) -> Data? {
        var candidate = resizedImage(image, maxDimension: maxDimension)
        let qualitySteps: [CGFloat] = [0.72, 0.6, 0.5, 0.4, 0.32, 0.25, 0.2, 0.16, 0.12]

        for _ in 0..<5 {
            for quality in qualitySteps {
                guard let data = candidate.jpegData(compressionQuality: quality) else { continue }
                if data.count <= maxBytes {
                    return data
                }
            }

            let longestSide = max(candidate.size.width, candidate.size.height)
            guard longestSide > 220 else { break }

            let nextMaxDimension = max(longestSide * 0.82, 220)
            candidate = resizedImage(candidate, maxDimension: nextMaxDimension)
        }

        guard let fallback = candidate.jpegData(compressionQuality: 0.1) else { return nil }
        return fallback.count <= maxBytes ? fallback : nil
    }

    private func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        let longestSide = max(originalSize.width, originalSize.height)
        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(
            width: max(1, floor(originalSize.width * scale)),
            height: max(1, floor(originalSize.height * scale))
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func decodeGatewayError(data: Data, statusCode: Int) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Photo upload failed (\(statusCode))."
        }

        if let text = object["error"] as? String,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }

        if let errObject = object["error"] as? [String: Any] {
            if let message = errObject["message"] as? String,
               !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return message
            }
            if let code = errObject["code"] as? String,
               !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return code
            }
        }

        return "Photo upload failed (\(statusCode))."
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastId = router.chatMessages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }
}

struct TypingIndicatorBubble: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.35)) { context in
            let frame = Int(context.date.timeIntervalSinceReferenceDate / 0.35) % 3 + 1
            let dots = String(repeating: ".", count: frame)

            Text("Typing\(dots)")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DesignTokens.Colors.surface)
                .clipShape(Capsule())
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isMine { Spacer(minLength: 40) }

            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 4) {
                if !message.isMine {
                    Text(message.senderName)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }

                Text(message.text)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(message.isMine ? .white : DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isMine ? DesignTokens.Colors.primary : DesignTokens.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(message.isMine ? DesignTokens.Colors.primary : DesignTokens.Colors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if !message.isMine { Spacer(minLength: 40) }
        }
    }
}

struct CommunityChatView_Preview: PreviewProvider {
    static var previews: some View {
        CommunityChatView().environmentObject(Router())
    }
}
