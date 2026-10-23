import SwiftUI
import MapLibre

final class RouteLine: MLNPolyline { var color: UIColor = .systemBlue }
final class StopAnnotation: MLNPointAnnotation { var stop: Stop! }

final class StopView: MLNAnnotationView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 26, height: 26)
        backgroundColor = .systemIndigo
        layer.cornerRadius = 13; layer.borderWidth = 2; layer.borderColor = UIColor.white.cgColor
        let iv = UIImageView(image: UIImage(systemName: "bus.fill"))
        iv.tintColor = .white; iv.contentMode = .scaleAspectFit
        iv.frame = bounds.insetBy(dx: 6, dy: 6); addSubview(iv)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0) {
            self.transform = selected ? CGAffineTransform(scaleX: 1.35, y: 1.35) : .identity
        }
    }
}

/// Стиль строится локально: тайлы из скачанного .pmtiles, шрифты из приложения. Сети нет.
enum StyleBuilder {
    static func write(for city: City) -> URL {
        let pack = "pmtiles://" + LocalMaps.url(city).absoluteString
        let fonts = Bundle.main.bundleURL.appendingPathComponent("Resources/fonts").absoluteString
        let label = #"{"text-font":["Noto Sans Regular"],"text-size":12}"#
        _ = label
        let json = """
        {"version":8,"glyphs":"\(fonts)/{fontstack}/{range}.pbf",
        "sources":{"p":{"type":"vector","url":"\(pack)","attribution":"© OpenStreetMap"}},
        "layers":[
        {"id":"bg","type":"background","paint":{"background-color":"#f2efe9"}},
        {"id":"landuse","type":"fill","source":"p","source-layer":"landuse","paint":{"fill-color":"#d3e6c0","fill-opacity":0.7}},
        {"id":"water","type":"fill","source":"p","source-layer":"water","paint":{"fill-color":"#a8d4f0"}},
        {"id":"bld","type":"fill","source":"p","source-layer":"buildings","minzoom":14,"paint":{"fill-color":"#e1ddd4"}},
        {"id":"r1","type":"line","source":"p","source-layer":"roads","filter":["in","kind","minor_road","other"],"layout":{"line-cap":"round"},"paint":{"line-color":"#ffffff","line-width":["interpolate",["linear"],["zoom"],12,0.6,18,9]}},
        {"id":"r2","type":"line","source":"p","source-layer":"roads","filter":["in","kind","major_road","medium_road"],"layout":{"line-cap":"round"},"paint":{"line-color":"#ffe08a","line-width":["interpolate",["linear"],["zoom"],10,1,18,16]}},
        {"id":"r3","type":"line","source":"p","source-layer":"roads","filter":["==","kind","highway"],"paint":{"line-color":"#f7b955","line-width":["interpolate",["linear"],["zoom"],8,1,18,20]}},
        {"id":"rl","type":"symbol","source":"p","source-layer":"roads","minzoom":14,"layout":{"symbol-placement":"line","text-field":["get","name"],"text-font":["Noto Sans Regular"],"text-size":11},"paint":{"text-color":"#555555","text-halo-color":"#ffffff","text-halo-width":1.5}},
        {"id":"pl","type":"symbol","source":"p","source-layer":"places","filter":["==","kind","locality"],"layout":{"text-field":["get","name"],"text-font":["Noto Sans Regular"],"text-size":["interpolate",["linear"],["zoom"],8,12,14,17]},"paint":{"text-color":"#333333","text-halo-color":"#ffffff","text-halo-width":1.5}}
        ]}
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("style-\(city.id).json")
        try? json.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

struct MapLibreView: UIViewRepresentable {
    let city: City
    let routes: [BusRoute]
    let stops: [Stop]
    @Binding var selected: Stop?

    func makeCoordinator() -> Coord { Coord(self) }

    func makeUIView(context: Context) -> MLNMapView {
        let v = MLNMapView(frame: .zero, styleURL: StyleBuilder.write(for: city))
        v.delegate = context.coordinator
        v.setCenter(city.center, zoomLevel: city.zoom, animated: false)
        v.showsUserLocation = true
        v.automaticallyAdjustsContentInset = false
        return v
    }

    func updateUIView(_ v: MLNMapView, context: Context) {
        context.coordinator.parent = self
        let key = routes.map(\.id).joined(separator: ",") + "|" + stops.map(\.id).joined(separator: ",")
        if key != context.coordinator.key {
            context.coordinator.key = key
            if let old = v.annotations { v.removeAnnotations(old) }
            for r in routes {
                var cs = r.stops.map(\.coordinate)
                let line = RouteLine(coordinates: &cs, count: UInt(cs.count))
                line.color = UIColor(r.color)
                v.addAnnotation(line)
            }
            for s in stops {
                let a = StopAnnotation(); a.coordinate = s.coordinate; a.title = s.name; a.stop = s
                v.addAnnotation(a)
            }
        }
        if selected == nil { v.selectedAnnotations.forEach { v.deselectAnnotation($0, animated: true) } }
    }

    final class Coord: NSObject, MLNMapViewDelegate {
        var parent: MapLibreView
        var key = ""
        init(_ p: MapLibreView) { parent = p }

        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            guard annotation is StopAnnotation else { return nil }
            return mapView.dequeueReusableAnnotationView(withIdentifier: "stop") ?? StopView(reuseIdentifier: "stop")
        }
        func mapView(_ mapView: MLNMapView, didSelect annotation: MLNAnnotation) {
            guard let a = annotation as? StopAnnotation else { return }
            mapView.setCenter(a.coordinate, zoomLevel: max(mapView.zoomLevel, 15), animated: true)
            parent.selected = a.stop
        }
        func mapView(_ mapView: MLNMapView, annotationCanShowCalloutFor annotation: MLNAnnotation) -> Bool { false }
        func mapView(_ mapView: MLNMapView, strokeColorForShapeAnnotation annotation: MLNShape) -> UIColor {
            (annotation as? RouteLine)?.color ?? .systemBlue
        }
        func mapView(_ mapView: MLNMapView, lineWidthForPolylineAnnotation annotation: MLNPolyline) -> CGFloat { 5 }
    }
}
