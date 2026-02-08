import Foundation

// MARK: - Pet Profile
struct Pet: Codable, Identifiable {
    let id: UUID
    var name: String
    var species: String
    var breed: String
    var level: Int
    var experience: Int
    var maxExperience: Int
    var health: Double // 0.0 to 1.0
    var happiness: Double // 0.0 to 1.0
    var imageURL: String
}

// MARK: - Navigation
struct LauncherItem: Codable, Identifiable {
    let id: String
    let title: String
    let icon: String // SystemName
    let destination: AppScreen
    let hexColor: String
}

enum AppScreen: String, Codable {
    case home, diary, photos, community, health, shop, settings
}

// MARK: - Diary & Photos
struct DiaryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    var title: String
    var content: String
    var mood: String // Emoji or tag
    var imageURLs: [String]
}

struct PetPhoto: Codable, Identifiable {
    let id: UUID
    let url: String
    let caption: String
    let date: Date
    let isFavorite: Bool
}

// MARK: - Community
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let senderId: String
    let senderName: String
    let text: String
    let timestamp: Date
    let isMine: Bool
}

struct WeeklyActivityDay: Codable, Identifiable {
    let id: UUID
    let dayLabel: String
    let walkMinutes: Int
    let playMinutes: Int
    let mealsLogged: Int
    let mood: String
}

// MARK: - Settings
struct SettingsSection: Codable, Identifiable {
    let id: String
    let title: String
    var items: [SettingItem]
}

struct SettingItem: Codable, Identifiable {
    let id: String
    let title: String
    let type: SettingType
    var valueBool: Bool?
    var valueString: String?
}

enum SettingType: String, Codable {
    case toggle, link, disclosure
}
