import SwiftUI
import MapKit

struct EditStorefrontView: View {
    @Environment(\.dismiss) private var dismiss
    let appState: AppState
    var onSave: (() -> Void)?

    @State private var storeName: String = ""
    @State private var bio: String = ""
    @State private var meetupAddress: String = ""
    @State private var meetupSpotNote: String = ""
    @State private var categoriesText: String = ""
    @State private var profileImageData: Data?
    @State private var coverImageData: Data?
    @State private var currentProfileURL: String?
    @State private var currentCoverURL: String?
    @State private var addressSuggestions: [MKLocalSearchCompletion] = []
    @State private var searchCompleter = AddressSearchCompleter()
    @State private var showSuggestions: Bool = false
    @State private var isSaving: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        ImagePickerButton(
                            label: "Choose Profile Picture",
                            currentURL: currentProfileURL,
                            imageData: $profileImageData,
                            shape: .circle
                        )

                        ImagePickerButton(
                            label: "Choose Cover Photo",
                            currentURL: currentCoverURL,
                            imageData: $coverImageData,
                            shape: .roundedRect
                        )
                    }
                } header: {
                    Text("Images")
                }

                Section("Store Info") {
                    TextField("Store Name", text: $storeName)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Categories") {
                    TextField("e.g. Singles, Slabs, Sealed", text: $categoriesText)
                    Text("Separate with commas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Meetup Location") {
                    TextField("Search address…", text: $meetupAddress)
                        .onChange(of: meetupAddress) { _, newValue in
                            searchCompleter.search(query: newValue)
                            showSuggestions = !newValue.isEmpty
                        }

                    if showSuggestions && !searchCompleter.results.isEmpty {
                        ForEach(searchCompleter.results, id: \.self) { completion in
                            Button {
                                meetupAddress = [completion.title, completion.subtitle]
                                    .filter { !$0.isEmpty }
                                    .joined(separator: ", ")
                                showSuggestions = false
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.title)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    TextField("Exact spot description (optional)", text: $meetupSpotNote)
                }
            }
            .navigationTitle("Edit Storefront")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { saveChanges() }
                            .disabled(storeName.isEmpty || meetupAddress.isEmpty)
                    }
                }
            }
            .onAppear {
                if let vendor = appState.currentVendor {
                    storeName = vendor.storeName
                    bio = vendor.bio ?? ""
                    meetupAddress = vendor.meetupAddress
                    meetupSpotNote = vendor.meetupSpotNote ?? ""
                    categoriesText = vendor.categories.joined(separator: ", ")
                    currentProfileURL = vendor.profileImageURL
                    currentCoverURL = vendor.coverImageURL
                }
            }
        }
    }

    private func saveChanges() {
        guard var vendor = appState.currentVendor else { return }
        isSaving = true

        Task {
            if let data = profileImageData {
                if appState.isMockMode {
                    vendor.profileImageURL = nil
                } else {
                    do {
                        vendor.profileImageURL = try await SupabaseService.shared.uploadImage(bucket: "vendors", folder: vendor.userID, imageData: data)
                    } catch {
                        appState.showToast("Failed to upload profile image", isError: true)
                    }
                }
            }

            if let data = coverImageData {
                if appState.isMockMode {
                    vendor.coverImageURL = nil
                } else {
                    do {
                        vendor.coverImageURL = try await SupabaseService.shared.uploadImage(bucket: "vendors", folder: "\(vendor.userID)/cover", imageData: data)
                    } catch {
                        appState.showToast("Failed to upload cover image", isError: true)
                    }
                }
            }

            vendor.storeName = storeName
            vendor.bio = bio.isEmpty ? nil : bio
            vendor.meetupAddress = meetupAddress
            vendor.meetupSpotNote = meetupSpotNote.isEmpty ? nil : meetupSpotNote
            vendor.categories = categoriesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            vendor.updatedAt = Date()

            let geocoder = CLGeocoder()
            if let placemarks = try? await geocoder.geocodeAddressString(meetupAddress),
               let location = placemarks.first?.location {
                vendor.lat = location.coordinate.latitude
                vendor.lng = location.coordinate.longitude
            }

            if !appState.isMockMode {
                do {
                    try await SupabaseService.shared.updateVendor(vendor)
                } catch {
                    appState.showToast("Failed to save storefront", isError: true)
                    isSaving = false
                    return
                }
            } else {
                MockDataService.shared.updateVendor(vendor)
            }

            appState.currentVendor = vendor
            appState.showToast("Storefront updated")
            onSave?()
            isSaving = false
            dismiss()
        }
    }
}

@MainActor
@Observable
class AddressSearchCompleter: NSObject, MKLocalSearchCompleterDelegate {
    var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func search(query: String) {
        completer.queryFragment = query
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.results = Array(completer.results.prefix(5))
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.results = []
        }
    }
}
