import SwiftUI

@MainActor
struct ProductFormView: View {
    let product: Product?
    let onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var price = ""
    @State private var stock = ""
    @State private var category = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var isEditing: Bool { product != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Product" : "New Product")
                .font(.title2)
                .fontWeight(.bold)

            Group {
                TextField("Name", text: $name)
                TextField("Description", text: $description)
                TextField("Price (₹)", text: $price)
                TextField("Stock", text: $stock)
                TextField("Category", text: $category)
            }
            .textFieldStyle(.roundedBorder)

            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red).font(.caption)
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button(isEditing ? "Save" : "Create", action: save)
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            if let p = product {
                name = p.name
                description = p.description
                price = String(p.price)
                stock = String(p.stock)
                category = p.category
            }
        }
    }

    private func save() {
        guard let priceVal = Double(price), let stockVal = Int(stock) else {
            errorMessage = "Invalid price or stock"
            return
        }
        let body: [String: Any] = ["name": name, "description": description, "price": priceVal, "stock": stockVal, "category": category]
        isLoading = true
        Task {
            do {
                if let p = product {
                    _ = try await APIClient.shared.updateProduct(id: p.id, body: body)
                } else {
                    _ = try await APIClient.shared.createProduct(body)
                }
                await onSave()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
