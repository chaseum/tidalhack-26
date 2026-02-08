import SwiftUI

struct HomeLauncherView: View {
    @EnvironmentObject var router: Router
    @State private var viewMode = "Overview"
    @State private var activeNotice: String?
    let pet = MockData.pet
    let weeklyActivity = MockData.weeklyActivity
    
    let columns = [
        GridItem(.flexible(), spacing: DesignTokens.Spacing.l),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.l)
    ]
    
    var body: some View {
        ZStack {
            PetPalBackground()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack(spacing: DesignTokens.Spacing.m) {
                    PetAvatarBadgeView(pet: pet, size: 56)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pet.name)
                            .font(DesignTokens.Typography.headline)
                        Text(pet.breed)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    CircularIconButton(icon: "bell.fill") {
                        activeNotice = "No new alerts right now."
                    }
                }
                .padding()
                
                PetPalSelector(items: ["Overview", "Stats"], selection: $viewMode)
                    .padding(.horizontal)
                    .padding(.bottom, DesignTokens.Spacing.m)
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        if viewMode == "Overview" {
                            // Health/Happiness Bar
                            VStack(spacing: DesignTokens.Spacing.s) {
                                HStack {
                                    Label("Health", systemImage: "heart.fill").foregroundColor(.red)
                                    Spacer()
                                    Text(statusText(for: pet.health))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                ProgressView(value: pet.health)
                                    .tint(.red)
                                
                                HStack {
                                    Label("Happiness", systemImage: "face.smiling.fill").foregroundColor(.yellow)
                                    Spacer()
                                    Text(statusText(for: pet.happiness))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                ProgressView(value: pet.happiness)
                                    .tint(.yellow)
                            }
                            .padding()
                            .petPalCard()
                            .padding(.horizontal)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            
                            // Main Launcher Grid
                            LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.l) {
                                ForEach(MockData.launcherItems) { item in
                                    CircularAppButton(item: item) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                            router.open(screen: item.destination)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.l)
                        } else {
                            // Weekly Stats
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) {
                                Text("Weekly Activity")
                                    .font(DesignTokens.Typography.headline)
                                
                                HStack(alignment: .bottom, spacing: 12) {
                                    ForEach(weeklyActivity) { day in
                                        VStack(spacing: 6) {
                                            RoundedRectangle(cornerRadius: 4)
                                            .fill(DesignTokens.Colors.primary)
                                                .frame(width: 22, height: max(CGFloat(day.walkMinutes) * 2.2, 24))
                                            Text(day.dayLabel)
                                                .font(DesignTokens.Typography.caption)
                                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack(spacing: 10) {
                                    statRow(title: "Walk Time", value: "\(weeklyActivity.map(\.walkMinutes).reduce(0, +)) min this week")
                                    statRow(title: "Play Time", value: "\(weeklyActivity.map(\.playMinutes).reduce(0, +)) min this week")
                                    statRow(title: "Meal Logs", value: "\(weeklyActivity.map(\.mealsLogged).reduce(0, +)) meals tracked")
                                    statRow(title: "Most Common Mood", value: mostCommonMood())
                                }
                            }
                            .padding()
                            .petPalCard()
                            .padding(.horizontal)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                        
                        // Promotion / Tip Card
                        HStack(spacing: DesignTokens.Spacing.m) {
                            Image(systemName: "sparkles")
                                .font(.title)
                                .foregroundColor(DesignTokens.Colors.secondary)
                            VStack(alignment: .leading) {
                                Text("Pro Tip")
                                    .font(DesignTokens.Typography.headline)
                                Text("Take a daily photo to keep the mood high!")
                                    .font(DesignTokens.Typography.body)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                        }
                        .padding()
                        .petPalCard(radius: DesignTokens.Radius.l)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewMode)
                }
                
                BottomNavBar(selectedTab: $router.currentTab) { screen in
                    router.switchTab(to: screen)
                }
            }
        }
        .onAppear {
            router.currentTab = .home
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
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
    }
}

struct HomeLauncherView_Preview: PreviewProvider {
    static var previews: some View {
        HomeLauncherView().environmentObject(Router())
    }
}

struct HealthStatusView: View {
    @EnvironmentObject var router: Router
    let pet = MockData.pet
    
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
                        .petPalCard()
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                            Text("Advice")
                                .font(DesignTokens.Typography.headline)
                            Text("Keep Pixel hydrated and add one outdoor play session to boost mood.")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .petPalCard()
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
