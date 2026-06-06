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
    let name: String
    let description: String
    let price: Double
    let stock: Int
    let category: String
    let images: [ProductImage]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, description, price, stock, category, images
    }
}

// Returned by POST /api/orders (product is not populated)
struct CreatedOrder: Codable {
    let id: String
    let totalAmount: Double
    let status: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case totalAmount, status
    }
}

// Returned by GET /api/orders/my (product is populated with name + price)
struct OrderProduct: Codable, Identifiable {
    let id: String
    let name: String
    let price: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, price
    }
}

struct Order: Codable, Identifiable {
    let id: String
    let product: OrderProduct?
    let quantity: Int
    let totalAmount: Double
    let status: String
    let createdAt: String
    let razorpayPaymentId: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case product, quantity, totalAmount, status, createdAt, razorpayPaymentId
    }
}

struct RazorpayOrderResponse: Codable {
    let razorpayOrderId: String
    let amount: Int
    let currency: String
}
