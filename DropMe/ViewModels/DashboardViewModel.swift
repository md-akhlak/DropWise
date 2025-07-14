import Foundation
import CoreLocation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var deliveries: [Delivery] = []
    @Published var selectedDelivery: Delivery?
    @Published var optimizedRoute: [Delivery]?

    @Published var isOptimizing: Bool = false

    
    let locationService: LocationServiceProtocol
    private let routeOptimizationService: RouteOptimizationServiceProtocol
    private let csvImportService = CSVImportService.shared
    
    init(locationService: LocationServiceProtocol, routeOptimizationService: RouteOptimizationServiceProtocol = RouteOptimizationService()) {
        self.locationService = locationService
        self.routeOptimizationService = routeOptimizationService
        loadDeliveryData()
        // Automatically optimize route after loading data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.optimizeRouteAndUpdateDeliveries()
        }
    }
    
    // New: Import CSV from user-selected file
    func importCSV(from url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        let rows = content.components(separatedBy: .newlines)
        var csvData: [CSVDeliveryData] = []
        for row in rows.dropFirst() where !row.isEmpty {
            let columns = row.components(separatedBy: ",")
            if columns.count >= 4 {
                let delivery = CSVDeliveryData(
                    customerName: columns[0].trimmingCharacters(in: .whitespaces),
                    address: columns[1].trimmingCharacters(in: .whitespaces),
                    phone: columns[2].trimmingCharacters(in: .whitespaces),
                    instructions: columns.count > 3 ? columns[3].trimmingCharacters(in: .whitespaces) : nil,
                    priority: columns.count > 4 ? Int(columns[4].trimmingCharacters(in: .whitespaces)) ?? 1 : 1
                )
                csvData.append(delivery)
            }
        }
        deliveries = csvImportService.convertToDeliveries(csvData: csvData, viewModel: self)
        updateShortAddresses()
    }
    
    private func loadDeliveryData() {
        // Try to load from CSV first, fallback to dummy data
        let csvData = csvImportService.importDeliveriesFromCSV(fileName: "deliveries")
        
        if !csvData.isEmpty {
            // Use CSV data
            deliveries = csvImportService.convertToDeliveries(csvData: csvData, viewModel: self)
        } else {
            // Use dummy data for Greater Noida
            loadDummyData()
        }
        
        // Update short addresses for all deliveries
        updateShortAddresses()
    }
    
    private func loadDummyData() {
        // Provided dummy data
        let dummyDeliveries: [Delivery] = [
            Delivery(id: UUID(),
                address: "Alpha Commercial Belt Sector Alpha-1, 201310",
                status: .pending,
                customerName: "Rahul Sharma",
                customerPhone: "",
                deliveryInstructions: "Priority: high, Commission: 15.0",
                timestamp: Date(),
                viewModel: self),
            Delivery(id: UUID(),
                address: "Knowledge Park-3 Sector 62, 201310",
                status: .pending,
                customerName: "Priya Patel",
                customerPhone: "",
                deliveryInstructions: "Priority: medium, Commission: 12.0",
                timestamp: Date(),
                viewModel: self),
            Delivery(id: UUID(),
                address: "Delta-1 Sector 1, 201310",
                status: .pending,
                customerName: "Amit Kumar",
                customerPhone: "",
                deliveryInstructions: "Priority: low, Commission: 10.0",
                timestamp: Date(),
                viewModel: self),
            Delivery(id: UUID(),
                address: "Gamma-1 Sector 4, 201310",
                status: .pending,
                customerName: "Neha Singh",
                customerPhone: "",
                deliveryInstructions: "Priority: high, Commission: 18.0",
                timestamp: Date(),
                viewModel: self),
            Delivery(id: UUID(),
                address: "Beta-1 Sector 2, 201310",
                status: .pending,
                customerName: "Rajesh Verma",
                customerPhone: "",
                deliveryInstructions: "Priority: medium, Commission: 14.0",
                timestamp: Date(),
                viewModel: self),
            Delivery(id: UUID(),
                address: "Knowledge Park-2 Sector 126, 201310",
                status: .pending,
                customerName: "Sunita Gupta",
                customerPhone: "",
                deliveryInstructions: "Priority: high, Commission: 20.0",
                timestamp: Date(),
                viewModel: self),
            Delivery(id: UUID(),
                address: "Chi-4 Sector 16, 201310",
                status: .pending,
                customerName: "Vikram Malhotra",
                customerPhone: "",
                deliveryInstructions: "Priority: medium, Commission: 13.0",
                timestamp: Date(),
                viewModel: self),
            Delivery(id: UUID(),
                address: "Knowledge Park-1 Sector 125, 201310",
                status: .pending,
                customerName: "Anjali Reddy",
                customerPhone: "",
                deliveryInstructions: "Priority: low, Commission: 11.0",
                timestamp: Date(),
                viewModel: self),
            Delivery(id: UUID(),
                address: "Gamma-2 Sector 5, 201310",
                status: .pending,
                customerName: "Deepak Joshi",
                customerPhone: "",
                deliveryInstructions: "Priority: high, Commission: 16.0",
                timestamp: Date(),
                viewModel: self)
        ]
        deliveries = dummyDeliveries
    }
    
    private func updateShortAddresses() {
        let group = DispatchGroup()
        
        for i in 0..<deliveries.count {
            group.enter()
            deliveries[i].geocodeCoordinates { coordinates in
                if let coordinates = coordinates {
                    AddressLookupService.getShortAddress(for: coordinates) { shortAddress in
                        if let shortAddress = shortAddress {
                            self.deliveries[i].shortAddress = shortAddress
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            // Sorting by distance is now async, so you may want to update the UI after all geocoding is done
            // Example: sort by distance from base (requires async distance calculation)
            // You may need to refactor this part to update the UI as distances become available
        }
    }
    
    func selectDelivery(_ delivery: Delivery) {
        selectedDelivery = delivery
    }
    
    // Helper to optimize and update deliveries list
    func optimizeRouteAndUpdateDeliveries() {
        guard let currentLocation = (locationService as? LocationService)?.currentLocation else { return }
        routeOptimizationService.optimizeRoute(
            deliveries: deliveries,
            startingPoint: currentLocation
        ) { [weak self] optimizedDeliveries, _ in
            DispatchQueue.main.async {
                self?.optimizedRoute = optimizedDeliveries
                self?.deliveries = optimizedDeliveries // update main list to match optimized order
                self?.isOptimizing = false
            }
        }
    }
    
    // Filter deliveries to only those within 10 km of the user's current location
    func filterNearbyDeliveries(completion: (() -> Void)? = nil) {
        guard let currentLocation = (locationService as? LocationService)?.currentLocation else {
            completion?()
            return
        }
        let group = DispatchGroup()
        var nearby: [Delivery] = []
        for delivery in deliveries {
            group.enter()
            delivery.distanceFrom(currentLocation) { distance in
                if let distance = distance, distance <= 10.0 {
                    nearby.append(delivery)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.deliveries = nearby
            completion?()
        }
    }
} 
