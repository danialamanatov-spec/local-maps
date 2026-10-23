import SwiftUI
import CoreLocation

struct Stop: Identifiable, Hashable {
    let id: String, name: String, lat: Double, lon: Double
    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lon) }
    static func == (a: Stop, b: Stop) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

struct BusRoute: Identifiable, Hashable {
    let id: String, title: String
    let color: Color
    let stopIDs: [String]
    let intervalMin: Int
    var stops: [Stop] { stopIDs.compactMap { Catalog.stop($0) } }
}

struct Arrival: Identifiable { let id = UUID(); let route: BusRoute; let minutes: Int }

/// ДЕМО-данные только для Махачкалы (координаты приблизительные).
/// Замените реальными остановками/маршрутами из OpenStreetMap.
enum Catalog {
    static let stops: [Stop] = [
        Stop(id: "vokzal",  name: "Железнодорожный вокзал", lat: 42.9690, lon: 47.4890),
        Stop(id: "lenin",   name: "Площадь Ленина",         lat: 42.9826, lon: 47.5040),
        Stop(id: "dgu",     name: "ДГУ",                    lat: 42.9560, lon: 47.5120),
        Stop(id: "anzhi",   name: "Анжи-Арена",             lat: 42.9590, lon: 47.4990),
        Stop(id: "rynok",   name: "Центральный рынок",      lat: 42.9780, lon: 47.5000),
    ]
    static let routes: [BusRoute] = [
        BusRoute(id: "1", title: "Вокзал — ДГУ",       color: .blue,   stopIDs: ["vokzal","rynok","lenin","dgu"], intervalMin: 8),
        BusRoute(id: "5", title: "Анжи-Арена — Центр", color: .orange, stopIDs: ["anzhi","vokzal","lenin"],       intervalMin: 12),
    ]
    static func stop(_ id: String) -> Stop? { stops.first { $0.id == id } }
    static func routes(for c: City) -> [BusRoute] { c.id == "makhachkala" ? routes : [] }
    static func stops(for c: City) -> [Stop] { c.id == "makhachkala" ? stops : [] }
    static func routes(at s: Stop) -> [BusRoute] { routes.filter { $0.stopIDs.contains(s.id) } }
}

protocol ArrivalProvider { func arrivals(at stop: Stop, now: Date) -> [Arrival] }

/// Симуляция. Заменить на реальный источник (GTFS-RT / API перевозчика).
struct SimulatedProvider: ArrivalProvider {
    func arrivals(at stop: Stop, now: Date) -> [Arrival] {
        let t = now.timeIntervalSince1970 / 60
        return Catalog.routes(at: stop).map { r in
            let off = Double(abs(stop.id.hashValue ^ r.id.hashValue) % 8)
            let p = Double(r.intervalMin)
            return Arrival(route: r, minutes: max(1, Int((p - (t + off).truncatingRemainder(dividingBy: p)).rounded(.up))))
        }.sorted { $0.minutes < $1.minutes }
    }
}
