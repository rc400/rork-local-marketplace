import SwiftUI
import MapKit

struct RadiusPickerView: View {
    let viewModel: WantedBoardViewModel
    let locationService: LocationService

    @Environment(\.dismiss) private var dismiss
    @State private var tempRadius: Double
    @State private var mapPosition: MapCameraPosition

    init(viewModel: WantedBoardViewModel, locationService: LocationService) {
        self.viewModel = viewModel
        self.locationService = locationService
        let radius = viewModel.radiusKm
        let coord = locationService.userLocation ?? LocationService.torontoCenter
        let latDelta = radius / 111.0 * 2.5
        let lonDelta = latDelta * 1.3
        _tempRadius = State(initialValue: radius)
        _mapPosition = State(initialValue: .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )))
    }

    private var userCoordinate: CLLocationCoordinate2D {
        locationService.userLocation ?? LocationService.torontoCenter
    }

    private func updateMapPosition() {
        let latDelta = tempRadius / 111.0 * 2.5
        let lonDelta = latDelta * 1.3
        withAnimation(.easeInOut(duration: 0.3)) {
            mapPosition = .region(MKCoordinateRegion(
                center: userCoordinate,
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            ))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(position: $mapPosition) {
                    MapCircle(center: userCoordinate, radius: tempRadius * 1000)
                        .foregroundStyle(.teal.opacity(0.15))
                        .stroke(.teal, lineWidth: 2)
                        .mapOverlayLevel(level: .aboveRoads)

                    Annotation("You", coordinate: userCoordinate) {
                        Circle()
                            .fill(.teal)
                            .frame(width: 14, height: 14)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                            }
                            .shadow(radius: 3)
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
                .frame(height: 300)
                .allowsHitTesting(false)

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Search Radius")
                            .font(.headline)
                        Text("\(Int(tempRadius)) km")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.teal)
                            .contentTransition(.numericText())
                    }

                    HStack {
                        Text("1 km")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $tempRadius, in: 1...250, step: 1)
                            .tint(.teal)
                            .onChange(of: tempRadius) { _, _ in
                                updateMapPosition()
                            }
                        Text("250 km")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)

                    Text("This sets both listings shown to you and your listings shown to others.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button {
                        viewModel.updateRadius(tempRadius)
                        dismiss()
                    } label: {
                        Text("Apply")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.teal, in: .rect(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .navigationTitle("Search Radius")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
