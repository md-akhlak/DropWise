import Foundation
import CoreLocation
import Combine
import MapKit

class DashboardViewModel: ObservableObject {
    @Published var deliveries: [Delivery] = []
    @Published var selectedDelivery: Delivery?
    @Published var optimizedRoute: [Delivery]?
    @Published var routeCoordinates: [[CLLocationCoordinate2D]]?
    @Published var isOptimizing: Bool = false
    
    let locationService: LocationServiceProtocol
    private let routeOptimizationService: RouteOptimizationServiceProtocol
    
    init(locationService: LocationServiceProtocol, routeOptimizationService: RouteOptimizationServiceProtocol = RouteOptimizationService()) {
        self.locationService = locationService
        self.routeOptimizationService = routeOptimizationService
        loadDummyData()
    }
    
    private func loadDummyData() {
        // Base location: Sector 62 Noida (Tech Hub)
        let baseLocation = CLLocationCoordinate2D(latitude: 28.5728, longitude: 77.3639)
        
        // Delivery locations within 10km radius in different directions
        var unsortedDeliveries = [
            // North (Sector 62 - Base)
            Delivery(id: UUID(),
                    address: "Sector 62 Metro, Noida",
                    coordinates: CLLocationCoordinate2D(latitude: 28.6287, longitude: 77.3639),
                    status: .pending,
                    customerName: "Rahul Kumar",
                    customerPhone: "555-0123",
                    deliveryInstructions: "Near NSEZ Metro Station",
                    timestamp: Date(),
                    viewModel: self),
            
            // North East (Sector 121)
            Delivery(id: UUID(),
                    address: "Sector 121, Noida",
                    coordinates: CLLocationCoordinate2D(latitude: 28.6372, longitude: 77.3912),
                    status: .pending,
                    customerName: "Priya Singh",
                    customerPhone: "555-0124",
                    deliveryInstructions: "Homes 121 Society",
                    timestamp: Date(),
                    viewModel: self),
            
            // East (Sector 168)
            Delivery(id: UUID(),
                    address: "Sector 168, Noida",
                    coordinates: CLLocationCoordinate2D(latitude: 28.6266, longitude: 77.4149),
                    status: .pending,
                    customerName: "Amit Sharma",
                    customerPhone: "555-0125",
                    deliveryInstructions: "Near Noida Expressway",
                    timestamp: Date(),
                    viewModel: self),
            
            // South East (Sector 144)
            Delivery(id: UUID(),
                    address: "Sector 144, Noida",
                    coordinates: CLLocationCoordinate2D(latitude: 28.5866, longitude: 77.4049),
                    status: .pending,
                    customerName: "Neha Verma",
                    customerPhone: "555-0126",
                    deliveryInstructions: "Oxygen Business Park",
                    timestamp: Date(),
                    viewModel: self),
            
            // South (Sector 50)
            Delivery(id: UUID(),
                    address: "Sector 50, Noida",
                    coordinates: CLLocationCoordinate2D(latitude: 28.5728, longitude: 77.3639),
                    status: .pending,
                    customerName: "Vikram Malhotra",
                    customerPhone: "555-0127",
                    deliveryInstructions: "Near Hong Kong Market",
                    timestamp: Date(),
                    viewModel: self),
            
            // South West (Sector 44)
            Delivery(id: UUID(),
                    address: "Sector 44, Noida",
                    coordinates: CLLocationCoordinate2D(latitude: 28.5666, longitude: 77.3449),
                    status: .pending,
                    customerName: "Anjali Gupta",
                    customerPhone: "555-0128",
                    deliveryInstructions: "Near Pathways School",
                    timestamp: Date(),
                    viewModel: self),
            
            // West (Sector 18)
            Delivery(id: UUID(),
                    address: "Sector 18, Noida",
                    coordinates: CLLocationCoordinate2D(latitude: 28.6266, longitude: 77.3149),
                    status: .pending,
                    customerName: "Rajesh Khanna",
                    customerPhone: "555-0129",
                    deliveryInstructions: "DLF Mall of India",
                    timestamp: Date(),
                    viewModel: self),
            
            // North West (Sector 15)
            Delivery(id: UUID(),
                    address: "Sector 15, Noida",
                    coordinates: CLLocationCoordinate2D(latitude: 28.6466, longitude: 77.3249),
                    status: .pending,
                    customerName: "Meera Patel",
                    customerPhone: "555-0130",
                    deliveryInstructions: "Near Metro Hospital",
                    timestamp: Date(),
                    viewModel: self),
            
            // North North East (Sector 122)
            Delivery(id: UUID(),
                    address: "Sector 122, Noida",
                    coordinates: CLLocationCoordinate2D(latitude: 28.6466, longitude: 77.3849),
                    status: .pending,
                    customerName: "Sanjay Kapoor",
                    customerPhone: "555-0131",
                    deliveryInstructions: "Near Eldeco Business Park",
                    timestamp: Date(),
                    viewModel: self),
            
            // South South West (Sector 41)
            Delivery(id: UUID(),
                    address: "Sector 41, Noida",
                    coordinates: CLLocationCoordinate2D(latitude: 28.5566, longitude: 77.3349),
                    status: .pending,
                    customerName: "Pooja Sharma",
                    customerPhone: "555-0132",
                    deliveryInstructions: "Near City Center Metro",
                    timestamp: Date(),
                    viewModel: self)
        ]
        
        // Update short addresses for all deliveries
        let group = DispatchGroup()
        
        for i in 0..<unsortedDeliveries.count {
            group.enter()
            AddressLookupService.getShortAddress(for: unsortedDeliveries[i].coordinates) { shortAddress in
                if let shortAddress = shortAddress {
                    unsortedDeliveries[i].shortAddress = shortAddress
                }
                group.leave()
            }
        }
        
        // Sort and update deliveries after getting short addresses
        group.notify(queue: .main) {
            self.deliveries = unsortedDeliveries.sorted { $0.distanceFromBase < $1.distanceFromBase }
        }
    }
    
    func selectDelivery(_ delivery: Delivery) {
        selectedDelivery = delivery
    }
    
    func optimizeRoute() {
        isOptimizing = true
        routeCoordinates = nil
        
        // Get current location from location service
        guard let currentLocation = (locationService as? LocationService)?.currentLocation else {
            print("Current location not available")
            isOptimizing = false
            return
        }
        
        // Optimize route starting from current location
        routeOptimizationService.optimizeRoute(
            deliveries: deliveries,
            startingPoint: currentLocation
        ) { [weak self] optimizedDeliveries, coordinates in
            DispatchQueue.main.async {
                self?.optimizedRoute = optimizedDeliveries
                self?.routeCoordinates = coordinates
                self?.isOptimizing = false
            }
        }
    }
} 
