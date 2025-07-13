import SwiftUI
import MapKit
import Combine

class RouteCalculator {
    static let shared = RouteCalculator()
    private var queue: [(MKDirections.Request, (MKRoute?) -> Void)] = []
    private var isProcessing = false
    private let semaphore = DispatchSemaphore(value: 1)
    
    private init() {}
    
    func calculateRoute(request: MKDirections.Request, completion: @escaping (MKRoute?) -> Void) {
        queue.append((request, completion))
        processNextRoute()
    }
    private func processNextRoute() {
        semaphore.wait()
        guard !isProcessing else {
            semaphore.signal()
            return
        }
        guard !queue.isEmpty else {
            semaphore.signal()
            return
        }
        isProcessing = true
        let (request, completion) = queue.removeFirst()
        semaphore.signal()
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            completion(response?.routes.first)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Add delay between requests
                self?.semaphore.wait()
                self?.isProcessing = false
                self?.semaphore.signal()
                self?.processNextRoute()
            }
        }
    }
}

struct MapView: View {
    let locationService: LocationServiceProtocol
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.365222, longitude: 77.542049),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var isFullScreen = false
    @GestureState private var isDetectingLongPress = false
    @State private var mapView: MKMapView?
    
    var deliveries: [Delivery]
    var optimizedRoute: [Delivery]?
    var onOptimizeRoute: (() -> Void)?
    var isInFullScreenMode: Bool = false
    
    private var allAnnotations: [Delivery] {
        var annotations = deliveries
        
        // Add current location if available
        if let currentLocation = (locationService as? LocationService)?.currentLocation {
            let currentLocationDelivery = Delivery(
                id: UUID(),
                address: "Current Location",
                coordinates: currentLocation,
                status: .pending,
                customerName: "You",
                customerPhone: "",
                timestamp: Date()
            )
            annotations.append(currentLocationDelivery)
        }
        return annotations
    }
    
    var body: some View {
        ZStack {
            MapViewRepresentable(
                region: $region,
                annotations: allAnnotations,
                optimizedRoute: optimizedRoute,
                locationService: locationService,
                mapView: $mapView
            )
            .overlay {
                if !isInFullScreenMode {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                onOptimizeRoute?()
                            }) {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    .font(.title2)
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            .padding(.trailing)
                            
                            Button(action: {
                                isFullScreen = true
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.title2)
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            .padding()
                        }
                    }
                }
            }
            .gesture(
                !isInFullScreenMode ?
                TapGesture(count: 2)
                    .onEnded { _ in
                        isFullScreen = true
                    }
                : nil
            )
        }
        .sheet(isPresented: $isFullScreen) {
            FullScreenMapView(
                locationService: locationService,
                deliveries: deliveries,
                optimizedRoute: optimizedRoute,
                onOptimizeRoute: onOptimizeRoute,
                isPresented: $isFullScreen
            )
        }
        .onAppear {
            locationService.requestLocationPermission()
            locationService.startUpdatingLocation()
        }
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let annotations: [Delivery]
    let optimizedRoute: [Delivery]?
    let locationService: LocationServiceProtocol
    @Binding var mapView: MKMapView?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.region = region
        
        self.mapView = mapView
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.region = region
        // Remove existing annotations and overlays
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        // Add delivery point annotations
        let mapAnnotations = annotations.map { delivery -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = delivery.coordinates
            annotation.title = delivery.customerName
            annotation.subtitle = delivery.address
            return annotation
        }
        mapView.addAnnotations(mapAnnotations)
        // Add route overlays if available
        if let route = optimizedRoute,
           let currentLocation = (locationService as? LocationService)?.currentLocation {
            let coordinates = [currentLocation] + route.map { $0.coordinates }
            var totalRect: MKMapRect?
            
            for i in 0..<coordinates.count-1 {
                let sourcePlacemark = MKPlacemark(coordinate: coordinates[i])
                let destinationPlacemark = MKPlacemark(coordinate: coordinates[i+1])
                
                let sourceItem = MKMapItem(placemark: sourcePlacemark)
                let destinationItem = MKMapItem(placemark: destinationPlacemark)
                
                let directionRequest = MKDirections.Request()
                directionRequest.source = sourceItem
                directionRequest.destination = destinationItem
                directionRequest.transportType = .automobile
                
                RouteCalculator.shared.calculateRoute(request: directionRequest) { route in
                    DispatchQueue.main.async {
                        if let route = route {
                            mapView.addOverlay(route.polyline)
                            
                            // Update region to show all points
                            if let rect = totalRect {
                                totalRect = rect.union(route.polyline.boundingMapRect)
                            } else {
                                totalRect = route.polyline.boundingMapRect
                            }
                            
                            if i == coordinates.count - 2 {
                                if let finalRect = totalRect {
                                    let insets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
                                    mapView.setVisibleMapRect(finalRect, edgePadding: insets, animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            let identifier = "DeliveryPoint"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            if let title = annotation.title, title == "You" {
                (annotationView as? MKMarkerAnnotationView)?.markerTintColor = .blue
            } else {
                (annotationView as? MKMarkerAnnotationView)?.markerTintColor = .red
            }
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct FullScreenMapView: View {
    let locationService: LocationServiceProtocol
    let deliveries: [Delivery]
    let optimizedRoute: [Delivery]?
    let onOptimizeRoute: (() -> Void)?
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.365222, longitude: 77.542049),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var mapView: MKMapView?
    
    private var allAnnotations: [Delivery] {
        var annotations = deliveries
        
        // Add current location if available
        if let currentLocation = (locationService as? LocationService)?.currentLocation {
            let currentLocationDelivery = Delivery(
                id: UUID(),
                address: "Current Location",
                coordinates: currentLocation,
                status: .pending,
                customerName: "You",
                customerPhone: "",
                timestamp: Date()
            )
            annotations.append(currentLocationDelivery)
        }
        return annotations
    }
    
    var body: some View {
        NavigationView {
            MapViewRepresentable(
                region: $region,
                annotations: allAnnotations,
                optimizedRoute: optimizedRoute,
                locationService: locationService,
                mapView: $mapView
            )
            .navigationBarItems(
                leading: Button("Close") {
                    isPresented = false
                    dismiss()
                },
                trailing: Button("Optimize Route") {
                    onOptimizeRoute?()
                }
            )
            .ignoresSafeArea()
        }
    }
}

extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude),\(longitude)"
    }
}

#Preview {
    MapView(
        locationService: LocationService(),
        deliveries: [
            Delivery(
                id: UUID(),
                address: "Alpha 1, Greater Noida",
                coordinates: CLLocationCoordinate2D(latitude: 28.365222, longitude: 77.542049),
                status: .pending,
                customerName: "Test Customer",
                customerPhone: "555-0000",
                timestamp: Date()
            )
        ]
    )
} 
