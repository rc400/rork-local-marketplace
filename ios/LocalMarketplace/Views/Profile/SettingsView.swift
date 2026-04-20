import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var pushEnabled = false
    @State private var showDeleteAlert = false
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("Notifications") {
                    Toggle(isOn: $pushEnabled) {
                        Label("Push Notifications", systemImage: "bell.fill")
                    }
                    .tint(.teal)
                }

                Section("Account") {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Account", systemImage: "trash.fill")
                    }
                }

                Section("Legal") {
                    NavigationLink {
                        LegalPageView(title: "Terms of Service")
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text")
                    }

                    NavigationLink {
                        LegalPageView(title: "Privacy Policy")
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Local Marketplace v1.0")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    appState.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        await appState.deleteAccount()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. Your account and data will be permanently deleted.")
            }
        }
    }
}

struct LegalPageView: View {
    let title: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Local Marketplace")
                    .font(.title2.weight(.bold))

                Text("This is a placeholder for the \(title). Content will be added in a future update.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
