import Foundation
import Combine

class APIClient: ObservableObject {
    static let shared = APIClient()

    private let baseURL = "http://192.168.1.109:3000/api"
    private var token: String? = nil

    func setToken(_ token: String) {
        self.token = token
    }

    func clearToken() {
        self.token = nil
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = ["email": email, "password": password]
        return try await post("/auth/login", body: body)
    }

    // MARK: - Products

    func getProducts() async throws -> [Product] {
        return try await get("/products")
    }

    func createProduct(_ body: [String: Any]) async throws -> Product {
        return try await post("/products", body: body)
    }

    func updateProduct(id: String, body: [String: Any]) async throws -> Product {
        return try await put("/products/\(id)", body: body)
    }

    func deleteProduct(id: String) async throws {
        try await delete("/products/\(id)")
    }

    // MARK: - Orders

    func getSellerOrders() async throws -> [Order] {
        return try await get("/orders/seller")
    }

    func updateOrderStatus(id: String, status: String) async throws -> Order {
        return try await patch("/orders/\(id)/status", body: ["status": status])
    }

    func refundOrder(id: String) async throws {
        let _: [String: String] = try await post("/payments/refund/\(id)", body: [:])
    }

    // MARK: - HTTP helpers

    private func request(_ path: String, method: String, body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return data
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await request(path, method: "GET")
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let data = try await request(path, method: "POST", body: body)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func put<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let data = try await request(path, method: "PUT", body: body)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func patch<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let data = try await request(path, method: "PATCH", body: body)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func delete(_ path: String) async throws {
        _ = try await request(path, method: "DELETE")
    }
}
