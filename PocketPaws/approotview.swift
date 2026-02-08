import SwiftUI

struct AppRootView: View {
    @StateObject private var router = Router()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            Group {
                if router.isAuthenticated {
                    HomeLauncherView()
                } else {
                    LoginView()
                }
            }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .login: LoginView()
                    case .register: RegisterView()
                    case .home: HomeLauncherView()
                    case .diary: PetDiaryView()
                    case .photos: PetPhotosView()
                    case .community: CommunityChatView()
                    case .health: HealthStatusView()
                    case .shop: ShopView()
                    case .settings: SettingsView()
                    }
                }
        }
        .preferredColorScheme(.light)
        .environmentObject(router)
    }
}

struct AppRootView_Preview: PreviewProvider {
    static var previews: some View {
        AppRootView()
    }
}
