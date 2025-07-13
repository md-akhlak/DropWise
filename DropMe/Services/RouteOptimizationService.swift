import Foundation
import CoreLocation
import MapKit

protocol RouteOptimizationServiceProtocol {
    func optimizeRoute(deliveries: [Delivery], startingPoint: CLLocationCoordinate2D, completion: @escaping ([Delivery], [[CLLocationCoordinate2D]]?) -> Void)
}

class RouteOptimizationService: RouteOptimizationServiceProtocol {
    func optimizeRoute(deliveries: [Delivery], startingPoint: CLLocationCoordinate2D, completion: @escaping ([Delivery], [[CLLocationCoordinate2D]]?) -> Void) {
        // If no deliveries, return empty array
        if deliveries.isEmpty {
            completion([], nil)
            return
        }
        
        // Create a mutable array of unvisited deliveries
        var unvisitedDeliveries = deliveries
        var optimizedRoute: [Delivery] = []
        var routeCoordinates: [[CLLocationCoordinate2D]] = []
        let group = DispatchGroup()
        
        // Start from the current location
        var currentLocation = startingPoint
        
        // Keep finding the nearest delivery until all deliveries are visited
        func processNextDelivery() {
            if unvisitedDeliveries.isEmpty {
                completion(optimizedRoute, routeCoordinates)
                return
            }
            
            // Find the nearest delivery to the current location
            let (nextDelivery, nextIndex) = findNearestDelivery(
                from: currentLocation,
                deliveries: unvisitedDeliveries
            )
            
            // Calculate actual route to the next delivery
            group.enter()
            calculateRoute(from: currentLocation, to: nextDelivery.coordinates) { coordinates in
                if let coordinates = coordinates {
                    routeCoordinates.append(coordinates)
                }
                
                // Add the nearest delivery to the optimized route
                optimizedRoute.append(nextDelivery)
                
                // Remove the visited delivery from unvisited deliveries
                unvisitedDeliveries.remove(at: nextIndex)
                
                // Update current location to the last visited delivery
                currentLocation = nextDelivery.coordinates
                
                group.leave()
                
                // Process next delivery
                processNextDelivery()
            }
        }
        
        // Start processing deliveries
        processNextDelivery()
    }
    
    private func findNearestDelivery(from location: CLLocationCoordinate2D, deliveries: [Delivery]) -> (Delivery, Int) {
        var minDistance = Double.infinity
        var nearestDeliveryIndex = 0
        
        for (index, delivery) in deliveries.enumerated() {
            let distance = calculateDistance(
                from: location,
                to: delivery.coordinates
            )
            
            if distance < minDistance {
                minDistance = distance
                nearestDeliveryIndex = index
            }
        }
        
        return (deliveries[nearestDeliveryIndex], nearestDeliveryIndex)
    }
    
    private func calculateDistance(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(
            latitude: coordinate1.latitude,
            longitude: coordinate1.longitude
        )
        let location2 = CLLocation(
            latitude: coordinate2.latitude,
            longitude: coordinate2.longitude
        )
        
        return location1.distance(from: location2) / 1000.0
    }
    
    private func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, completion: @escaping ([CLLocationCoordinate2D]?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                completion(nil)
                return
            }
            
            let coordinates = route.polyline.coordinates
            completion(coordinates)
        }
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
} 
