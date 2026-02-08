import SwiftUI

struct LoginView: View {
    @EnvironmentObject var router: Router
    @State private var email = ""
    @State private var password = ""
    @State private var didAppear = false

    private var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        ZStack {
            PetPalBackground()

            VStack(spacing: DesignTokens.Spacing.l) {
                Spacer(minLength: 42)

                hero

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
                    Text("Welcome back")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Text("Sign in to keep your pet diary, mood logs, and daily routines synced.")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)

                    inputField(icon: "envelope.fill", title: "Email") {
                        TextField("hello@pocketpaws.app", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(.emailAddress)
                    }

                    inputField(icon: "lock.fill", title: "Password") {
                        SecureField("Enter password", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(.password)
                    }

                    Button {
                        Task {
                            await router.login(email: email, password: password)
                        }
                    } label: {
                        Text(router.isAuthenticating ? "Signing In..." : "Enter PocketPaws")
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
                    .disabled(!canLogin || router.isAuthenticating)
                    .opacity(canLogin && !router.isAuthenticating ? 1 : 0.6)

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

                Button {
                    router.navigate(to: .register)
                } label: {
                    Text("New here? Create your account")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.65), in: Capsule())
                }
                .buttonStyle(.plain)

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

    private var hero: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DesignTokens.Colors.cardLilac, DesignTokens.Colors.secondary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 108, height: 108)
                .overlay(
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.14), radius: 12, x: 0, y: 7)

            Text("PocketPaws")
                .font(DesignTokens.Typography.title)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            Text("Your playful companion app")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
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

struct LoginView_Preview: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(Router())
    }
}
