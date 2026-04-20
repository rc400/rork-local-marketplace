import SwiftUI

struct WantedBoardView: View {
    let appState: AppState
    let locationService: LocationService
    @State private var viewModel: WantedBoardViewModel
    @State private var selectedCard: WantedCard?
    @State private var showMyBoard = false
    @State private var showRadiusPicker = false
    @State private var showHelpOverlay = false

    init(appState: AppState, locationService: LocationService) {
        self.appState = appState
        self.locationService = locationService
        _viewModel = State(initialValue: WantedBoardViewModel(appState: appState, locationService: locationService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                if viewModel.isLoading && viewModel.filteredFeedCards.isEmpty {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Spacer()
                } else if viewModel.filteredFeedCards.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.filteredFeedCards) { card in
                                WantedCardRow(card: card, distanceString: viewModel.distanceString(for: card))
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedCard = card }

                                if card.id != viewModel.filteredFeedCards.last?.id {
                                    Divider()
                                        .padding(.leading, 96)
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.loadFeed()
                    }
                }
            }
            .navigationTitle("Wanted Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.blue, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHelpOverlay = true } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(item: $selectedCard) { card in
                WantedCardDetailSheet(card: card, viewModel: viewModel, appState: appState)
            }
            .sheet(isPresented: $showMyBoard) {
                NavigationStack {
                    MyBoardView(viewModel: viewModel, appState: appState, locationService: locationService)
                }
            }
            .sheet(isPresented: $showRadiusPicker) {
                RadiusPickerView(viewModel: viewModel, locationService: locationService)
            }
            .task {
                await viewModel.loadFeed()
            }
            .overlay {
                if showHelpOverlay {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { showHelpOverlay = false } }
                        .overlay {
                            VStack(spacing: 16) {
                                Image(systemName: "rectangle.stack.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.blue)

                                Text("Wanted Board")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)

                                Text("Post up to 5 cards you're actively looking to buy. Other collectors nearby can see your listings and message you directly.\n\nBrowse what others are looking for — if you have their card, reach out and make a deal!")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                                    .multilineTextAlignment(.center)

                                Button {
                                    withAnimation { showHelpOverlay = false }
                                } label: {
                                    Text("Got it")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(.blue, in: .rect(cornerRadius: 12))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(28)
                            .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
                            .padding(.horizontal, 32)
                        }
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showHelpOverlay)
        }
    }

    private var headerBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                TextField("Search wanted cards...", text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.searchText = $0 }
                ))
                .font(.subheadline)
                .autocorrectionDisabled()

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))

            Button { showMyBoard = true } label: {
                Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                    .font(.title3)
                    .foregroundStyle(.teal)
            }

            Button { showRadiusPicker = true } label: {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title3)
                    .foregroundStyle(.teal)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.portrait.on.rectangle.portrait.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No Wanted Cards Nearby")
                .font(.headline)
            Text("Be the first to post what you're looking for!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}
