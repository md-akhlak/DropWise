import SwiftUI

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    @State private var showingDeliveryFlow = false
    
    var body: some View {
        VStack(spacing: 0) {
            MapView(
                locationService: viewModel.locationService,
                deliveries: viewModel.deliveries,
                optimizedRoute: viewModel.optimizedRoute,
                onOptimizeRoute: {
                    viewModel.optimizeRoute()
                }
            )
            .frame(height: UIScreen.main.bounds.height / 3)
            
            if viewModel.isOptimizing {
                ProgressView("Optimizing route...")
                    .padding()
            }
            
            DeliveryListView(
                deliveries: viewModel.optimizedRoute ?? viewModel.deliveries,
                onDeliverySelected: { delivery in
                    viewModel.selectDelivery(delivery)
                    showingDeliveryFlow = true
                },
                currentLocation: (viewModel.locationService as? LocationService)?.currentLocation
            )
        }
        .sheet(isPresented: $showingDeliveryFlow) {
            if let selectedDelivery = viewModel.selectedDelivery {
                DeliveryFlowView(delivery: selectedDelivery, viewModel: viewModel)
            }
        }
    }
}

struct OptimizeRouteView: View {
    let onOptimize: () -> Void
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack {
            Spacer()
            if viewModel.isOptimizing {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Optimizing Route...")
                        .font(.headline)
                }
            } else {
                Image(systemName: "map")
                    .font(.system(size: 60))
                Text("Optimize Route")
                    .font(.title)
                    .padding()
            }
            Spacer()
            Button("OPTIMIZE ROUTE") {
                onOptimize()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .disabled(viewModel.isOptimizing)
        }
    }
}

struct OptimizedRouteView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                .font(.system(size: 60))
            Text("Route Optimized")
                .font(.title)
                .padding()
            Spacer()
            Button("START") {
                onStart()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

struct DeliveryCompleteView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            Text("Delivery Completed")
                .font(.title)
                .padding()
            Spacer()
            Button("OK") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

struct DeliveryFlowView: View {
    let delivery: Delivery
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                switch currentStep {
                case 0:
                    OptimizeRouteView(onOptimize: {
                        viewModel.optimizeRoute()
                        // Move to next step after optimization is complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            currentStep = 1
                        }
                    }, viewModel: viewModel)
                case 1:
                    OptimizedRouteView {
                        currentStep = 2
                    }
                case 2:
                    DeliveryCompleteView {
                        dismiss()
                    }
                default:
                    EmptyView()
                }
            }
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
} 