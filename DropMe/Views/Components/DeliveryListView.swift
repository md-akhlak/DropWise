import SwiftUI
import CoreLocation

struct DeliveryListView: View {
    let deliveries: [Delivery]
    let optimizedRoute: [Delivery]?
    let onDeliverySelected: (Delivery) -> Void
    let currentLocation: CLLocationCoordinate2D?
    
    var body: some View {
        List {
            ForEach(Array(deliveries.enumerated()), id: \.element.id) { index, delivery in
                DeliveryRow(
                    delivery: delivery,
                    serialNumber: index + 1,
                    isOptimized: true,
                    currentLocation: currentLocation
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onDeliverySelected(delivery)
                }
            }
        }
    }
}

struct DeliveryRow: View {
    let delivery: Delivery
    let serialNumber: Int
    let isOptimized: Bool
    let currentLocation: CLLocationCoordinate2D?
    
    @State private var distance: Double? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Serial Number Badge
            if isOptimized {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 30, height: 30)
                    
                    Text("\(serialNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            } else {
                // Default marker for non-optimized routes
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(delivery.shortAddress ?? delivery.address)
                            .font(.headline)
                        if let instructions = delivery.deliveryInstructions, !instructions.isEmpty {
                            Text(instructions)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    if let distance = distance {
                        Text(String(format: "%.1f km", distance))
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                
                HStack {
                    Text(delivery.customerName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(delivery.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if let currentLocation = currentLocation {
                delivery.distanceFrom(currentLocation) { result in
                    if let result = result {
                        self.distance = result
                    }
                }
            }
        }
    }
} 
