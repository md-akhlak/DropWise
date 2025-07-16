import SwiftUI
import UniformTypeIdentifiers

struct SingleDestinationSheet: Identifiable {
    let delivery: Delivery
    let sequence: Int
    var id: UUID { delivery.id }
}

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    @State private var showMap = false
    @State private var showDocumentPicker = false
    @State private var singleDestination: SingleDestinationSheet? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Deliveries")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
                
                if viewModel.isOptimizing {
                    ProgressView("Optimizing route...")
                        .padding()
                }
                
                DeliveryListView(
                    deliveries: viewModel.optimizedRoute ?? viewModel.deliveries,
                    optimizedRoute: viewModel.optimizedRoute,
                    onDeliverySelected: { delivery in
                        let route = viewModel.optimizedRoute ?? viewModel.deliveries
                        if let idx = route.firstIndex(where: { $0.id == delivery.id }) {
                            singleDestination = SingleDestinationSheet(delivery: delivery, sequence: idx + 1)
                        }
                    },
                    currentLocation: (viewModel.locationService as? LocationService)?.currentLocation
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: { showDocumentPicker = true }) {
                    HStack {
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text("Import CSV")
                    }
                },
                trailing: Button(action: { showMap = true }) {
                    Image(systemName: "map")
                        .font(.title2)
                }
            )
            .sheet(isPresented: $showMap) {
                MapScreen(
                    deliveries: viewModel.deliveries,
                    optimizedRoute: viewModel.optimizedRoute,
                    userLocation: (viewModel.locationService as? LocationService)?.currentLocation,
                    singleSequence: nil
                )
            }
            .sheet(item: $singleDestination) { sheet in
                MapScreen(
                    deliveries: [sheet.delivery],
                    optimizedRoute: nil,
                    userLocation: (viewModel.locationService as? LocationService)?.currentLocation,
                    singleSequence: sheet.sequence
                )
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { url in
                    if let url = url {
                        viewModel.importCSV(from: url)
                        viewModel.optimizeRouteAndUpdateDeliveries()
                    }
                }
            }
            .onAppear {
                (viewModel.locationService as? LocationService)?.requestLocationPermission()
                viewModel.optimizeRouteAndUpdateDeliveries()
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
                        viewModel.optimizeRouteAndUpdateDeliveries()
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

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL?) -> Void
        init(onPick: @escaping (URL?) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls.first)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
        }
    }
} 