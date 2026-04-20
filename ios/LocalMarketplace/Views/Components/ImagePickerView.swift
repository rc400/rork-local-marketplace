import SwiftUI
import PhotosUI

struct ImagePickerButton: View {
    let label: String
    let currentURL: String?
    @Binding var imageData: Data?
    var shape: ImagePickerShape = .roundedRect

    @State private var selectedItem: PhotosPickerItem?

    enum ImagePickerShape {
        case circle
        case roundedRect
    }

    var body: some View {
        VStack(spacing: 10) {
            if let data = imageData, let uiImage = UIImage(data: data) {
                imagePreview(Image(uiImage: uiImage))
            } else if let urlString = currentURL, let url = URL(string: urlString) {
                Color(.tertiarySystemGroupedBackground)
                    .frame(height: shape == .circle ? 80 : 120)
                    .frame(width: shape == .circle ? 80 : nil)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else if phase.error != nil {
                                placeholderIcon
                            } else {
                                ProgressView()
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(shape == .circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 12)))
            } else {
                placeholderView
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label(imageData != nil || currentURL != nil ? "Change" : label, systemImage: "photo.on.rectangle.angled")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(.teal)
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func imagePreview(_ image: Image) -> some View {
        switch shape {
        case .circle:
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
        case .roundedRect:
            Color.clear
                .frame(height: 120)
                .overlay { image.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false) }
                .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var placeholderView: some View {
        Group {
            switch shape {
            case .circle:
                Circle()
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .frame(width: 80, height: 80)
                    .overlay { placeholderIcon }
            case .roundedRect:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .frame(height: 120)
                    .overlay { placeholderIcon }
            }
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(.secondary)
    }
}
