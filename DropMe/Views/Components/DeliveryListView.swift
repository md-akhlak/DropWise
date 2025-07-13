import SwiftUI
import CoreLocation

struct DeliveryListView: View {
    let deliveries: [Delivery]
    let onDeliverySelected: (Delivery) -> Void
    let currentLocation: CLLocationCoordinate2D?
    
    var body: some View {
        List(deliveries) { delivery in
            DeliveryRow(delivery: delivery)
                .contentShape(Rectangle())
                .onTapGesture {
                    onDeliverySelected(delivery)
                }
        }
    }
}

struct DeliveryRow: View {
    let delivery: Delivery
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(delivery.shortAddress ?? delivery.address)
                        .font(.headline)
                    Text(delivery.deliveryInstructions ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(String(format: "%.1f km", delivery.distanceFromBase))
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                Text(delivery.customerName)
                    .font(.subheadline)
                Spacer()
                Text(delivery.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
} 