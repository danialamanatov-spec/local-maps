import SwiftUI

struct MapScreen: View {
    let city: City
    let onChangeCity: () -> Void
    @State private var selectedStop: Stop?
    @State private var selectedRoute: BusRoute?
    let provider: ArrivalProvider = SimulatedProvider()

    private var routes: [BusRoute] { Catalog.routes(for: city) }
    private var shownRoutes: [BusRoute] { selectedRoute.map { [$0] } ?? routes }
    private var shownStops: [Stop] { selectedRoute?.stops ?? Catalog.stops(for: city) }

    var body: some View {
        MapLibreView(city: city, routes: shownRoutes, stops: shownStops, selected: $selectedStop)
            .ignoresSafeArea()
            .overlay(alignment: .top) { topBar }
            .sheet(item: $selectedStop) { stop in
                StopSheet(stop: stop, provider: provider)
                    .presentationDetents([.height(300), .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(300)))
                    .presentationCornerRadius(24)
            }
            .animation(.spring(duration: 0.45, bounce: 0.25), value: selectedRoute)
    }

    private var topBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: onChangeCity) {
                    Label(city.name, systemImage: "mappin.and.ellipse").font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.thinMaterial, in: Capsule())
                }.foregroundStyle(.primary)
                if !routes.isEmpty {
                    chip("Все", .gray, selectedRoute == nil) { selectedRoute = nil }
                    ForEach(routes) { r in
                        chip("№\(r.id)", r.color, selectedRoute == r) { selectedRoute = (selectedRoute == r) ? nil : r }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
    }

    private func chip(_ t: String, _ c: Color, _ on: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(t).font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(on ? AnyShapeStyle(c) : AnyShapeStyle(.thinMaterial), in: Capsule())
                .foregroundStyle(on ? .white : .primary)
        }
        .sensoryFeedback(.selection, trigger: on)
    }
}

struct StopSheet: View {
    let stop: Stop
    let provider: ArrivalProvider
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(stop.name).font(.title2.bold())
            Text("Ближайший транспорт").font(.subheadline).foregroundStyle(.secondary)
            TimelineView(.periodic(from: .now, by: 10)) { ctx in
                let list = provider.arrivals(at: stop, now: ctx.date)
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(list) { a in
                            HStack(spacing: 12) {
                                Text(a.route.id).font(.headline).foregroundStyle(.white)
                                    .frame(width: 46, height: 34)
                                    .background(a.route.color, in: RoundedRectangle(cornerRadius: 10))
                                Text(a.route.title).font(.subheadline)
                                Spacer()
                                Text("\(a.minutes) мин").font(.headline.monospacedDigit())
                                    .contentTransition(.numericText(countsDown: true))
                            }
                            .padding(12)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .animation(.smooth, value: list.map(\.minutes))
            }
        }
        .padding(20)
    }
}
