import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var stats: DeliveryStats
    
    init() {
        // Dummy data for testing
        self.user = User(
            id: UUID(),
            name: "John Driver",
            phone: "555-0100",
            email: "john.driver@example.com",
            totalEarnings: 1250.50,
            completedDeliveries: 45,
            rating: 4.8
        )
        
        self.stats = DeliveryStats(
            totalDeliveries: 45,
            completedToday: 8,
            averageTimePerDelivery: 1800, // 30 minutes in seconds
            totalEarningsToday: 160.00
        )
    }
} 