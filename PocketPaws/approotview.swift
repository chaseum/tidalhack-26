import SwiftUI

struct AppRootView: View {
    @StateObject private var router = Router()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            LoginView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .login: LoginView()
                    case .register: RegisterView()
                    case .home: HomeLauncherView()
                    case .diary: PetDiaryView()
                    case .photos: PetPhotosView()
                    case .community: CommunityChatView()
                    case .settings: SettingsView()
                    default: HomeLauncherView()
                    }
                }
        }
        .environmentObject(router)
    }
}

struct AppRootView_Preview: PreviewProvider {
    static var previews: some View {
        AppRootView()
    }
}
