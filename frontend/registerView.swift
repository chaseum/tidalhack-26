import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var router: Router
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            PetPalBackground()
            
            VStack(spacing: DesignTokens.Spacing.xl) {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    Spacer()
                }
                .padding()
                
                Text("Join PocketPaws")
                    .font(DesignTokens.Typography.title)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                VStack(spacing: DesignTokens.Spacing.m) {
                    TextField("Pet's Name", text: $name)
                        .padding()
                        .background(DesignTokens.Colors.surface)
                        .cornerRadius(DesignTokens.Radius.m)
                        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.m).stroke(DesignTokens.Colors.border))
                    
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
                    Text("Create Account")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.primary)
                        .cornerRadius(DesignTokens.Radius.m)
                }
                .padding(.horizontal, DesignTokens.Spacing.l)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

struct RegisterView_Preview: PreviewProvider {
    static var previews: some View {
        RegisterView().environmentObject(Router())
    }
}
