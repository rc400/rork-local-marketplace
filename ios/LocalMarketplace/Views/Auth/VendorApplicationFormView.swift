import SwiftUI

struct VendorApplicationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var onComplete: () -> Void

    @State private var legalName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var experience = ""
    @State private var whySell = ""
    @State private var source = ""

    private var isValid: Bool {
        !legalName.isEmpty && !contactEmail.isEmpty
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
                        fieldSection(title: "Legal / Business Name", placeholder: "Your name or business name", text: $legalName)
                        fieldSection(title: "Contact Email", placeholder: "vendor@example.com", text: $contactEmail, keyboard: .emailAddress)
                        fieldSection(title: "Contact Phone", placeholder: "416-555-0100", text: $contactPhone, keyboard: .phonePad)
                        multilineSection(title: "Selling Experience", placeholder: "Tell us about your experience...", text: $experience)
                        multilineSection(title: "Why do you want to sell?", placeholder: "What motivates you to sell locally?", text: $whySell)
                        multilineSection(title: "Where do you source inventory?", placeholder: "Personal collection, wholesale, etc.", text: $source)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip for Now") {
                        onComplete()
                    }
                }
            }
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
                "experience": experience,
                "why_sell": whySell,
                "source": source
            ]
        )
        appState.vendorApplication = application

        if !appState.isMockMode {
            Task {
                try? await SupabaseService.shared.submitVendorApplication(application)
            }
        }

        appState.showToast("Application submitted!")
        onComplete()
    }
}
