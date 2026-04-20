import SwiftUI

struct VendorStorefrontView: View {
    let vendorID: String
    let appState: AppState
    @State private var viewModel: StorefrontViewModel
    @State private var showCreateItem = false
    @State private var showEditStorefront = false
    @State private var showReportSheet = false
    @State private var showBlockAlert = false
    @State private var editingBinder: Binder?
    @State private var showBinderManagement = false
    @State private var showSoldItems = false
    @State private var selectedBinderForFullView: Binder?
    @State private var selectedItemForDetail: MarketplaceItem?
    @State private var quickAddedItemID: String?
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0

    init(vendorID: String, appState: AppState) {
        self.vendorID = vendorID
        self.appState = appState
        _viewModel = State(initialValue: StorefrontViewModel(appState: appState))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                storefrontHeader

                VStack(spacing: 24) {
                    if let vendor = viewModel.vendor {
                        infoSection(vendor)
                    }

                    if !viewModel.visibleBinders.isEmpty {
                        ForEach(viewModel.visibleBinders) { binder in
                            binderRow(binder)
                        }
                    }

                    if !viewModel.unbinderedItems.isEmpty {
                        unbinderedSection
                    }

                    if viewModel.isOwnStore && !viewModel.soldItems.isEmpty {
                        soldPreviewSection
                    }

                    if viewModel.visibleBinders.isEmpty && viewModel.activeItems.isEmpty && !viewModel.isLoading {
                        ContentUnavailableView(
                            "No Items Yet",
                            systemImage: "tray",
                            description: Text(viewModel.isOwnStore ? "Add items to your storefront to get started." : "This vendor hasn't listed any items yet.")
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(viewModel.vendor?.storeName ?? "Store")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isOwnStore {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showEditStorefront = true } label: {
                            Label("Edit Storefront", systemImage: "pencil")
                        }
                        Button { showCreateItem = true } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                        Button { showBinderManagement = true } label: {
                            Label("Manage Binders", systemImage: "folder.badge.gearshape")
                        }
                        Button { showSoldItems = true } label: {
                            Label("Sold Items", systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) { showBlockAlert = true } label: {
                            Label("Block Vendor", systemImage: "hand.raised.fill")
                        }
                        Button { showReportSheet = true } label: {
                            Label("Report Vendor", systemImage: "flag.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadStorefront(vendorID: vendorID)
        }
        .sheet(isPresented: $showCreateItem) {
            CreateItemView(viewModel: viewModel)
        }
        .sheet(isPresented: $showEditStorefront) {
            EditStorefrontView(appState: appState, onSave: {
                Task { await viewModel.loadStorefront(vendorID: vendorID) }
            })
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(reportedVendorID: vendorID, appState: appState)
        }
        .sheet(item: $editingBinder) { binder in
            EditBinderSheet(viewModel: viewModel, binder: binder)
        }
        .sheet(isPresented: $showBinderManagement) {
            BinderManagementView(viewModel: viewModel)
        }
        .fullScreenCover(item: $selectedBinderForFullView) { binder in
            NavigationStack {
                FullBinderView(binder: binder, viewModel: viewModel, appState: appState)
            }
        }
        .sheet(isPresented: $showSoldItems) {
            NavigationStack {
                SoldItemsView(viewModel: viewModel)
            }
        }
        .navigationDestination(item: $selectedItemForDetail) { item in
            ItemDetailView(
                item: item,
                vendorAddress: viewModel.vendor?.meetupAddress,
                isInCart: viewModel.cartQuantity(for: item.id) > 0,
                canAdd: viewModel.canAddToCart(item),
                onAddToCart: viewModel.isOwnStore ? nil : {
                    viewModel.addToCart(item)
                }
            )
        }
        .alert("Block Vendor?", isPresented: $showBlockAlert) {
            Button("Block", role: .destructive) {
                appState.showToast("Vendor blocked")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't receive messages from this vendor anymore.")
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.isOwnStore && !viewModel.inquiryCart.isEmpty {
                inquiryCartBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: viewModel.inquiryCart.isEmpty)
    }

    // MARK: - Header

    private var storefrontHeader: some View {
        ZStack(alignment: .bottomLeading) {
            if let coverURL = viewModel.vendor?.coverImageURL, let url = URL(string: coverURL) {
                Color(.secondarySystemBackground)
                    .frame(height: 180)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Color.teal.opacity(0.15)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect)
            } else {
                LinearGradient(
                    colors: [.teal.opacity(0.3), .teal.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 180)
            }

            HStack(alignment: .bottom, spacing: 14) {
                profileImage
                    .offset(y: 30)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(viewModel.vendor?.storeName ?? "")
                            .font(.title3.weight(.bold))
                        VerifiedBadge()
                    }

                    if viewModel.vendor?.isActive == true {
                        CategoryBadge(text: "Active Now", style: .active)
                    }
                }
                .padding(.bottom, 8)

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 36)
    }

    private var profileImage: some View {
        Group {
            if let profileURL = viewModel.vendor?.profileImageURL, let url = URL(string: profileURL) {
                Color(.tertiarySystemGroupedBackground)
                    .frame(width: 76, height: 76)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "storefront.fill")
                                    .font(.title)
                                    .foregroundStyle(.teal)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.teal.opacity(0.15))
                    .frame(width: 76, height: 76)
                    .overlay {
                        Image(systemName: "storefront.fill")
                            .font(.title)
                            .foregroundStyle(.teal)
                    }
            }
        }
        .overlay {
            Circle()
                .stroke(Color(.systemBackground), lineWidth: 3)
        }
    }

    // MARK: - Info

    private func infoSection(_ vendor: Vendor) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let bio = vendor.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(vendor.categories, id: \.self) { cat in
                        CategoryBadge(text: cat)
                    }
                }
            }
            .contentMargins(.horizontal, 16)

            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.teal)
                VStack(alignment: .leading, spacing: 2) {
                    Text(vendor.meetupAddress)
                        .font(.subheadline)
                    if let spot = vendor.meetupSpotNote, !spot.isEmpty {
                        Text(spot)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Binder Row

    private func binderRow(_ binder: Binder) -> some View {
        let binderItems = viewModel.itemsForBinder(binder.id)
        guard !binderItems.isEmpty || viewModel.isOwnStore else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button {
                        selectedBinderForFullView = binder
                    } label: {
                        HStack(spacing: 6) {
                            Text(binder.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if binder.isHidden && viewModel.isOwnStore {
                                Image(systemName: "eye.slash.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if viewModel.isOwnStore {
                        Button {
                            editingBinder = binder
                        } label: {
                            Image(systemName: "pencil.circle")
                                .foregroundStyle(.teal)
                        }
                    }
                }
                .padding(.horizontal, 16)

                if binderItems.isEmpty {
                    Text("No items in this binder yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(binderItems) { item in
                                HorizontalItemCard(
                                    item: item,
                                    isOwnStore: viewModel.isOwnStore,
                                    isQuickAdded: quickAddedItemID == item.id,
                                    isInCart: viewModel.cartQuantity(for: item.id) > 0,
                                    canAdd: viewModel.canAddToCart(item),
                                    onTap: {
                                        selectedItemForDetail = item
                                    },
                                    onQuickAdd: {
                                        viewModel.addToCart(item)
                                        quickAddedItemID = item.id
                                        Task {
                                            try? await Task.sleep(for: .seconds(1.2))
                                            if quickAddedItemID == item.id {
                                                quickAddedItemID = nil
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .contentMargins(.horizontal, 16)
                }
            }
        )
    }

    // MARK: - Unbindered

    private var unbinderedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Other Items")
                .font(.headline)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.unbinderedItems) { item in
                        HorizontalItemCard(
                            item: item,
                            isOwnStore: viewModel.isOwnStore,
                            isQuickAdded: quickAddedItemID == item.id,
                            isInCart: viewModel.cartQuantity(for: item.id) > 0,
                            canAdd: viewModel.canAddToCart(item),
                            onTap: {
                                selectedItemForDetail = item
                            },
                            onQuickAdd: {
                                viewModel.addToCart(item)
                                quickAddedItemID = item.id
                                Task {
                                    try? await Task.sleep(for: .seconds(1.2))
                                    if quickAddedItemID == item.id {
                                        quickAddedItemID = nil
                                    }
                                }
                            }
                        )
                    }
                }
            }
            .contentMargins(.horizontal, 16)
        }
    }

    // MARK: - Sold Preview

    private var soldPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recently Sold")
                    .font(.headline)
                Spacer()
                Button {
                    showSoldItems = true
                } label: {
                    Text("See All")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.teal)
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.soldItems.prefix(5)) { item in
                        SoldItemCard(item: item)
                    }
                }
            }
            .contentMargins(.horizontal, 16)
        }
    }

    // MARK: - Inquiry Cart Bar

    private var inquiryCartBar: some View {
        Button {
            viewModel.showInquiryCart = true
        } label: {
            HStack {
                Image(systemName: "cart.fill")
                Text("\(viewModel.inquiryCart.count) item\(viewModel.inquiryCart.count == 1 ? "" : "s")")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Send Inquiry")
                    .font(.subheadline.weight(.bold))
            }
            .padding(16)
            .background(.teal, in: .capsule)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $viewModel.showInquiryCart) {
            InquiryCartView(viewModel: viewModel, appState: appState)
        }
    }
}

