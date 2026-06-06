import SwiftUI
import UniformTypeIdentifiers

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
    @State private var images: [ProductImage] = []
    @State private var isUploading = false
    @State private var showingFilePicker = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    var isEditing: Bool { product != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(isEditing ? "Edit Product" : "New Product")
                    .font(.title3).fontWeight(.bold)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Details group
                    GroupBox {
                        VStack(spacing: 12) {
                            field("Name", text: $name, placeholder: "Product name")
                            field("Description", text: $description, placeholder: "Short description")
                            field("Category", text: $category, placeholder: "e.g. footwear")
                        }
                        .padding(4)
                    } label: {
                        Label("Details", systemImage: "tag")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    // Pricing group
                    GroupBox {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Price (₹)").font(.caption).foregroundStyle(.secondary)
                                TextField("0.00", text: $price)
                                    .textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stock").font(.caption).foregroundStyle(.secondary)
                                TextField("0", text: $stock)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(4)
                    } label: {
                        Label("Pricing & Inventory", systemImage: "indianrupeesign")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    // Images group
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            if !images.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(images) { img in
                                            AsyncImage(url: URL(string: img.url)) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                Color(NSColor.separatorColor)
                                            }
                                            .frame(width: 64, height: 64)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }

                            Button {
                                showingFilePicker = true
                            } label: {
                                Label(
                                    isUploading ? "Uploading..." : "Add Image",
                                    systemImage: isUploading ? "arrow.triangle.2.circlepath" : "photo.badge.plus"
                                )
                            }
                            .disabled(isUploading)
                        }
                        .padding(4)
                    } label: {
                        Label("Images", systemImage: "photo.on.rectangle")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    if !errorMessage.isEmpty {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)

                Spacer()

                Button(action: save) {
                    Group {
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text(isEditing ? "Save Changes" : "Create Product")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.brand)
                .disabled(isLoading || isUploading || name.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 440)
        .onAppear {
            if let p = product {
                name = p.name
                description = p.description
                price = String(p.price)
                stock = String(p.stock)
                category = p.category
                images = p.images
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.jpeg, .png, .heic, .image],
            allowsMultipleSelection: false
        ) { result in
            guard let url = try? result.get().first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let image = NSImage(contentsOf: url),
                  let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
            else { return }

            isUploading = true
            Task {
                do {
                    let uploaded = try await APIClient.shared.uploadImage(jpegData, filename: url.lastPathComponent)
                    images.append(uploaded)
                    print("[Form] images after upload: \(images)")
                } catch {
                    errorMessage = error.localizedDescription
                }
                isUploading = false
            }
        }
    }

    @ViewBuilder
    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(placeholder, text: text).textFieldStyle(.roundedBorder)
        }
    }

    private func save() {
        guard let priceVal = Double(price), let stockVal = Int(stock) else {
            errorMessage = "Invalid price or stock"
            return
        }
        let body: [String: Any] = [
            "name": name,
            "description": description,
            "price": priceVal,
            "stock": stockVal,
            "category": category,
            "images": images.map { ["url": $0.url, "publicId": $0.publicId] }
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
