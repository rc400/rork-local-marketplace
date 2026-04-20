import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showSignUp = false
    @State private var showLogin = false
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [animateGradient ? 0.6 : 0.4, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .teal.opacity(0.3), .blue.opacity(0.2), .cyan.opacity(0.3),
                    .blue.opacity(0.2), .teal.opacity(0.4), .blue.opacity(0.3),
                    .cyan.opacity(0.2), .teal.opacity(0.3), .blue.opacity(0.2)
                ]
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.teal)
                        .symbolEffect(.pulse, options: .repeating)

                    Text("Local")
                        .font(.system(size: 44, weight: .bold, design: .rounded))

                    Text("Discover vendors near you")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Create Account")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .clipShape(.capsule)

                    Button {
                        showLogin = true
                    } label: {
                        Text("Sign In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)
                    .clipShape(.capsule)

                    if appState.isMockMode {
                        mockButtons
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
    }

    private var mockButtons: some View {
        VStack(spacing: 8) {
            Divider().padding(.vertical, 4)
            Text("Preview Mode")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(UserRole.allCases, id: \.self) { role in
                    Button {
                        appState.mockSignIn(as: role)
                    } label: {
                        Text(role.displayName)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                    .clipShape(.capsule)
                }
            }
        }
    }
}
