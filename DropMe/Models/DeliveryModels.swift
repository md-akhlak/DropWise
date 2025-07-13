import Foundation
import CoreLocation

class AddressLookupService {
    static func getShortAddress(for coordinates: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var components: [String] = []
                
                if let subLocality = placemark.subLocality {
                    components.append(subLocality)
                }
                
                if let locality = placemark.locality {
                    components.append(locality)
                }
                
                if let postalCode = placemark.postalCode {
                    components.append(postalCode)
                }
                
                let shortAddress = components.joined(separator: ", ")
                completion(shortAddress)
            } else {
                completion(nil)
            }
        }
    }
}

struct User: Identifiable {
    let id: UUID
    var name: String
    var phone: String
    var email: String
    var totalEarnings: Double
    var completedDeliveries: Int
    var rating: Double
}

struct Delivery: Identifiable {
    let id: UUID
    var address: String
    var coordinates: CLLocationCoordinate2D
    var status: DeliveryStatus
    var customerName: String
    var customerPhone: String
    var deliveryInstructions: String?
    var timestamp: Date
    var shortAddress: String?
    weak var viewModel: AnyObject?
    
    // Base location (Sector 62 Noida)
    static let baseLocation = CLLocationCoordinate2D(latitude: 28.6266, longitude: 77.3649)
    
    // Fixed distance from base location
    var distanceFromBase: Double {
        let deliveryLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let baseLocationCL = CLLocation(latitude: Self.baseLocation.latitude, longitude: Self.baseLocation.longitude)
        return deliveryLocation.distance(from: baseLocationCL) / 1000.0 // Convert to kilometers
    }
    
    // Dynamic distance from current location (for route optimization)
    func distanceFrom(_ location: CLLocationCoordinate2D?) -> Double? {
        guard let location = location else { return nil }
        let deliveryLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let currentLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return deliveryLocation.distance(from: currentLocation) / 1000.0 // Convert to kilometers
    }
}

enum DeliveryStatus {
    case pending
    case inProgress
    case completed
    case failed
}

struct DeliveryStats {
    var totalDeliveries: Int
    var completedToday: Int
    var averageTimePerDelivery: TimeInterval
    var totalEarningsToday: Double
} 