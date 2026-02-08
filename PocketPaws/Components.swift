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
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(selection == item ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selection == item {
                            Capsule()
                                .fill(DesignTokens.Colors.surface)
                                .overlay(
                                    Capsule().stroke(DesignTokens.Colors.border, lineWidth: 1)
                                )
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
        .background(DesignTokens.Colors.surface, in: Capsule())
        .overlay(Capsule().stroke(DesignTokens.Colors.border, lineWidth: 1))
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
            .overlay(Circle().stroke(DesignTokens.Colors.border, lineWidth: 1))
            
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
                .overlay(Circle().stroke(DesignTokens.Colors.border, lineWidth: 1))
        }
    }
}

struct CircularAppButton: View {
    let item: LauncherItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.s) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: item.hexColor).opacity(0.22))
                    .overlay(
                        Image(systemName: item.icon)
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(Color(hex: item.hexColor))
                    )
                    .frame(width: 78, height: 78)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(hex: item.hexColor).opacity(0.35), lineWidth: 1)
                    )
                
                Text(item.title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Navigation
struct BottomNavBar: View {
    @Binding var selectedTab: AppScreen
    var onSelect: (AppScreen) -> Void = { _ in }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            navItem(.diary)
            navItem(.community)
            
            Button {
                select(.home)
            } label: {
                Image(systemName: icon(for: .home))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(DesignTokens.Colors.primary)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(DesignTokens.Colors.surface, lineWidth: 3))
                    .padding(.bottom, 8)
            }
            .buttonStyle(.plain)
            
            navItem(.health)
            navItem(.settings)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(DesignTokens.Colors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundColor(DesignTokens.Colors.border), alignment: .top)
    }
    
    private func navItem(_ screen: AppScreen) -> some View {
        Button {
            select(screen)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon(for: screen))
                    .font(.system(size: 19, weight: .semibold))
                Text(title(for: screen))
                    .font(DesignTokens.Typography.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedTab == screen ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
        }
        .buttonStyle(.plain)
    }
    
    private func select(_ screen: AppScreen) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            selectedTab = screen
        }
        onSelect(screen)
    }
    
    private func title(for screen: AppScreen) -> String {
        switch screen {
        case .home: return "Home"
        case .diary: return "Diary"
        case .community: return "Ask"
        case .health: return "Health"
        case .settings: return "Settings"
        case .photos: return "Photos"
        case .shop: return "Shop"
        }
    }
    
    private func icon(for screen: AppScreen) -> String {
        switch screen {
        case .home: return "house.fill"
        case .diary: return "book.closed.fill"
        case .community: return "bubble.left.and.bubble.right.fill"
        case .health: return "heart.text.square.fill"
        case .settings: return "gearshape.fill"
        case .photos: return "photo.on.rectangle"
        case .shop: return "bag.fill"
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