// MARK: - Horizontal Item Card

struct HorizontalItemCard: View {
    let item: MarketplaceItem
    let isOwnStore: Bool
    var isQuickAdded: Bool = false
    var isInCart: Bool = false
    var canAdd: Bool = true
    var onTap: (() -> Void)?
    var onQuickAdd: (() -> Void)?

    private var cardWidth: CGFloat {
        (UIScreen.main.bounds.width - 16 * 2 - 12) / 2
    }

    private var isTCGItem: Bool {
        (item.category == .single || item.category == .slab) && item.tcgCardImageURL != nil
    }

    private var isHidden: Bool {
        item.status == .inactive
    }

    private var quickAddIcon: String {
        if isQuickAdded { return "checkmark.circle.fill" }
        if isInCart && !canAdd { return "cart.fill" }
        return "plus.circle.fill"
    }

    private var quickAddColor: Color {
        if isQuickAdded { return .green }
        if isInCart && !canAdd { return .secondary }
        return .teal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if isTCGItem, let urlString = item.tcgCardImageURL, let imageURL = URL(string: urlString) {
                    Color(.tertiarySystemGroupedBackground)
                        .aspectRatio(0.714, contentMode: .fit)
                        .overlay {
                            AsyncImage(url: imageURL) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } else if phase.error != nil {
                                    Image(systemName: item.category.icon)
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                } else {
                                    ProgressView()
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 8))
                } else {
                    Color(.tertiarySystemGroupedBackground)
                        .frame(height: 120)
                        .overlay {
                            if let url = item.image1URL, let imageURL = URL(string: url) {
                                AsyncImage(url: imageURL) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Image(systemName: item.category.icon)
                                            .font(.largeTitle)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .allowsHitTesting(false)
                            } else {
                                Image(systemName: item.category.icon)
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .clipShape(.rect(cornerRadius: 8))
                }

                if !isOwnStore {
                    Button {
                        if canAdd {
                            onQuickAdd?()
                        }
                    } label: {
                        Image(systemName: quickAddIcon)
                            .font(.title3)
                            .foregroundStyle(quickAddColor)
                            .background(Circle().fill(.ultraThinMaterial).padding(2))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .disabled(!canAdd && !isQuickAdded)
                    .padding(6)
                }

                if isHidden && isOwnStore {
                    VStack {
                        Spacer()
                        HStack {
                            Text("Hidden")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.ultraThinMaterial)
                                .clipShape(.capsule)
                                .padding(6)
                            Spacer()
                        }
                    }
                }
            }

            Text(item.displayName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(item.formattedPrice)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.teal)

                Spacer()

                if let slabLabel = item.slabDisplayLabel {
                    Text(slabLabel)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.teal.opacity(0.15))
                        .foregroundStyle(.teal)
                        .clipShape(.capsule)
                }
            }

            if let qtyLabel = item.quantityLabel {
                Text(qtyLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: cardWidth)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
        .opacity(isHidden && isOwnStore ? 0.6 : 1.0)
        .contentShape(.rect)
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Sold Item Card

struct SoldItemCard: View {
    let item: MarketplaceItem

    private var cardWidth: CGFloat {
        (UIScreen.main.bounds.width - 16 * 2 - 12) / 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let urlString = item.tcgCardImageURL, let imageURL = URL(string: urlString) {
                Color(.tertiarySystemGroupedBackground)
                    .aspectRatio(0.714, contentMode: .fit)
                    .overlay {
                        AsyncImage(url: imageURL) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fit)
                            } else {
                                Image(systemName: "checkmark.circle")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay(alignment: .topTrailing) {
                        Text("SOLD")
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.red)
                            .foregroundStyle(.white)
                            .clipShape(.capsule)
                            .padding(6)
                    }
            } else {
                Color(.tertiarySystemGroupedBackground)
                    .frame(height: 100)
                    .overlay {
                        Image(systemName: "checkmark.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
                    .clipShape(.rect(cornerRadius: 8))
            }

            Text(item.displayName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            if let soldAt = item.soldAt {
                Text(soldAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: cardWidth * 0.8)
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .opacity(0.85)
    }
}

// MARK: - ItemCard (FullBinderView grid)

struct ItemCard: View {
    let item: MarketplaceItem
    let isOwnStore: Bool
    var isSelected: Bool = false
    var onTap: (() -> Void)?
    var onQuickAdd: (() -> Void)?
    var onSelect: (() -> Void)?
    var isQuickAdded: Bool = false
    var isInCart: Bool = false
    var canAdd: Bool = true

    private var isTCGItem: Bool {
        (item.category == .single || item.category == .slab) && item.tcgCardImageURL != nil
    }

    private var isHidden: Bool {
        item.status == .inactive
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if isTCGItem, let urlString = item.tcgCardImageURL, let imageURL = URL(string: urlString) {
                    Color(.tertiarySystemGroupedBackground)
                        .aspectRatio(0.714, contentMode: .fit)
                        .overlay {
                            AsyncImage(url: imageURL) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } else if phase.error != nil {
                                    Image(systemName: item.category.icon)
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                } else {
                                    ProgressView()
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 8))
                } else {
                    Color(.tertiarySystemGroupedBackground)
                        .frame(height: 120)
                        .overlay {
                            if let url = item.image1URL, let imageURL = URL(string: url) {
                                AsyncImage(url: imageURL) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Image(systemName: item.category.icon)
                                            .font(.largeTitle)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .allowsHitTesting(false)
                            } else {
                                Image(systemName: item.category.icon)
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .clipShape(.rect(cornerRadius: 12))
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, .teal)
                        .padding(6)
                }

                if isHidden && isOwnStore && !isSelected {
                    VStack {
                        Spacer()
                        Text("Hidden")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial)
                            .clipShape(.capsule)
                            .padding(6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.formattedPrice)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.teal)

                    Spacer()

                    if let slabLabel = item.slabDisplayLabel {
                        Text(slabLabel)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.teal.opacity(0.15))
                            .foregroundStyle(.teal)
                            .clipShape(.capsule)
                    }

                    if item.category == .single, let cond = item.condition {
                        Text(cond.shortName)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(.capsule)
                    }
                }

                if let qtyLabel = item.quantityLabel {
                    Text(qtyLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !isOwnStore {
                Button {
                    if canAdd {
                        onQuickAdd?()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isQuickAdded ? "checkmark" : (isInCart && !canAdd ? "cart.fill" : "plus"))
                            .contentTransition(.symbolEffect(.replace))
                        Text(isQuickAdded ? "Added" : (isInCart && !canAdd ? "In Cart" : "Add to Inquiry"))
                    }
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .tint(isQuickAdded ? .green : (isInCart && !canAdd ? .secondary : .teal))
                .clipShape(.capsule)
                .disabled(!canAdd && !isQuickAdded)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
        .opacity(isHidden && isOwnStore ? 0.6 : 1.0)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.teal, lineWidth: 2)
            }
        }
        .contentShape(.rect)
        .onTapGesture {
            if onSelect != nil {
                onSelect?()
            } else {
                onTap?()
            }
        }
    }
}
