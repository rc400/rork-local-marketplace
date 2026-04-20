import SwiftUI

struct VendorPreviewCard: View {
    let vendor: Vendor
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showStorefront = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    if let profileURL = vendor.profileImageURL, let url = URL(string: profileURL) {
                        Color(.tertiarySystemGroupedBackground)
                            .frame(width: 56, height: 56)
                            .overlay {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Image(systemName: "storefront.fill")
                                            .font(.title2)
                                            .foregroundStyle(.teal)
                                    }
                                }
                                .allowsHitTesting(false)
                            }
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.teal.opacity(0.15))
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: "storefront.fill")
                                    .font(.title2)
                                    .foregroundStyle(.teal)
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(vendor.storeName)
                                .font(.title3.weight(.semibold))
                            VerifiedBadge()
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(vendor.categories, id: \.self) { cat in
                                    CategoryBadge(text: cat)
                                }
                            }
                        }
                    }

                    Spacer()
                }

                if let bio = vendor.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 12) {
                    Button {
                        showStorefront = true
                    } label: {
                        Label("View Store", systemImage: "storefront")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .clipShape(.capsule)

                    NavigationLink {
                        ChatView(
                            conversationID: nil,
                            otherUserID: vendor.userID,
                            otherUserName: vendor.storeName,
                            appState: appState
                        )
                    } label: {
                        Label("Message", systemImage: "message.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)
                    .clipShape(.capsule)
                }
            }
            .padding(20)
            .fullScreenCover(isPresented: $showStorefront) {
                NavigationStack {
                    VendorStorefrontView(vendorID: vendor.userID, appState: appState)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showStorefront = false
                                }
                            }
                        }
                }
            }
        }
    }
}
