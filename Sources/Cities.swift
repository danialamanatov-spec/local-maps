import Foundation
import CoreLocation

enum Cities {
    /// ЗАМЕНИТЕ на адрес, где лежат файлы <id>.pmtiles (только https).
    static let baseURL = "https://github.com/danialamanatov-spec/local-maps/releases/download/packs/"
}

struct City: Identifiable, Hashable {
    let id: String, name: String, region: String
    let lat: Double, lon: Double, zoom: Double
    var center: CLLocationCoordinate2D { .init(latitude: lat, longitude: lon) }
    var url: URL { URL(string: Cities.baseURL + id + ".pmtiles")! }

    // id и bbox должны совпадать со списком в .github/workflows/packs.yml
    static let all: [City] = [
        City(id: "makhachkala", name: "Махачкала",  region: "Дагестан", lat: 42.9849, lon: 47.5047, zoom: 12),
        City(id: "kaspiysk",    name: "Каспийск",   region: "Дагестан", lat: 42.8816, lon: 47.6392, zoom: 13),
        City(id: "derbent",     name: "Дербент",    region: "Дагестан", lat: 42.0678, lon: 48.2899, zoom: 13),
        City(id: "khasavyurt",  name: "Хасавюрт",   region: "Дагестан", lat: 43.2500, lon: 46.5877, zoom: 13),
        City(id: "buynaksk",    name: "Буйнакск",   region: "Дагестан", lat: 42.8208, lon: 47.1159, zoom: 13),
    ]
}

enum LocalMaps {
    static var dir: URL {
        let d = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("maps")
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    static func url(_ c: City) -> URL { dir.appendingPathComponent("\(c.id).pmtiles") }
    static func exists(_ c: City) -> Bool { FileManager.default.fileExists(atPath: url(c).path) }
}
