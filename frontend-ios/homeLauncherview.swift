import SwiftUI

struct HomeLauncherView: View {
    @EnvironmentObject var router: Router
    @State private var viewMode = "Overview"
    let pet = MockData.pet
    
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
                    
                    CircularIconButton(icon: "bell.fill") {}
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
                                    Text("\(Int(pet.health * 100))%")
                                }
                                ProgressView(value: pet.health)
                                    .accentColor(.red)
                                
                                HStack {
                                    Label("Happiness", systemImage: "face.smiling.fill").foregroundColor(.yellow)
                                    Spacer()
                                    Text("\(Int(pet.happiness * 100))%")
                                }
                                ProgressView(value: pet.happiness)
                                    .accentColor(.yellow)
                            }
                            .padding()
                            .petPalCard()
                            .padding(.horizontal)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            
                            // Main Launcher Grid
                            LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.l) {
                                ForEach(MockData.launcherItems) { item in
                                    CircularAppButton(item: item) {
                                        router.navigate(to: route(for: item.destination))
                                    }
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.l)
                        } else {
                            // Stats View Placeholder
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) {
                                Text("Weekly Activity")
                                    .font(DesignTokens.Typography.headline)
                                
                                HStack(alignment: .bottom, spacing: 12) {
                                    ForEach(0..<7) { i in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(DesignTokens.Colors.primary)
                                            .frame(width: 30, height: CGFloat.random(in: 40...140))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .petPalCard()
                            }
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
                
                BottomNavBar(selectedTab: $router.currentTab)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func route(for screen: AppScreen) -> AppRoute {
        switch screen {
        case .diary: return .diary
        case .photos: return .photos
        case .community: return .community
        case .settings: return .settings
        default: return .home
        }
    }
}

struct HomeLauncherView_Preview: PreviewProvider {
    static var previews: some View {
        HomeLauncherView().environmentObject(Router())
    }
}
