import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var selectedRole: UserRole = .buyer
    @State private var showVendorApplication = false
    @State private var showPassword = false

    private enum FocusField { case email, username, password }
    @FocusState private var focusedField: FocusField?

    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty && !username.isEmpty && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("Join Local")
                            .font(.title.bold())
                        Text("Create your account to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.subheadline.weight(.medium))
                            TextField("you@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .onSubmit { focusedField = .username }
                                .submitLabel(.next)
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Username")
                                .font(.subheadline.weight(.medium))
                            TextField("choose a username", text: $username)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .username)
                                .onSubmit { focusedField = .password }
                                .submitLabel(.next)
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.subheadline.weight(.medium))
                            HStack(spacing: 0) {
                                Group {
                                    if showPassword {
                                        TextField("min 6 characters", text: $password)
                                    } else {
                                        SecureField("min 6 characters", text: $password)
                                    }
                                }
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.done)

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .padding(.leading, 14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("I want to")
                            .font(.subheadline.weight(.medium))

                        HStack(spacing: 12) {
                            roleCard(role: .buyer, icon: "bag.fill", label: "Buy")
                            roleCard(role: .vendor, icon: "storefront.fill", label: "Sell")
                        }
                    }

                    Button {
                        focusedField = nil
                        Task {
                            await appState.signUp(email: email, password: password, username: username, role: selectedRole)
                            if appState.isAuthenticated {
                                if selectedRole == .vendor {
                                    showVendorApplication = true
                                } else {
                                    appState.showNewAccountBanner = true
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Group {
                            if appState.isLoading {
                                ProgressView()
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .clipShape(.capsule)
                    .disabled(!isValid || appState.isLoading)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showVendorApplication) {
                VendorApplicationFormView(onComplete: { dismiss() })
            }
        }
    }

    private func roleCard(role: UserRole, icon: String, label: String) -> some View {
        Button {
            withAnimation(.snappy) { selectedRole = role }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(selectedRole == role ? Color.teal.opacity(0.12) : Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedRole == role ? Color.teal : Color.clear, lineWidth: 2)
            )
            .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedRole)
    }
}
