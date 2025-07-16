import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    let deliveries: [Delivery]
    let optimizedRoute: [Delivery]?
    let userLocation: CLLocationCoordinate2D?
    let singleSequence: Int?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        let route = optimizedRoute ?? deliveries
        // Geocode all deliveries first
        geocodeAllDeliveries(route) { geocoded in
            // Add user location annotation (custom)
            if let userLocation = userLocation {
                let userAnnotation = MKPointAnnotation()
                userAnnotation.coordinate = userLocation
                userAnnotation.title = "You"
                mapView.addAnnotation(userAnnotation)
            }
            // Add delivery annotations
            for (index, (delivery, coordinate)) in geocoded.enumerated() {
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                if let singleSequence = singleSequence {
                    annotation.title = "\(singleSequence)"
                } else {
                    annotation.title = "\(index + 1)"
                }
                annotation.subtitle = delivery.shortAddress ?? delivery.address
                mapView.addAnnotation(annotation)
            }
            // Draw actual route using MKDirections
            var points: [CLLocationCoordinate2D] = []
            if let userLocation = userLocation {
                points.append(userLocation)
            }
            points.append(contentsOf: geocoded.map { $0.1 })
            if points.count > 1 {
                for i in 0..<(points.count - 1) {
                    let request = MKDirections.Request()
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: points[i]))
                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: points[i+1]))
                    request.transportType = .automobile
                    let directions = MKDirections(request: request)
                    directions.calculate { response, error in
                        if let polyline = response?.routes.first?.polyline {
                            DispatchQueue.main.async {
                                mapView.addOverlay(polyline)
                                let rect = mapView.overlays.reduce(MKMapRect.null) { $0.union($1.boundingMapRect) }
                                if !rect.isNull {
                                    mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 60, left: 40, bottom: 60, right: 40), animated: true)
                                }
                            }
                        }
                    }
                }
            }
            // Highlight the first destination
            if let first = geocoded.first {
                let region = MKCoordinateRegion(center: first.1, latitudinalMeters: 800, longitudinalMeters: 800)
                mapView.setRegion(region, animated: true)
            }
        }
    }
    
    // Helper to geocode all deliveries in order
    private func geocodeAllDeliveries(_ deliveries: [Delivery], completion: @escaping ([(Delivery, CLLocationCoordinate2D)]) -> Void) {
        var results: [(Delivery, CLLocationCoordinate2D)] = []
        let group = DispatchGroup()
        for delivery in deliveries {
            group.enter()
            delivery.geocodeCoordinates { coordinate in
                if let coordinate = coordinate {
                    results.append((delivery, coordinate))
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            // Preserve original order
            let ordered = deliveries.compactMap { delivery in
                results.first(where: { $0.0.id == delivery.id })
            }
            completion(ordered)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            // Custom user location annotation
            if let title = annotation.title, title == "You" {
                let identifier = "UserLocationAnnotation"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    view?.canShowCallout = true
                } else {
                    view?.annotation = annotation
                }
                view?.glyphText = "You"
                view?.markerTintColor = .red
                return view
            }
            let identifier = "DeliveryMilestone"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
            } else {
                view?.annotation = annotation
            }
            view?.glyphText = annotation.title ?? ""
            view?.markerTintColor = .systemBlue
            return view
        }
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemGreen
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct MapScreen: View {
    let deliveries: [Delivery]
    let optimizedRoute: [Delivery]?
    let userLocation: CLLocationCoordinate2D?
    let singleSequence: Int?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                let route = optimizedRoute ?? deliveries
                MapView(
                    deliveries: deliveries,
                    optimizedRoute: optimizedRoute,
                    userLocation: userLocation,
                    singleSequence: singleSequence
                )
                .edgesIgnoringSafeArea(.all)
                
                if !route.isEmpty {
                    NavigationInfoBar(
                        current: route[0],
                        next: route.count > 1 ? route[1] : nil,
                        sequence: singleSequence ?? 1
                    )
                }
            }
            .navigationBarTitle("Route Map", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct NavigationInfoBar: View {
    let current: Delivery
    let next: Delivery?
    let sequence: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Stop #\(sequence): \(current.shortAddress ?? current.address)")
                .font(.headline)
                .padding(.top, 8)
            if let next = next {
                Text("Next: \(next.shortAddress ?? next.address)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding()
        .shadow(radius: 8)
    }
} 