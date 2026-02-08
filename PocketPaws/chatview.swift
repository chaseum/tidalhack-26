import SwiftUI

struct CommunityChatView: View {
    @EnvironmentObject var router: Router
    @State private var messageText = ""
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
                                    Text("Thinking...")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(DesignTokens.Colors.surface)
                                        .clipShape(Capsule())
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
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || router.isSendingChat)
                    .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || router.isSendingChat ? 0.5 : 1)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                BottomNavBar(selectedTab: $router.currentTab) { screen in
                    router.switchTab(to: screen)
                }
            }
        }
        .alert("Assistant", isPresented: Binding(
            get: { router.chatError != nil },
            set: { show in
                if !show { router.chatError = nil }
            }
        )) {
            Button("OK", role: .cancel) { router.chatError = nil }
        } message: {
            Text(router.chatError ?? "")
        }
        .navigationBarHidden(true)
    }
    
    private func send() {
        let outgoing = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !outgoing.isEmpty else { return }
        messageText = ""
        
        Task {
            await router.sendChatMessage(outgoing)
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastId = router.chatMessages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            proxy.scrollTo(lastId, anchor: .bottom)
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
