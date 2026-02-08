import SwiftUI

// MARK: - Animated Selector
struct PetPalSelector: View {
    let items: [String]
    @Binding var selection: String
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(selection == item ? Color.white : DesignTokens.Colors.textSecondary)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selection == item {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [DesignTokens.Colors.primary, DesignTokens.Colors.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
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
        .padding(6)
        .background(DesignTokens.Colors.surface.opacity(0.96), in: Capsule())
        .overlay(Capsule().stroke(DesignTokens.Colors.border, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Avatar & Badges
struct PetAvatarBadgeView: View {
    let pet: Pet
    var size: CGFloat = 64

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: URL(string: pet.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                DesignTokens.Colors.border
                    .overlay(ProgressView())
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 4))
            .overlay(Circle().stroke(DesignTokens.Colors.border, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 5)

            LevelChip(level: pet.level)
                .offset(x: 10, y: 4)
        }
    }
}

struct LevelChip: View {
    let level: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("LVL")
            Text("\(level)")
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: level)
        }
        .font(DesignTokens.Typography.pixel)
        .foregroundColor(.white)
        .padding(.horizontal, DesignTokens.Spacing.s)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(DesignTokens.Colors.primary)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
    }
}

// MARK: - Chips
struct PillChip: View {
    let text: String
    var color: Color = DesignTokens.Colors.primary

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.caption)
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
                .frame(width: 66, height: 66)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.primary, DesignTokens.Colors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(Circle().stroke(Color.white.opacity(0.65), lineWidth: 2))
                .shadow(color: Color.black.opacity(0.2), radius: 9, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

struct CircularAppButton: View {
    let item: LauncherItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.s) {
                let baseColor = Color(hex: item.hexColor)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                baseColor.opacity(0.96),
                                baseColor.opacity(0.76)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 34, height: 34)
                            .offset(x: -22, y: -24)
                    )
                    .overlay(
                        Image(systemName: item.icon)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color.white)
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 2)
                    )
                    .shadow(color: baseColor.opacity(0.32), radius: 10, x: 0, y: 6)

                Text(item.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Navigation
struct BottomNavBar: View {
    @Binding var selectedTab: AppScreen
    var onSelect: (AppScreen) -> Void = { _ in }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(DesignTokens.Colors.dock.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.65), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.13), radius: 16, x: 0, y: 8)

            HStack(spacing: 8) {
                navItem(.diary)
                navItem(.community)
                Color.clear.frame(width: 60)
                navItem(.health)
                navItem(.settings)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            Button {
                select(.home)
            } label: {
                Image(systemName: icon(for: .home))
                    .font(.system(size: 23, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 62, height: 62)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DesignTokens.Colors.primary, DesignTokens.Colors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .offset(y: -22)
        }
        .frame(height: 92)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private func navItem(_ screen: AppScreen) -> some View {
        let selected = selectedTab == screen

        return Button {
            select(screen)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon(for: screen))
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 38, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selected ? Color.white.opacity(0.65) : .clear)
                    )

                Text(title(for: screen))
                    .font(DesignTokens.Typography.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(selected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
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
