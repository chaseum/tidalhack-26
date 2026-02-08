import SwiftUI

struct LoginView: View {
    @EnvironmentObject var router: Router
    @State private var email = ""
    @State private var password = ""
    
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
                        .padding()
                        .background(DesignTokens.Colors.surface)
                        .cornerRadius(DesignTokens.Radius.m)
                        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.m).stroke(DesignTokens.Colors.border))
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(DesignTokens.Colors.surface)
                        .cornerRadius(DesignTokens.Radius.m)
                        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.m).stroke(DesignTokens.Colors.border))
                }
                .padding(.horizontal, DesignTokens.Spacing.l)
                
                Button {
                    router.navigate(to: .home)
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
