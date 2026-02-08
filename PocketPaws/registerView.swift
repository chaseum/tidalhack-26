import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var router: Router
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var didAppear = false

    private var canCreateAccount: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            PetPalBackground()

            VStack(spacing: DesignTokens.Spacing.l) {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(DesignTokens.Colors.primary, in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.l)
                .padding(.top, 10)

                VStack(spacing: 8) {
                    Text("Join PocketPaws")
                        .font(DesignTokens.Typography.title)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Text("Create your playful pet companion account")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
                    inputField(icon: "pawprint.fill", title: "Pet Name") {
                        TextField("Mogee", text: $name)
                    }

                    inputField(icon: "envelope.fill", title: "Email") {
                        TextField("hello@pocketpaws.app", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(.emailAddress)
                    }

                    inputField(icon: "lock.fill", title: "Password") {
                        SecureField("Create password", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(.newPassword)
                    }

                    Button {
                        Task {
                            await router.register(displayName: name, email: email, password: password)
                        }
                    } label: {
                        Text(router.isAuthenticating ? "Creating..." : "Create Account")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [DesignTokens.Colors.primary, DesignTokens.Colors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canCreateAccount || router.isAuthenticating)
                    .opacity(canCreateAccount && !router.isAuthenticating ? 1 : 0.6)

                    if let authError = router.authError {
                        Text(authError)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.red)
                    }
                }
                .petPalCard(radius: 28, shadow: true)
                .padding(.horizontal, DesignTokens.Spacing.l)
                .scaleEffect(didAppear ? 1 : 0.96)
                .opacity(didAppear ? 1 : 0)

                Spacer()
            }
            .padding(.bottom, DesignTokens.Spacing.m)
        }
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
                didAppear = true
            }
            router.clearAuthError()
        }
        .navigationBarHidden(true)
    }

    private func inputField<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(width: 20)

                content()
                    .font(DesignTokens.Typography.body)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
            )
        }
    }
}

struct RegisterView_Preview: PreviewProvider {
    static var previews: some View {
        RegisterView().environmentObject(Router())
    }
}
