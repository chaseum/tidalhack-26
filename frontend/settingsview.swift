import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var router: Router
    let sections = MockData.settings
    
    var body: some View {
        ZStack {
            PetPalBackground()
            
            VStack {
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
                            
                            Button("Edit Profile") { }
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
                                        SettingRow(item: item)
                                        
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
                            router.popToRoot()
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
            }
        }
        .navigationBarHidden(true)
    }
}

struct SettingRow: View {
    let item: SettingItem
    @State private var toggleVal = true
    
    var body: some View {
        HStack {
            Text(item.title)
                .font(DesignTokens.Typography.body)
            Spacer()
            
            switch item.type {
            case .toggle:
                Toggle("", isOn: $toggleVal).labelsHidden()
            case .disclosure:
                Image(systemName: "chevron.right")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            case .link:
                Image(systemName: "arrow.up.right")
                    .foregroundColor(DesignTokens.Colors.primary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
}

struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(Router())
    }
}
