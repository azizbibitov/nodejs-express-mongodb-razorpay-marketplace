import SwiftUI

struct ProductsView: View {
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var searchText = ""

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var filtered: [Product] {
        if searchText.isEmpty { return products }
        return products.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.category.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !errorMessage.isEmpty {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else if filtered.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if products.isEmpty {
                    ContentUnavailableView("No Products", systemImage: "shippingbox", description: Text("Check back soon."))
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filtered) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    ProductCard(product: product)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Shop")
            .searchable(text: $searchText, prompt: "Search products")
            .task { await loadProducts() }
            .refreshable { await loadProducts() }
        }
    }

    private func loadProducts() async {
        isLoading = products.isEmpty
        do {
            products = try await APIClient.shared.getProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                // A definite-size base view (full cell width x 160) defines the
                // layout. The image is rendered as an overlay so it can fill and
                // crop without its aspect ratio widening the grid cell.
                Color(.systemGray5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .overlay {
                        if let imageURL = product.images.first.flatMap({ URL(string: $0.url) }) {
                            AsyncImage(url: imageURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color(.systemGray5)
                            }
                        } else {
                            Image(systemName: "photo")
                                .foregroundStyle(.tertiary)
                                .font(.largeTitle)
                        }
                    }
                    .clipped()

                if product.stock == 0 {
                    Text("Out of stock")
                        .font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(product.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .lineLimit(2)
                Text(String(format: "$%.2f", product.price))
                    .font(.subheadline)
                    .foregroundStyle(Color.brand)
                    .fontWeight(.bold)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
    }
}
