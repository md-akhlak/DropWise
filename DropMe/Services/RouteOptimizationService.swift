import Foundation
import CoreLocation

protocol RouteOptimizationServiceProtocol {
    func optimizeRoute(deliveries: [Delivery], startingPoint: CLLocationCoordinate2D, completion: @escaping ([Delivery], [[CLLocationCoordinate2D]]?) -> Void)
}

class RouteOptimizationService: RouteOptimizationServiceProtocol {
    
    // MARK: - Main Optimization Method
    func optimizeRoute(deliveries: [Delivery], startingPoint: CLLocationCoordinate2D, completion: @escaping ([Delivery], [[CLLocationCoordinate2D]]?) -> Void) {
        guard !deliveries.isEmpty else {
            completion([], nil)
            return
        }
        // Geocode all deliveries first
        var geocodedDeliveries: [(delivery: Delivery, coordinate: CLLocationCoordinate2D)] = []
        let group = DispatchGroup()
        for delivery in deliveries {
            group.enter()
            delivery.geocodeCoordinates { coordinate in
                if let coordinate = coordinate {
                    geocodedDeliveries.append((delivery, coordinate))
                }
                group.leave()
            }
        }
        group.notify(queue: .global()) {
            // Only use deliveries that were successfully geocoded
            let filteredDeliveries = geocodedDeliveries
            if filteredDeliveries.isEmpty {
                completion([], nil)
                return
            }
            // Run TSP on geocoded deliveries
            let optimized = self.solveTSP(geocodedDeliveries: filteredDeliveries, startingPoint: startingPoint)
            // Return only the deliveries in optimized order
            let optimizedDeliveries = optimized.map { $0.delivery }
            completion(optimizedDeliveries, nil)
        }
    }
    
    // MARK: - TSP Algorithm Implementation (using geocoded deliveries)
    private func solveTSP(geocodedDeliveries: [(delivery: Delivery, coordinate: CLLocationCoordinate2D)], startingPoint: CLLocationCoordinate2D) -> [(delivery: Delivery, coordinate: CLLocationCoordinate2D)] {
        var unvisited = geocodedDeliveries
        var route: [(delivery: Delivery, coordinate: CLLocationCoordinate2D)] = []
        var currentLocation = startingPoint
        
        // Step 1: Nearest Neighbor Algorithm
        while !unvisited.isEmpty {
            let nearestIndex = findNearestIndex(from: currentLocation, to: unvisited)
            let nearest = unvisited[nearestIndex]
            route.append(nearest)
            currentLocation = nearest.coordinate
            unvisited.remove(at: nearestIndex)
        }
        // Step 2: 2-opt improvement for better optimization
        route = twoOptImprovement(route: route, startingPoint: startingPoint)
        return route
    }
    
    // MARK: - Nearest Neighbor Helper (using geocoded deliveries)
    private func findNearestIndex(from location: CLLocationCoordinate2D, to deliveries: [(delivery: Delivery, coordinate: CLLocationCoordinate2D)]) -> Int {
        var minDistance = Double.infinity
        var nearestIndex = 0
        for (index, item) in deliveries.enumerated() {
            let distance = calculateDistance(from: location, to: item.coordinate)
            if distance < minDistance {
                minDistance = distance
                nearestIndex = index
            }
        }
        return nearestIndex
    }
    
    // MARK: - 2-opt Improvement Algorithm (using geocoded deliveries)
    private func twoOptImprovement(route: [(delivery: Delivery, coordinate: CLLocationCoordinate2D)], startingPoint: CLLocationCoordinate2D) -> [(delivery: Delivery, coordinate: CLLocationCoordinate2D)] {
        guard route.count > 3 else { return route }
        var improvedRoute = route
        var improved = true
        let maxIterations = 100 // Prevent infinite loops
        var iterations = 0
        while improved && iterations < maxIterations {
            improved = false
            iterations += 1
            let currentDistance = calculateTotalDistance(route: improvedRoute, startingPoint: startingPoint)
            // Try all possible 2-opt swaps
            for i in 1..<improvedRoute.count - 1 {
                for j in i + 1..<improvedRoute.count {
                    var newRoute = improvedRoute
                    // Perform 2-opt swap: reverse the segment between i and j
                    let segment = Array(improvedRoute[i...j])
                    let reversedSegment = Array(segment.reversed())
                    for k in i...j {
                        newRoute[k] = reversedSegment[k - i]
                    }
                    let newDistance = calculateTotalDistance(route: newRoute, startingPoint: startingPoint)
                    if newDistance < currentDistance {
                        improvedRoute = newRoute
                        improved = true
                        break
                    }
                }
                if improved { break }
            }
        }
        return improvedRoute
    }
    
    // MARK: - Distance Calculations (using geocoded deliveries)
    private func calculateTotalDistance(route: [(delivery: Delivery, coordinate: CLLocationCoordinate2D)], startingPoint: CLLocationCoordinate2D) -> Double {
        var totalDistance = 0.0
        var currentLocation = startingPoint
        for item in route {
            totalDistance += calculateDistance(from: currentLocation, to: item.coordinate)
            currentLocation = item.coordinate
        }
        return totalDistance
    }
    
    private func calculateDistance(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        
        return location1.distance(from: location2) / 1000.0 // Convert to kilometers
    }
    

} 
