import SwiftUI

struct VendorApplicationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var onComplete: () -> Void

    @State private var legalFirstName = ""
    @State private var legalLastName = ""
    @State private var businessName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var cityRegion = ""
    @State private var whatDoYouSell = ""
    @State private var cardShowFrequency = ""
    @State private var socialMedia = ""
    @State private var whySell = ""
    @State private var agreedToTerms = false

    private var isValid: Bool {
        !legalFirstName.isEmpty && !legalLastName.isEmpty && !contactEmail.isEmpty && !cityRegion.isEmpty && !whatDoYouSell.isEmpty && !whySell.isEmpty && agreedToTerms
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.teal)
                        Text("Vendor Application")
                            .font(.title2.bold())
                        Text("Tell us a bit about yourself so we can review your application.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            fieldSection(title: "First Name", placeholder: "First", text: $legalFirstName)
                            fieldSection(title: "Last Name", placeholder: "Last", text: $legalLastName)
                        }

                        fieldSection(title: "Business Name (Optional)", placeholder: "Your business name", text: $businessName)

                        fieldSection(title: "Contact Email", placeholder: "vendor@example.com", text: $contactEmail, keyboard: .emailAddress)

                        fieldSection(title: "Contact Phone", placeholder: "416-555-0100", text: $contactPhone, keyboard: .phonePad)

                        fieldSection(title: "City / Region", placeholder: "e.g. Toronto, GTA", text: $cityRegion)

                        multilineSection(title: "What do you primarily sell?", placeholder: "e.g. Pokémon singles, sealed product, Japanese imports, graded cards...", text: $whatDoYouSell)

                        multilineSection(title: "How often do you attend card shows?", placeholder: "e.g. Weekly, a few times a month, rarely...", text: $cardShowFrequency)

                        multilineSection(title: "Social media & online presence", placeholder: "Instagram, TikTok, eBay, or any other usernames / links", text: $socialMedia)

                        multilineSection(title: "Why do you want to sell on Local?", placeholder: "What motivates you to sell locally?", text: $whySell)

                        Toggle(isOn: $agreedToTerms) {
                            Text("I agree to the Terms of Service")
                                .font(.subheadline)
                        }
                        .tint(.teal)
                        .padding(.top, 4)
                    }

                    Button {
                        submitApplication()
                    } label: {
                        Text("Submit Application")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .clipShape(.capsule)
                    .disabled(!isValid)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func fieldSection(title: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
        }
    }

    private func multilineSection(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(3...6)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
        }
    }

    private func submitApplication() {
        guard let user = appState.currentUser else { return }
        let application = VendorApplication(
            id: UUID().uuidString,
            userID: user.id,
            status: .pending,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            answersJSON: [
                "legal_first_name": legalFirstName,
                "legal_last_name": legalLastName,
                "business_name": businessName,
                "city_region": cityRegion,
                "what_do_you_sell": whatDoYouSell,
                "card_show_frequency": cardShowFrequency,
                "social_media": socialMedia,
                "why_sell": whySell,
                "agreed_to_terms": "true",
                "submitted_at": ISO8601DateFormatter().string(from: Date())
            ]
        )

        if appState.isMockMode {
            appState.vendorApplication = application
            appState.showToast("Application submitted!")
            onComplete()
            return
        }

        Task {
            do {
                try await SupabaseService.shared.submitVendorApplication(application)
                let storeName = businessName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "\(legalFirstName) \(legalLastName)"
                    : businessName
                let categories = whatDoYouSell
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                let vendor = Vendor(
                    userID: user.id,
                    storeName: storeName,
                    categories: categories.isEmpty ? ["General"] : categories,
                    meetupAddress: cityRegion,
                    approved: false,
                    isDisabled: false,
                    isActive: false
                )
                try await SupabaseService.shared.createVendor(vendor)
                appState.currentVendor = vendor
                appState.vendorApplication = application
                appState.showToast("Application submitted!")
                onComplete()
            } catch {
                appState.showToast("Failed to submit application", isError: true)
            }
        }
    }
}
