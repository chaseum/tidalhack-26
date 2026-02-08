import SwiftUI

struct HomeLauncherView: View {
    @EnvironmentObject var router: Router
    @State private var viewMode = "Overview"
    @State private var activeNotice: String?

    @State private var showPetSpotlight = false
    @State private var showLauncher = false
    @State private var showProTip = false

    let weeklyActivity = MockData.weeklyActivity

    let columns = [
        GridItem(.flexible(), spacing: DesignTokens.Spacing.m),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.m),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.m)
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PetPalBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignTokens.Spacing.l) {
                        petSpotlight

                        PetPalSelector(items: ["Overview", "Stats"], selection: $viewMode)

                        if viewMode == "Overview" {
                            launcherGrid
                            proTipCard
                        } else {
                            statsCard
                            moodCard
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.l)
                    .padding(.top, DesignTokens.Spacing.s)
                    .padding(.bottom, 128)
                    .animation(.spring(response: 0.38, dampingFraction: 0.84), value: viewMode)
                }

                BottomNavBar(selectedTab: $router.currentTab) { screen in
                    router.switchTab(to: screen)
                }
            }

            if viewMode == "Overview" {
                PrimaryCircleButton(icon: "plus") {
                    activeNotice = "Quick add is coming soon."
                }
                .padding(.trailing, 26)
                .padding(.bottom, 118)
            }
        }
        .onAppear {
            router.currentTab = .home
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showPetSpotlight = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showLauncher = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showProTip = true
                }
            }
        }
        .alert("PocketPaws", isPresented: Binding(
            get: { activeNotice != nil },
            set: { show in
                if !show { activeNotice = nil }
            }
        )) {
            Button("OK", role: .cancel) { activeNotice = nil }
        } message: {
            Text(activeNotice ?? "")
        }
        .navigationBarHidden(true)
    }

    private var pet: Pet {
        var current = MockData.pet
        current.name = router.petName
        return current
    }

    private var header: some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            PetAvatarBadgeView(pet: pet, size: 58)

            VStack(alignment: .leading, spacing: 2) {
                Text(pet.name)
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                Text(pet.breed)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Spacer()

            CircularIconButton(icon: "bell.fill") {
                activeNotice = "No new alerts right now."
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.l)
        .padding(.top, 10)
        .padding(.bottom, DesignTokens.Spacing.s)
    }

    private var petSpotlight: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
            HStack(spacing: DesignTokens.Spacing.m) {
                PetAvatarBadgeView(pet: pet, size: 84)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(pet.level)")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Text("LVL")
                            .font(DesignTokens.Typography.pixel)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }

                    Text("MA \(pet.name.uppercased())")
                        .font(DesignTokens.Typography.pixel)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Text("\(pet.experience) / \(pet.maxExperience) XP")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }

                Spacer(minLength: 0)
            }

            ProgressView(value: Double(pet.experience), total: Double(pet.maxExperience))
                .tint(DesignTokens.Colors.primary)
        }
        .padding(DesignTokens.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(DesignTokens.Colors.cardMint)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
        .opacity(showPetSpotlight ? 1 : 0)
        .offset(y: showPetSpotlight ? 0 : 20)
    }

    private var launcherGrid: some View {
        LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.l) {
            ForEach(MockData.launcherItems) { item in
                CircularAppButton(item: item) {
                    router.open(screen: item.destination)
                }
            }
        }
        .opacity(showLauncher ? 1 : 0)
        .offset(y: showLauncher ? 0 : 20)
    }

    private var proTipCard: some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DesignTokens.Colors.cardPeach)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text("Pro Tip")
                    .font(DesignTokens.Typography.headline)
                TypewriterView(text: "Add one photo a day and your pet mood stays maxed.")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .petPalCard(radius: DesignTokens.Radius.l, shadow: true)
        .opacity(showProTip ? 1 : 0)
        .offset(y: showProTip ? 0 : 20)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) {
            Text("Weekly Activity")
                .font(DesignTokens.Typography.headline)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(weeklyActivity) { day in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(DesignTokens.Colors.primary)
                            .frame(width: 24, height: max(CGFloat(day.walkMinutes) * 2.2, 24))
                        Text(day.dayLabel)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 10) {
                statRow(title: "Walk Time", value: "\(weeklyActivity.map(\.walkMinutes).reduce(0, +)) min")
                statRow(title: "Play Time", value: "\(weeklyActivity.map(\.playMinutes).reduce(0, +)) min")
                statRow(title: "Meals Logged", value: "\(weeklyActivity.map(\.mealsLogged).reduce(0, +))")
                statRow(title: "Mood", value: mostCommonMood())
            }
        }
        .petPalCard(radius: DesignTokens.Radius.l, shadow: true)
    }

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Text("Status")
                .font(DesignTokens.Typography.headline)

            HStack {
                Label("Health", systemImage: "heart.fill")
                    .foregroundColor(.red)
                Spacer()
                Text(statusText(for: pet.health))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            ProgressView(value: pet.health)
                .tint(.red)
                .scaleEffect(x: 1, y: 8, anchor: .center)

            HStack {
                Label("Happiness", systemImage: "face.smiling.fill")
                    .foregroundColor(.yellow)
                Spacer()
                Text(statusText(for: pet.happiness))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            ProgressView(value: pet.happiness)
                .tint(.yellow)
                .scaleEffect(x: 1, y: 8, anchor: .center)
        }
        .petPalCard(radius: DesignTokens.Radius.l)
    }

    private func statusText(for value: Double) -> String {
        switch value {
        case ..<0.35: return "Low"
        case ..<0.65: return "Okay"
        case ..<0.85: return "Good"
        default: return "Great"
        }
    }

    private func mostCommonMood() -> String {
        let counts = weeklyActivity.reduce(into: [String: Int]()) { partial, day in
            partial[day.mood, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? "Steady"
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(DesignTokens.Typography.pixelBody)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignTokens.Typography.pixelBody)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
    }
}



