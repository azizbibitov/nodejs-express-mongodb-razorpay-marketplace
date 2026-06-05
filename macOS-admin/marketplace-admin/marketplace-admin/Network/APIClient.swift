import Foundation
import Combine

class APIClient: ObservableObject {
    static let shared = APIClient()

    private let baseURL = "http://192.168.1.109:3000/api"
    private var token: String? = nil

    func setToken(_ token: String) {
        self.token = token
        KeychainManager.saveToken(token)
    }

    func loadSavedToken() {
        self.token = KeychainManager.loadToken()
    }

    func clearToken() {
        self.token = nil
        KeychainManager.deleteToken()
    }

    var hasToken: Bool { token != nil }

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

    // MARK: - Upload

    func uploadImage(_ imageData: Data, filename: String) async throws -> String {
        guard let url = URL(string: baseURL + "/upload/image") else { throw URLError(.badURL) }
        let boundary = UUID().uuidString
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        print("[API] POST /upload/image")
        let (data, response) = try await URLSession.shared.data(for: req)
        let http = response as? HTTPURLResponse
        print("[API] POST /upload/image -> \(http?.statusCode ?? -1)")
        guard let http, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[API] Error: \(msg)")
            throw NSError(domain: "API", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        print("[API] Upload response: \(String(data: data, encoding: .utf8) ?? "")")
        let result = try JSONDecoder().decode([String: String].self, from: data)
        guard let imageUrl = result["url"] else { throw URLError(.cannotParseResponse) }
        print("[API] Image URL: \(imageUrl)")
        return imageUrl
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
        print("[API] \(method) \(path)")
        let (data, response) = try await URLSession.shared.data(for: req)
        let http = response as? HTTPURLResponse
        print("[API] \(method) \(path) -> \(http?.statusCode ?? -1)")
        guard let http, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[API] Error: \(msg)")
            throw NSError(domain: "API", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        print("[API] Response: \(String(data: data, encoding: .utf8) ?? "")")
        return data
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await request(path, method: "GET")
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("[API] Decode error on GET \(path): \(error)")
            throw error
        }
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let data = try await request(path, method: "POST", body: body)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("[API] Decode error on POST \(path): \(error)")
            throw error
        }
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
