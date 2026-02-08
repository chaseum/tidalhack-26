import SwiftUI
import Combine

/// App navigation states
enum AppRoute: Hashable {
    case login
    case register
    case home
    case diary
    case photos
    case community
    case health
    case shop
    case settings
}

class Router: ObservableObject {
    @Published var path = NavigationPath()
    @Published var currentTab: AppScreen = .diary // For bottom nav
    
    func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
