import Foundation

struct MockData {
    
    static let pet = Pet(
        id: UUID(),
        name: "Pixel",
        species: "Cat",
        breed: "Calico",
        level: 12,
        experience: 450,
        maxExperience: 1000,
        health: 0.85,
        happiness: 0.95,
        imageURL: "https://api.dicebear.com/7.x/bottts/svg?seed=Pixel"
    )
    
    static let launcherItems: [LauncherItem] = [
        LauncherItem(id: "1", title: "Diary", icon: "book.fill", destination: .diary, hexColor: "#97B476"),
        LauncherItem(id: "2", title: "Gallery", icon: "photo.on.rectangle", destination: .photos, hexColor: "#B199F9"),
        LauncherItem(id: "3", title: "Assistant", icon: "bubble.left.and.bubble.right.fill", destination: .community, hexColor: "#FF99C8"),
        LauncherItem(id: "4", title: "Health", icon: "heart.text.square.fill", destination: .health, hexColor: "#FFD666"),
        LauncherItem(id: "5", title: "Shop", icon: "bag.fill", destination: .shop, hexColor: "#7FB3D5"),
        LauncherItem(id: "6", title: "Settings", icon: "gearshape.fill", destination: .settings, hexColor: "#95A5A6")
    ]
    
    static let diaryEntries: [DiaryEntry] = [
        DiaryEntry(id: UUID(), date: Date(), title: "Sunshine Nap", content: "Pixel found a perfect sunbeam today. Slept for 3 hours straight.", mood: "☀️", imageURLs: []),
        DiaryEntry(id: UUID(), date: Date().addingTimeInterval(-86400), title: "The Red Dot Returns", content: "The laser pointer made a guest appearance. Much chaos ensued.", mood: "🔴", imageURLs: []),
        DiaryEntry(id: UUID(), date: Date().addingTimeInterval(-172800), title: "New Treat Alert", content: "Tried the tuna-flavored crunchies. Immediate hit.", mood: "🐟", imageURLs: []),
        DiaryEntry(id: UUID(), date: Date().addingTimeInterval(-259200), title: "Vet Visit", content: "Not the happiest day, but she was a brave girl.", mood: "🏥", imageURLs: []),
        DiaryEntry(id: UUID(), date: Date().addingTimeInterval(-345600), title: "First Butterfly", content: "Watched a monarch from the window for ages.", mood: "🦋", imageURLs: [])
    ]
    
    static let photos: [PetPhoto] = (1...10).map { i in
        PetPhoto(
            id: UUID(),
            url: "https://picsum.photos/seed/pet\(i)/400/400",
            caption: "Pixel moment #\(i)",
            date: Date().addingTimeInterval(Double(-i * 3600)),
            isFavorite: i % 3 == 0
        )
    }
    
    static let chatMessages: [ChatMessage] = [
        ChatMessage(
            id: UUID(),
            senderId: "assistant",
            senderName: "Mogee Guide",
            text: "Hi, I can help with food, routines, symptoms to watch, and care plans. What do you want to check today?",
            timestamp: Date(),
            isMine: false
        )
    ]
    
    static let weeklyActivity: [WeeklyActivityDay] = [
        WeeklyActivityDay(id: UUID(), dayLabel: "Mon", walkMinutes: 24, playMinutes: 18, mealsLogged: 3, mood: "Happy"),
        WeeklyActivityDay(id: UUID(), dayLabel: "Tue", walkMinutes: 32, playMinutes: 25, mealsLogged: 3, mood: "Great"),
        WeeklyActivityDay(id: UUID(), dayLabel: "Wed", walkMinutes: 16, playMinutes: 20, mealsLogged: 2, mood: "Calm"),
        WeeklyActivityDay(id: UUID(), dayLabel: "Thu", walkMinutes: 29, playMinutes: 28, mealsLogged: 3, mood: "Great"),
        WeeklyActivityDay(id: UUID(), dayLabel: "Fri", walkMinutes: 22, playMinutes: 15, mealsLogged: 3, mood: "Happy"),
        WeeklyActivityDay(id: UUID(), dayLabel: "Sat", walkMinutes: 38, playMinutes: 31, mealsLogged: 3, mood: "Energetic"),
        WeeklyActivityDay(id: UUID(), dayLabel: "Sun", walkMinutes: 27, playMinutes: 22, mealsLogged: 3, mood: "Happy")
    ]
    
    static let settings: [SettingsSection] = [
        SettingsSection(id: "notifications", title: "Notifications", items: [
            SettingItem(id: "push", title: "Push Notifications", type: .toggle, valueBool: true),
            SettingItem(id: "reminders", title: "Care Reminders", type: .toggle, valueBool: true)
        ]),
        SettingsSection(id: "account", title: "Account", items: [
            SettingItem(id: "profile", title: "Edit Profile", type: .disclosure),
            SettingItem(id: "sync", title: "iCloud Sync", type: .toggle, valueBool: true)
        ]),
        SettingsSection(id: "legal", title: "Legal", items: [
            SettingItem(id: "privacy", title: "Privacy Policy", type: .link, valueString: "https://pocketpaws.app/privacy"),
            SettingItem(id: "terms", title: "Terms of Service", type: .link, valueString: "https://pocketpaws.app/terms")
        ])
    ]
}
