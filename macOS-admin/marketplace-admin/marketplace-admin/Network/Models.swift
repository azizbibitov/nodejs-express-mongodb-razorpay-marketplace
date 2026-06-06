import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let role: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, email, role
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct ProductImage: Codable, Identifiable {
    let url: String
    let publicId: String
    var id: String { publicId }
}

struct Product: Codable, Identifiable {
    let id: String
    var name: String
    var description: String
    var price: Double
    var stock: Int
    var category: String
    var images: [ProductImage]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, description, price, stock, category, images
    }
}

struct Order: Codable, Identifiable {
    let id: String
    let buyer: User?
    let product: Product?
    let quantity: Int
    let totalAmount: Double
    var status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case buyer, product, quantity, totalAmount, status, createdAt
    }
}
