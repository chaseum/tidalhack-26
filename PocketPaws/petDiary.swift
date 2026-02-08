import SwiftUI

struct PetDiaryView: View {
    @EnvironmentObject var router: Router
    @State private var filter = "All"
    @State private var entries = MockData.diaryEntries
    @State private var showingAddEntry = false
    @State private var newEntryTitle = ""
    @State private var newEntryContent = ""
    @State private var newEntryMood = "☀️"
    
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
                    Text(todayLabel)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    CircularIconButton(icon: "plus") {
                        showingAddEntry = true
                    }
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
                
                BottomNavBar(selectedTab: $router.currentTab) { screen in
                    router.switchTab(to: screen)
                }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            NavigationStack {
                Form {
                    Section("Entry") {
                        TextField("Title", text: $newEntryTitle)
                        TextField("Mood (emoji)", text: $newEntryMood)
                        TextField("What happened?", text: $newEntryContent, axis: .vertical)
                            .lineLimit(4...8)
                    }
                }
                .navigationTitle("New Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            resetDraftEntry()
                            showingAddEntry = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let entry = DiaryEntry(
                                id: UUID(),
                                date: Date(),
                                title: newEntryTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                                content: newEntryContent.trimmingCharacters(in: .whitespacesAndNewlines),
                                mood: newEntryMood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "☀️" : newEntryMood.trimmingCharacters(in: .whitespacesAndNewlines),
                                imageURLs: []
                            )
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                entries.insert(entry, at: 0)
                            }
                            resetDraftEntry()
                            showingAddEntry = false
                        }
                        .disabled(newEntryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newEntryContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .navigationBarHidden(true)
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: Date()).uppercased()
    }
    
    private func resetDraftEntry() {
        newEntryTitle = ""
        newEntryContent = ""
        newEntryMood = "☀️"
    }
}

struct PetDiaryView_Preview: PreviewProvider {
    static var previews: some View {
        PetDiaryView().environmentObject(Router())
    }
}
