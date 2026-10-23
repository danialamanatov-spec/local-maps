import SwiftUI

@main
struct MapsApp: App {
    var body: some Scene { WindowGroup { RootView() } }
}

final class AppState: ObservableObject {
    @Published var city: City?
    init() {
        if let id = UserDefaults.standard.string(forKey: "city"),
           let c = City.all.first(where: { $0.id == id }), LocalMaps.exists(c) { city = c }
    }
    func choose(_ c: City?) {
        city = c
        UserDefaults.standard.set(c?.id, forKey: "city") // только на устройстве
    }
}

struct RootView: View {
    @StateObject private var app = AppState()
    var body: some View {
        ZStack {
            if let c = app.city {
                MapScreen(city: c) { app.choose(nil) }.transition(.opacity)
            } else {
                CityPicker(app: app).transition(.move(edge: .bottom))
            }
        }
        .animation(.smooth(duration: 0.5), value: app.city?.id)
    }
}
