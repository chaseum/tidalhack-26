import SwiftUI

// MARK: - Theme Modifiers
struct PetPalCard: ViewModifier {
    var radius: CGFloat = DesignTokens.Radius.m
    var shadow: Bool = true
    
    func body(content: Content) -> some View {
        content
            .padding(DesignTokens.Spacing.m)
            .background(DesignTokens.Colors.surface)
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
            )
            .shadow(
                color: shadow ? Color.black.opacity(DesignTokens.Shadows.mediumOpacity) : .clear,
                radius: DesignTokens.Shadows.mediumRadius,
                x: DesignTokens.Shadows.mediumOffset.x,
                y: DesignTokens.Shadows.mediumOffset.y
            )
    }
}

extension View {
    func petPalCard(radius: CGFloat = DesignTokens.Radius.m, shadow: Bool = true) -> some View {
        modifier(PetPalCard(radius: radius, shadow: shadow))
    }
}

// MARK: - Reusable Components
struct PetPalBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: DesignTokens.Colors.backgroundGradient),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct CircularIconButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(DesignTokens.Colors.primary)
                .frame(width: 48, height: 48)
                .background(DesignTokens.Colors.surface)
                .clipShape(Circle())
                .shadow(
                    color: Color.black.opacity(DesignTokens.Shadows.softOpacity),
                    radius: DesignTokens.Shadows.softRadius,
                    x: DesignTokens.Shadows.softOffset.x,
                    y: DesignTokens.Shadows.softOffset.y
                )
        }
    }
}

// MARK: - Previews
struct ThemePreviews_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            PetPalBackground()
            
            VStack(spacing: DesignTokens.Spacing.l) {
                // Header Row Preview
                HStack(spacing: DesignTokens.Spacing.m) {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(DesignTokens.Colors.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pixel")
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        LevelChip(level: 12)
                    }
                    
                    Spacer()
                    
                    CircularIconButton(icon: "bell.fill") {
                        print("Notify clicked")
                    }
                }
                .padding(.horizontal)
                
                // Card Preview
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                    Text("Daily Quest")
                        .font(DesignTokens.Typography.headline)
                    Text("Take Pixel for a 15-minute walk to earn 50 XP.")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .petPalCard()
                .padding(.horizontal)
                
                // Action Buttons Preview
                HStack(spacing: DesignTokens.Spacing.l) {
                    CircularIconButton(icon: "camera.fill") {}
                    CircularIconButton(icon: "heart.fill") {}
                    CircularIconButton(icon: "leaf.fill") {}
                }
                
                Spacer()
            }
            .padding(.top, DesignTokens.Spacing.xl)
        }
    }
}
