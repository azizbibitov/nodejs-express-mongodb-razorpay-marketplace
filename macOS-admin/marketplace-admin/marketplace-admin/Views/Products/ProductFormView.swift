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
    @State private var imageURLs: [String] = []
    @State private var selectedImage: NSImage? = nil
    @State private var isUploading = false
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

            // Image section
            HStack(alignment: .top, spacing: 12) {
                Button(isUploading ? "Uploading..." : "Add Image") {
                    pickImage()
                }
                .disabled(isUploading)

                ScrollView(.horizontal) {
                    HStack {
                        ForEach(imageURLs, id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red).font(.caption)
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button(isEditing ? "Save" : "Create", action: save)
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || isUploading)
            }
        }
        .padding()
        .frame(width: 420)
        .onAppear {
            if let p = product {
                name = p.name
                description = p.description
                price = String(p.price)
                stock = String(p.stock)
                category = p.category
                imageURLs = p.images
            }
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .heic]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              let image = NSImage(contentsOf: url),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
        else { return }

        isUploading = true
        Task {
            do {
                let uploadedURL = try await APIClient.shared.uploadImage(jpegData, filename: url.lastPathComponent)
                imageURLs.append(uploadedURL)
            } catch {
                errorMessage = error.localizedDescription
            }
            isUploading = false
        }
    }

    private func save() {
        guard let priceVal = Double(price), let stockVal = Int(stock) else {
            errorMessage = "Invalid price or stock"
            return
        }
        var body: [String: Any] = [
            "name": name,
            "description": description,
            "price": priceVal,
            "stock": stockVal,
            "category": category,
            "images": imageURLs
        ]
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
