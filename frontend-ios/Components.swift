import SwiftUI

// MARK: - Animated Selector
struct PetPalSelector: View {
    let items: [String]
    @Binding var selection: String
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(selection == item ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selection == item {
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .matchedGeometryEffect(id: "selectorBG", in: ns)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selection = item
                        }
                    }
            }
        }
        .padding(4)
        .background(.thinMaterial, in: Capsule())
    }
}

// MARK: - Avatar & Badges
struct PetAvatarBadgeView: View {
    let pet: Pet
    var size: CGFloat = 64
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: URL(string: pet.imageURL)) { image in
                image.resizable()
            } placeholder: {
                DesignTokens.Colors.border
                    .overlay(ProgressView())
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(DesignTokens.Colors.surface, lineWidth: 2))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            LevelChip(level: pet.level)
                .offset(x: 10, y: 0)
        }
    }
}

struct LevelChip: View {
    let level: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Text("LVL")
            Text("\(level)")
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: level)
        }
        .font(DesignTokens.Typography.caption)
        .foregroundColor(.white)
        .padding(.horizontal, DesignTokens.Spacing.s)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(DesignTokens.Colors.secondary)
        .clipShape(Capsule())
    }
}

// MARK: - Chips
struct PillChip: View {
    let text: String
    var color: Color = DesignTokens.Colors.primary
    
    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, DesignTokens.Spacing.m)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Action Buttons
struct PrimaryCircleButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(DesignTokens.Colors.primary)
                .clipShape(Circle())
                .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

struct CircularAppButton: View {
    let item: LauncherItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.s) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.surface)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: item.hexColor))
                }
                
                Text(item.title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Navigation
struct BottomNavBar: View {
    @Binding var selectedTab: AppScreen
    
    var body: some View {
        HStack {
            ForEach([AppScreen.diary, AppScreen.community, AppScreen.settings], id: \.self) { screen in
                Spacer()
                Button {
                    selectedTab = screen
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon(for: screen))
                            .font(.system(size: 24))
                        Text(screen.rawValue.capitalized)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedTab == screen ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .background(DesignTokens.Colors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundColor(DesignTokens.Colors.border), alignment: .top)
    }
    
    private func icon(for screen: AppScreen) -> String {
        switch screen {
        case .diary: return "book.closed.fill"
        case .community: return "bubble.left.and.bubble.right.fill"
        case .settings: return "person.crop.circle.fill"
        default: return "questionmark"
        }
    }
}

struct Components_Preview: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            PetAvatarBadgeView(pet: MockData.pet)
            PillChip(text: "Active")
            PrimaryCircleButton(icon: "plus") {}
            CircularAppButton(item: MockData.launcherItems[0]) {}
        }
        .padding()
        .background(DesignTokens.Colors.backgroundGradient[0])
    }
}
