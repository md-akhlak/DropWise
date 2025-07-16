import Foundation
import CoreLocation

struct CSVDeliveryData {
    let customerName: String
    let address: String
    let phone: String
    let instructions: String?
    let priority: Int
}

class CSVImportService {
    static let shared = CSVImportService()
    
    private init() {}
    
    // MARK: - CSV Import Methods
    func importDeliveriesFromCSV(fileName: String) -> [CSVDeliveryData] {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "csv"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("CSV file not found: \(fileName)")
            return []
        }
        
        let rows = content.components(separatedBy: .newlines)
        var deliveries: [CSVDeliveryData] = []
        
        // Skip header row
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
                deliveries.append(delivery)
            }
        }
        
        return deliveries
    }
    
    // MARK: - Convert CSV Data to Delivery Objects
    func convertToDeliveries(csvData: [CSVDeliveryData], viewModel: AnyObject) -> [Delivery] {
        return csvData.enumerated().map { index, data in
            // For now, use dummy coordinates based on index
            // In real app, you'd geocode the addresses
            let coordinates = getDummyCoordinates(for: index)
            
            return Delivery(
                id: UUID(),
                address: data.address,
                status: .pending,
                customerName: data.customerName,
                customerPhone: data.phone,
                deliveryInstructions: data.instructions,
                timestamp: Date().addingTimeInterval(Double(index * 300)), // 5 min intervals
                viewModel: viewModel
            )
        }
    }
    
    // MARK: - Dummy Coordinates for Greater Noida
    private func getDummyCoordinates(for index: Int) -> CLLocationCoordinate2D {
        // Greater Noida coordinates spread across different sectors
        let coordinates: [CLLocationCoordinate2D] = [
            // Sector Alpha
            CLLocationCoordinate2D(latitude: 28.4744, longitude: 77.5040),
            CLLocationCoordinate2D(latitude: 28.4760, longitude: 77.5060),
            CLLocationCoordinate2D(latitude: 28.4780, longitude: 77.5080),
            
            // Sector Beta
            CLLocationCoordinate2D(latitude: 28.4800, longitude: 77.5100),
            CLLocationCoordinate2D(latitude: 28.4820, longitude: 77.5120),
            CLLocationCoordinate2D(latitude: 28.4840, longitude: 77.5140),
            
            // Sector Gamma
            CLLocationCoordinate2D(latitude: 28.4860, longitude: 77.5160),
            CLLocationCoordinate2D(latitude: 28.4880, longitude: 77.5180),
            CLLocationCoordinate2D(latitude: 28.4900, longitude: 77.5200),
            
            // Sector Delta
            CLLocationCoordinate2D(latitude: 28.4920, longitude: 77.5220),
            CLLocationCoordinate2D(latitude: 28.4940, longitude: 77.5240),
            CLLocationCoordinate2D(latitude: 28.4960, longitude: 77.5260),
            
            // Sector Epsilon
            CLLocationCoordinate2D(latitude: 28.4980, longitude: 77.5280),
            CLLocationCoordinate2D(latitude: 28.5000, longitude: 77.5300),
            CLLocationCoordinate2D(latitude: 28.5020, longitude: 77.5320),
            
            // Sector Zeta
            CLLocationCoordinate2D(latitude: 28.5040, longitude: 77.5340),
            CLLocationCoordinate2D(latitude: 28.5060, longitude: 77.5360),
            CLLocationCoordinate2D(latitude: 28.5080, longitude: 77.5380),
            
            // Sector Eta
            CLLocationCoordinate2D(latitude: 28.5100, longitude: 77.5400),
            CLLocationCoordinate2D(latitude: 28.5120, longitude: 77.5420),
            CLLocationCoordinate2D(latitude: 28.5140, longitude: 77.5440),
            
            // Sector Theta
            CLLocationCoordinate2D(latitude: 28.5160, longitude: 77.5460),
            CLLocationCoordinate2D(latitude: 28.5180, longitude: 77.5480),
            CLLocationCoordinate2D(latitude: 28.5200, longitude: 77.5500),
            
            // Sector Iota
            CLLocationCoordinate2D(latitude: 28.5220, longitude: 77.5520),
            CLLocationCoordinate2D(latitude: 28.5240, longitude: 77.5540),
            CLLocationCoordinate2D(latitude: 28.5260, longitude: 77.5560),
            
            // Sector Kappa
            CLLocationCoordinate2D(latitude: 28.5280, longitude: 77.5580),
            CLLocationCoordinate2D(latitude: 28.5300, longitude: 77.5600),
            CLLocationCoordinate2D(latitude: 28.5320, longitude: 77.5620),
            
            // Sector Lambda
            CLLocationCoordinate2D(latitude: 28.5340, longitude: 77.5640),
            CLLocationCoordinate2D(latitude: 28.5360, longitude: 77.5660),
            CLLocationCoordinate2D(latitude: 28.5380, longitude: 77.5680),
            
            // Sector Mu
            CLLocationCoordinate2D(latitude: 28.5400, longitude: 77.5700),
            CLLocationCoordinate2D(latitude: 28.5420, longitude: 77.5720),
            CLLocationCoordinate2D(latitude: 28.5440, longitude: 77.5740),
            
            // Sector Nu
            CLLocationCoordinate2D(latitude: 28.5460, longitude: 77.5760),
            CLLocationCoordinate2D(latitude: 28.5480, longitude: 77.5780),
            CLLocationCoordinate2D(latitude: 28.5500, longitude: 77.5800)
        ]
        
        return coordinates[index % coordinates.count]
    }
} 
