import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var router: Router
    let sections = MockData.settings
    @State private var activeNotice: String?
    
    var body: some View {
        ZStack {
            PetPalBackground()
            
            VStack(spacing: 0) {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left").foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    Text("Settings").font(DesignTokens.Typography.headline)
                    Spacer()
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.l) {
                        // Profile Card
                        VStack(spacing: DesignTokens.Spacing.m) {
                            PetAvatarBadgeView(pet: MockData.pet, size: 80)
                            Text("Pixel's Parent")
                                .font(DesignTokens.Typography.headline)
                            Text("parent@example.com")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            Button("Edit Profile") {
                                activeNotice = "Profile editing is coming soon."
                            }
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .petPalCard()
                        .padding(.horizontal)
                        
                        // Settings Groups
                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                                Text(section.title)
                                    .font(DesignTokens.Typography.headline)
                                    .padding(.leading, 4)
                                
                                VStack(spacing: 0) {
                                    ForEach(section.items.indices, id: \.self) { idx in
                                        let item = section.items[idx]
                                        SettingRow(item: item) { tappedItem in
                                            handleTap(for: tappedItem)
                                        }
                                        
                                        if idx < section.items.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                                .petPalCard(radius: DesignTokens.Radius.m, shadow: false)
                            }
                            .padding(.horizontal)
                        }
                        
                        Button {
                            router.logout()
                        } label: {
                            Text("Logout")
                                .foregroundColor(DesignTokens.Colors.accentDestructive)
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(DesignTokens.Colors.accentDestructive.opacity(0.1))
                                .cornerRadius(DesignTokens.Radius.m)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
                
                BottomNavBar(selectedTab: $router.currentTab) { screen in
                    router.switchTab(to: screen)
                }
            }
        }
        .alert("Settings", isPresented: Binding(
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
    
    private func handleTap(for item: SettingItem) {
        switch item.type {
        case .toggle:
            return
        case .disclosure:
            activeNotice = "\(item.title) screen is coming soon."
        case .link:
            guard let value = item.valueString, let url = URL(string: value) else {
                activeNotice = "Unable to open this link."
                return
            }
            openURL(url)
        }
    }
}

struct SettingRow: View {
    let item: SettingItem
    let onTap: (SettingItem) -> Void
    @State private var toggleVal: Bool
    
    init(item: SettingItem, onTap: @escaping (SettingItem) -> Void) {
        self.item = item
        self.onTap = onTap
        _toggleVal = State(initialValue: item.valueBool ?? true)
    }
    
    var body: some View {
        switch item.type {
        case .toggle:
            HStack {
                Text(item.title)
                    .font(DesignTokens.Typography.body)
                Spacer()
                Toggle("", isOn: $toggleVal)
                    .labelsHidden()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
        case .disclosure, .link:
            Button {
                onTap(item)
            } label: {
                HStack {
                    Text(item.title)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    Spacer()
                    Image(systemName: item.type == .disclosure ? "chevron.right" : "arrow.up.right")
                        .foregroundColor(item.type == .disclosure ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.primary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(Router())
    }
}