struct TypewriterView: View {
    let text: String
    @State private var displayedText = ""
    @State private var timer: Timer?

    var body: some View {
        Text(displayedText)
            .onAppear(perform: startAnimation)
            .onDisappear(perform: stopAnimation)
    }

    private func startAnimation() {
        var charIndex = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if charIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: charIndex)
                displayedText.append(text[index])
                charIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

struct HomeLauncherView_Preview: PreviewProvider
 {
    static var previews: some View {
        HomeLauncherView().environmentObject(Router())
    }
}

struct HealthStatusView: View {
    @EnvironmentObject var router: Router

    var body: some View {
        ZStack {
            PetPalBackground()

            VStack(spacing: 0) {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    Text("Health")
                        .font(DesignTokens.Typography.headline)
                    Spacer()
                }
                .padding()

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.l) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
                            Text("Today's Status")
                                .font(DesignTokens.Typography.headline)
                            HStack {
                                Label("Energy", systemImage: "bolt.fill")
                                Spacer()
                                Text(statusText(for: pet.happiness))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                            ProgressView(value: pet.happiness)
                                .tint(DesignTokens.Colors.secondary)

                            HStack {
                                Label("Wellness", systemImage: "heart.fill")
                                Spacer()
                                Text(statusText(for: pet.health))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                            ProgressView(value: pet.health)
                                .tint(DesignTokens.Colors.primary)
                        }
                        .petPalCard(shadow: true)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                            Text("Advice")
                                .font(DesignTokens.Typography.headline)
                            Text("Keep \(pet.name) hydrated and add one outdoor play session to boost mood.")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .petPalCard(shadow: true)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }

                BottomNavBar(selectedTab: $router.currentTab) { screen in
                    router.switchTab(to: screen)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func statusText(for value: Double) -> String {
        switch value {
        case ..<0.35: return "Needs Care"
        case ..<0.65: return "Stable"
        case ..<0.85: return "Good"
        default: return "Excellent"
        }
    }

    private var pet: Pet {
        var current = MockData.pet
        current.name = router.petName
        return current
    }
}

struct ShopView: View {
    @EnvironmentObject var router: Router
    @State private var activeNotice: String?

    var body: some View {
        ZStack {
            PetPalBackground()

            VStack(spacing: 0) {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    Text("Shop")
                        .font(DesignTokens.Typography.headline)
                    Spacer()
                }
                .padding()

                VStack(spacing: DesignTokens.Spacing.m) {
                    Text("Item store is loading soon.")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    PrimaryCircleButton(icon: "bag.fill") {
                        activeNotice = "Shop checkout is not connected yet."
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, DesignTokens.Spacing.xl)

                BottomNavBar(selectedTab: $router.currentTab) { screen in
                    router.switchTab(to: screen)
                }
            }
        }
        .alert("Shop", isPresented: Binding(
            get: { activeNotice != nil },
            set: { show in
                if !show { activeNotice = nil }
            }
        )) {
            Button("OK", role: .cancel) { activeNotice = nil }
        } message: {
            Text(activeNotice ?? "")
        }
        .navigationBarHidden(true)
    }
}
