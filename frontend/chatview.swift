import SwiftUI

struct CommunityChatView: View {
    @EnvironmentObject var router: Router
    let messages = MockData.chatMessages
    @State private var messageText = ""
    
    var body: some View {
        ZStack {
            PetPalBackground()
            
            VStack {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left").foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    Text("Community").font(DesignTokens.Typography.headline)
                    Spacer()
                    Image(systemName: "person.2.fill")
                }
                .padding()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: DesignTokens.Spacing.m) {
                            ForEach(messages) { msg in
                                ChatBubble(message: msg)
                            }
                        }
                        .padding()
                    }
                }
                
                // Composer
                HStack(spacing: DesignTokens.Spacing.m) {
                    TextField("Share a tip...", text: $messageText)
                        .padding(DesignTokens.Spacing.m)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(DesignTokens.Colors.border))
                    
                    Button {
                        messageText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(DesignTokens.Colors.primary)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(DesignTokens.Colors.surface.opacity(0.8))
            }
        }
        .navigationBarHidden(true)
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isMine { Spacer() }
            
            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 4) {
                if !message.isMine {
                    Text(message.senderName)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Text(message.text)
                    .padding()
                    .background(message.isMine ? DesignTokens.Colors.primary : DesignTokens.Colors.surface)
                    .foregroundColor(message.isMine ? .white : DesignTokens.Colors.textPrimary)
                    .cornerRadius(DesignTokens.Radius.m)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            
            if !message.isMine { Spacer() }
        }
    }
}

struct CommunityChatView_Preview: PreviewProvider {
    static var previews: some View {
        CommunityChatView().environmentObject(Router())
    }
}
