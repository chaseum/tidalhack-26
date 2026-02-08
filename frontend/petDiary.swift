import SwiftUI

struct PetDiaryView: View {
    @EnvironmentObject var router: Router
    @State private var filter = "All"
    let entries = MockData.diaryEntries
    
    var filteredEntries: [DiaryEntry] {
        if filter == "All" { return entries }
        // Simple mock filtering based on content or title just for demo
        return entries.filter { $0.title.localizedCaseInsensitiveContains(filter) || $0.mood.contains(filter) }
    }
    
    var body: some View {
        ZStack {
            PetPalBackground()
            
            VStack(spacing: 0) {
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    Text("Pet Diary")
                        .font(DesignTokens.Typography.headline)
                    Spacer()
                    CircularIconButton(icon: "plus") {}
                }
                .padding()
                
                PetPalSelector(items: ["All", "☀️", "🐟", "🏥"], selection: $filter)
                    .padding(.horizontal)
                    .padding(.bottom, DesignTokens.Spacing.m)
                
                List {
                    ForEach(filteredEntries) { entry in
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                            HStack {
                                Text(entry.mood)
                                    .font(.title2)
                                Text(entry.date, style: .date)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                Spacer()
                            }
                            
                            Text(entry.title)
                                .font(DesignTokens.Typography.headline)
                            
                            Text(entry.content)
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, DesignTokens.Spacing.s)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .petPalCard()
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .animation(.spring(), value: filter)
            }
        }
        .navigationBarHidden(true)
    }
}

struct PetDiaryView_Preview: PreviewProvider {
    static var previews: some View {
        PetDiaryView().environmentObject(Router())
    }
}
