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
    var status: DeliveryStatus
    var customerName: String
    var customerPhone: String
    var deliveryInstructions: String?
    var timestamp: Date
    var shortAddress: String?
    weak var viewModel: AnyObject?
    
    // Base location (Greater Noida - Knowledge Park)
    static let baseLocation = CLLocationCoordinate2D(latitude: 28.4744, longitude: 77.5040)
    
    // New: Geocode address to coordinates on-the-fly
    func geocodeCoordinates(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let location = placemarks?.first?.location {
                completion(location.coordinate)
            } else {
                completion(nil)
            }
        }
    }
    
    // Fixed distance from base location (async)
    func distanceFromBase(completion: @escaping (Double?) -> Void) {
        geocodeCoordinates { coordinates in
            guard let coordinates = coordinates else {
                completion(nil)
                return
            }
            let deliveryLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            let baseLocationCL = CLLocation(latitude: Self.baseLocation.latitude, longitude: Self.baseLocation.longitude)
            completion(deliveryLocation.distance(from: baseLocationCL) / 1000.0) // km
        }
    }
    
    // Dynamic distance from current location (for route optimization, async)
    func distanceFrom(_ location: CLLocationCoordinate2D?, completion: @escaping (Double?) -> Void) {
        guard let location = location else { completion(nil); return }
        geocodeCoordinates { coordinates in
            guard let coordinates = coordinates else {
                completion(nil)
                return
            }
            let deliveryLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            let currentLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            completion(deliveryLocation.distance(from: currentLocation) / 1000.0) // km
        }
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