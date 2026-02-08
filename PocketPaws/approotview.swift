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
                let transition = AnyTransition.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
                
                switch route {
                case .login: LoginView().transition(transition)
                case .register: RegisterView().transition(transition)
                case .home: HomeLauncherView().transition(transition)
                case .diary: PetDiaryView().transition(transition)
                case .photos: PetPhotosView().transition(transition)
                case .community: CommunityChatView().transition(transition)
                case .health: HealthStatusView().transition(transition)
                case .shop: ShopView().transition(transition)
                case .settings: SettingsView().transition(transition)
                }
            }
        }
        .animation(.default, value: router.path)
        .preferredColorScheme(.light)
        .environmentObject(router)
    }
}

struct AppRootView_Preview: PreviewProvider {
    static var previews: some View {
        AppRootView()
    }
}
