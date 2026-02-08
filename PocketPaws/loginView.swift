import SwiftUI

struct LoginView: View {
    @EnvironmentObject var router: Router
    @State private var email = ""
    @State private var password = ""
    
    private var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }
    
    var body: some View {
        ZStack {
            PetPalBackground()
            
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()
                
                // Logo
                VStack(spacing: DesignTokens.Spacing.m) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 80))
                        .foregroundColor(DesignTokens.Colors.primary)
                    Text("PocketPaws")
                        .font(DesignTokens.Typography.title)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                // Form
                VStack(spacing: DesignTokens.Spacing.m) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(DesignTokens.Colors.surface)
                        .cornerRadius(DesignTokens.Radius.m)
                        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.m).stroke(DesignTokens.Colors.border))
                    
                    SecureField("Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.password)
                        .padding()
                        .background(DesignTokens.Colors.surface)
                        .cornerRadius(DesignTokens.Radius.m)
                        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.m).stroke(DesignTokens.Colors.border))
                }
                .padding(.horizontal, DesignTokens.Spacing.l)
                
                Button {
                    router.login()
                } label: {
                    Text("Login")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.primary)
                        .cornerRadius(DesignTokens.Radius.m)
                }
                .padding(.horizontal, DesignTokens.Spacing.l)
                .disabled(!canLogin)
                .opacity(canLogin ? 1 : 0.6)
                
                Button {
                    router.navigate(to: .register)
                } label: {
                    Text("Don't have an account? Sign Up")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

struct LoginView_Preview: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(Router())
    }
}
