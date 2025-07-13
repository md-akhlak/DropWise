import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(viewModel.user.name)
                        .font(.title)
                    
                    Text(viewModel.user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Stats Cards
                VStack(spacing: 15) {
                    StatCard(title: "Total Earnings", value: "$\(String(format: "%.2f", viewModel.user.totalEarnings))")
                    StatCard(title: "Today's Earnings", value: "$\(String(format: "%.2f", viewModel.stats.totalEarningsToday))")
                    StatCard(title: "Rating", value: "\(String(format: "%.1f", viewModel.user.rating)) ⭐️")
                    StatCard(title: "Completed Deliveries", value: "\(viewModel.user.completedDeliveries)")
                }
                .padding()
                
                // Today's Stats
                VStack(alignment: .leading, spacing: 15) {
                    Text("Today's Stats")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 10) {
                        StatRow(title: "Deliveries Completed", value: "\(viewModel.stats.completedToday)")
                        StatRow(title: "Average Time per Delivery", value: formatTime(viewModel.stats.averageTimePerDelivery))
                        StatRow(title: "Total Earnings", value: "$\(String(format: "%.2f", viewModel.stats.totalEarningsToday))")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        return "\(minutes) min"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .bold()
        }
    }
} 