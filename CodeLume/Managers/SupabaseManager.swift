//
//  SupabaseManager.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/27.
//

import Foundation
import Supabase
import AppKit

private enum JWTParse {
    static func decodePayload(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        let payloadPart = String(parts[1])
        guard let payloadData = base64URLDecode(payloadPart) else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: payloadData) else { return nil }
        return obj as? [String: Any]
    }

    private static func base64URLDecode(_ input: String) -> Data? {
        var s = input.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let rem = s.count % 4
        if rem != 0 {
            s += String(repeating: "=", count: 4 - rem)
        }
        return Data(base64Encoded: s)
    }
}

struct IAPVerifyResponse: Codable {
    let success: Bool
    let creditsGranted: Int
    let balance: Int

    enum CodingKeys: String, CodingKey {
        case success
        case creditsGranted = "credits_granted"
        case balance
    }
}

struct WallpaperCreditsPurchaseResponse: Codable {
    let success: Bool
    let alreadyOwned: Bool
    let balance: Int

    enum CodingKeys: String, CodingKey {
        case success
        case alreadyOwned = "already_owned"
        case balance
    }
}

struct WallpaperDownloadLinkResponse: Codable {
    let success: Bool
    let url: String
}

struct RecordFreeDownloadResponse: Codable {
    let success: Bool
    let alreadyCounted: Bool

    enum CodingKeys: String, CodingKey {
        case success
        case alreadyCounted = "already_counted"
    }
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    private static let supabaseUrlKey = "SUPABASE_URL"
    private static let supabaseAnonKey = "SUPABASE_ANON_KEY"

    private lazy var supabaseUrl: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: Self.supabaseUrlKey) as? String,
              let url = URL(string: urlString),
              !urlString.isEmpty else {
            fatalError("Missing or invalid SUPABASE_URL in Info.plist")
        }
        return url
    }()

    private lazy var supabaseKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: Self.supabaseAnonKey) as? String,
              !key.isEmpty else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist")
        }
        return key
    }()
    
    @Published var isLoading = false
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var creditsBalance: Int?
    @Published var isCreditsLoading: Bool = false
    
    private var creditsRefreshTask: Task<Void, Never>?
    
    lazy var client: SupabaseClient = {
        return SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey
        )
    }()
    
    private init() {
        isLoading = true
        listenForAuthChanges()
    }
    
    func listenForAuthChanges() {
        Task{
            for await (event, session) in client.auth.authStateChanges {
                switch event {
                case .initialSession:
                    await MainActor.run {
                        self.currentUser = session?.user
                        self.isAuthenticated = (session?.user != nil)
                        self.isLoading = false
                    }
                    if session?.user != nil {
                        Task { await self.refreshCreditsBalance() }
                    } else {
                        await MainActor.run {
                            self.creditsBalance = nil
                            self.isCreditsLoading = false
                        }
                    }
                case .signedIn, .userUpdated:
                    await MainActor.run {
                        self.currentUser = session?.user
                        self.isAuthenticated = true
                        self.isLoading = false
                    }
                    Task { await self.refreshCreditsBalance() }
                case .signedOut:
                    await MainActor.run {
                        self.currentUser = nil
                        self.isAuthenticated = false
                        self.isLoading = false
                        self.creditsBalance = nil
                        self.isCreditsLoading = false
                    }
                default:
                    break
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        await MainActor.run {
            self.isLoading = true
        }
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            await MainActor.run {
                self.isLoading = false
                self.isAuthenticated = true
                self.currentUser = session.user
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                Alert(title: "Sign in failed!", dynamicMessage: error.localizedDescription)
            }
            return false
        }
        return true
    }

    func signInWithApple(idToken: String, nonce: String?) async -> Bool {
        await MainActor.run {
            self.isLoading = true
        }

        do {
            let credentials = OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )

            let session = try await client.auth.signInWithIdToken(credentials: credentials)
            await MainActor.run {
                self.isLoading = false
                self.isAuthenticated = true
                self.currentUser = session.user
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                Alert(title: "Apple ID sign in failed!", dynamicMessage: error.localizedDescription)
            }
            return false
        }

        return true
    }
    
    func signOut() {
        isLoading = true
        Task {
            do {
                try await client.auth.signOut()
            } catch {
                await MainActor.run {
                    Alert(title: "Sign out failed.", dynamicMessage: error.localizedDescription)
                }
            }
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func getCurrentUser() async throws -> Auth.User? {
        let session = try await client.auth.session
        return session.user
    }
    
    func getUserProfile() async throws -> UserTable {
        let session = try await client.auth.session
        let user = session.user
        
        
        let userTable = UserTable(id: user.id, email: user.email, username: user.role!, avatarUrl: nil, createdAt: .now, updatedAt: .now)
        return userTable
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        try await client.auth.update(
            user: UserAttributes(password: newPassword)
        )
    }
    
    func updateUserAvatar(avatarName: String) async throws {
        let authUser = try await getCurrentUser()
        guard let authUser else {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let metadata = authUser.userMetadata
        //        metadata["avatar_name"] = avatarName
        
        try await client.auth.update(
            user: UserAttributes(data: metadata)
        )
    }
    
    func getWallpapers(page: Int = 1, limit: Int = 20) async throws -> [WallpaperTable] {
        let wallpapers: [WallpaperTable] = try await client
            .from("wallpapers")
            .select()
            .eq("is_approved", value: true)
            .order("created_at", ascending: false)
            .range(from: (page - 1) * limit, to: page * limit - 1)
            .execute()
            .value
        return wallpapers
    }
    
    func getWallpaper(id: UUID) async throws -> WallpaperTable {
        let response = try await client
            .from("wallpapers")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        
        let wallpaper = try JSONDecoder().decode(WallpaperTable.self, from: response.data)
        return wallpaper
    }

    func getWallpaperVideoInfo(wallpaperId: UUID) async throws -> WallpaperVideoInfoTable? {
        let infos: [WallpaperVideoInfoTable] = try await client
            .from("wallpaper_video_info")
            .select()
            .eq("wallpaper_id", value: wallpaperId)
            .limit(1)
            .execute()
            .value

        return infos.first
    }

    func getCreditPackages() async throws -> [CreditPackageTable] {
        let packages: [CreditPackageTable] = try await client
            .from("iap_products")
            .select()
            .eq("is_active", value: true)
            .order("credits", ascending: true)
            .execute()
            .value
        return packages
    }

    func getUserCredits() async throws -> Int {
        guard let currentUser = try await getCurrentUser() else {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let balances: [UserBalanceTable] = try await client
            .from("user_balances")
            .select()
            .eq("user_id", value: currentUser.id)
            .execute()
            .value
        return balances.first?.credits ?? 0
    }

    func refreshCreditsBalance() async {
        guard isAuthenticated else {
            await MainActor.run {
                self.creditsBalance = nil
                self.isCreditsLoading = false
            }
            return
        }

        creditsRefreshTask?.cancel()
        creditsRefreshTask = Task {
            await MainActor.run { self.isCreditsLoading = true }
            do {
                let credits = try await self.getUserCredits()
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.creditsBalance = credits
                    self.isCreditsLoading = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.isCreditsLoading = false
                }
            }
        }
        await creditsRefreshTask?.value
    }

    func hasPurchasedWallpaper(wallpaperId: UUID) async throws -> Bool {
        guard let currentUser = try await getCurrentUser() else {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let entitlements: [WallpaperEntitlementTable] = try await client
            .from("wallpaper_entitlements")
            .select()
            .eq("user_id", value: currentUser.id)
            .eq("wallpaper_id", value: wallpaperId)
            .execute()
            .value
        return !entitlements.isEmpty
    }

    func verifyIAPPurchase(signedTransactionInfo: String) async throws -> IAPVerifyResponse {
        struct VerifyBody: Codable {
            let signedTransactionInfo: String
        }
        let body = VerifyBody(signedTransactionInfo: signedTransactionInfo)
        return try await invokeEdgeFunction(name: "verify-iap-purchase", body: body)
    }

    func purchaseWallpaperWithCredits(wallpaperId: UUID) async throws -> WallpaperCreditsPurchaseResponse {
        struct PurchaseBody: Codable {
            let wallpaperId: String

            enum CodingKeys: String, CodingKey {
                case wallpaperId = "wallpaper_id"
            }
        }

        let body = PurchaseBody(wallpaperId: wallpaperId.uuidString.lowercased())
        return try await invokeEdgeFunction(name: "purchase-wallpaper-with-credits", body: body)
    }

    func getPurchasedWallpaperDownloadURL(wallpaperId: UUID) async throws -> URL {
        struct DownloadBody: Codable {
            let wallpaperId: String

            enum CodingKeys: String, CodingKey {
                case wallpaperId = "wallpaper_id"
            }
        }

        Logger.info("[DownloadLink] Requesting purchased link. wallpaperId=\(wallpaperId.uuidString.lowercased())")

        let body = DownloadBody(wallpaperId: wallpaperId.uuidString.lowercased())
        let response: WallpaperDownloadLinkResponse
        do {
            response = try await invokeEdgeFunction(name: "create-purchased-download-link", body: body)
        } catch {
            Logger.error("[DownloadLink] Edge function call failed. error=\(error.localizedDescription)")
            throw error
        }
        Logger.info("[DownloadLink] Edge function response. success=\(response.success), rawUrl=\(response.url)")
        guard response.success, let url = URL(string: response.url) else {
            Logger.error("[DownloadLink] Invalid URL response. success=\(response.success), rawUrl=\(response.url)")
            throw NSError(domain: "SupabaseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL response"])
        }
        Logger.info("[DownloadLink] Parsed URL absoluteString=\(url.absoluteString)")
        return url
    }

    func recordFreeDownload(wallpaperId: UUID) async throws -> RecordFreeDownloadResponse {
        struct Body: Codable {
            let wallpaperId: String
            enum CodingKeys: String, CodingKey {
                case wallpaperId = "wallpaper_id"
            }
        }
        let body = Body(wallpaperId: wallpaperId.uuidString.lowercased())
        return try await invokeEdgeFunction(name: "record-free-download", body: body)
    }

    /// 免费壁纸无需 entitlement：用用户 JWT 直接从 Storage 拉取（RLS/Storage policy 负责放行）
    func makeAuthedWallpaperBundleRequest(wallpaper: WallpaperTable) async throws -> URLRequest {
        let accessToken = try await validAccessToken()

        let userId = wallpaper.userId.uuidString.lowercased()
        let wallpaperId = wallpaper.id.uuidString.lowercased()

        let url = supabaseUrl
            .appendingPathComponent("storage")
            .appendingPathComponent("v1")
            .appendingPathComponent("object")
            .appendingPathComponent("wallpaper-bundles")
            .appendingPathComponent(userId)
            .appendingPathComponent("\(wallpaperId).bundle.zip")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    func getWallpaperPreviewURL(wallpaper: WallpaperTable) -> URL {
        let userId = wallpaper.userId.uuidString.lowercased()
        let wallpaperId = wallpaper.id.uuidString.lowercased()

        let url = supabaseUrl
            .appendingPathComponent("storage")
            .appendingPathComponent("v1")
            .appendingPathComponent("object")
            .appendingPathComponent("public")
            .appendingPathComponent("wallpaper-previews")
            .appendingPathComponent(userId)
            .appendingPathComponent(wallpaperId)
            .appendingPathComponent("preview.gif")

        Logger.info("Preview URL build userId=\(userId), wallpaperId=\(wallpaperId), url=\(url.absoluteString)")
        return url
    }

    private func invokeEdgeFunction<Response: Decodable, Body: Encodable>(name: String, body: Body) async throws -> Response {
        Logger.info("[EdgeFunction] Start invoke name=\(name)")

        let endpoint = supabaseUrl.appendingPathComponent("functions/v1/\(name)")
        Logger.info("[EdgeFunction] Request endpoint=\(endpoint.absoluteString)")

        func sendOnce(accessToken: String) async throws -> (Data, HTTPURLResponse) {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("codelume-app/1", forHTTPHeaderField: "X-Client-Info")
            // Supabase Edge Functions 网关要求 apikey 头用于识别项目；缺失时可能出现 NOT_FOUND / Invalid JWT
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(body)
            let headerKeys = Array((request.allHTTPHeaderFields ?? [:]).keys).sorted()
            Logger.info("[EdgeFunction] Prepared headers keys=\(headerKeys), hasApikey=\(request.value(forHTTPHeaderField: "apikey") != nil), hasAuthorization=\(request.value(forHTTPHeaderField: "Authorization") != nil), name=\(name)")
            Logger.info("[EdgeFunction] Request body encoded bytes=\(request.httpBody?.count ?? 0), name=\(name)")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                Logger.error("[EdgeFunction] Non-HTTP response for name=\(name)")
                throw NSError(domain: "SupabaseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid edge function response"])
            }
            return (data, http)
        }

        // 首次尝试：用当前 session token
        var accessToken = try await validAccessToken()
        var (data, httpResponse) = try await sendOnce(accessToken: accessToken)
        Logger.info("[EdgeFunction] HTTP status=\(httpResponse.statusCode), name=\(name)")

        // 若 token 失效，刷新 session 并重试一次（不吞错，便于定位）
        if httpResponse.statusCode == 401 {
            Logger.warning("[EdgeFunction] 401 received, refreshing session and retrying. name=\(name)")
            do {
                _ = try await client.auth.refreshSession()
            } catch {
                Logger.error("[EdgeFunction] refreshSession failed. name=\(name), error=\(error.localizedDescription)")
                throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Auth refresh failed. Please sign in again."])
            }
            accessToken = try await validAccessToken()
            (data, httpResponse) = try await sendOnce(accessToken: accessToken)
            Logger.info("[EdgeFunction] Retry HTTP status=\(httpResponse.statusCode), name=\(name)")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            var errorMessage = String(data: data, encoding: .utf8) ?? "Edge function failed"
            if httpResponse.statusCode == 401, let payload = JWTParse.decodePayload(accessToken) {
                let iss = (payload["iss"] as? String) ?? "<nil>"
                let exp = (payload["exp"] as? Double).map { String(format: "%.0f", $0) } ?? "<nil>"
                let now = String(format: "%.0f", Date().timeIntervalSince1970)
                let expectedIss = supabaseUrl.appendingPathComponent("auth/v1").absoluteString
                let apikeyLen = supabaseKey.count
                let authLen = accessToken.count
                let responseURL = (httpResponse.url?.absoluteString ?? "<nil>")
                errorMessage += "\n\n[debug] jwt.iss=\(iss)\n[debug] expectedIss=\(expectedIss)\n[debug] jwt.exp=\(exp)\n[debug] now=\(now)\n[debug] apikeyLen=\(apikeyLen)\n[debug] authorizationLen=\(authLen)\n[debug] responseURL=\(responseURL)"
            }
            Logger.error("[EdgeFunction] HTTP error status=\(httpResponse.statusCode), name=\(name), body=\(errorMessage)")
            throw NSError(domain: "SupabaseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            Logger.info("[EdgeFunction] Decode success name=\(name)")
            return decoded
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            Logger.error("[EdgeFunction] Decode failed name=\(name), error=\(error.localizedDescription), raw=\(raw)")
            throw error
        }
    }

    private func validAccessToken() async throws -> String {
        // 优先拿 session；若 token 即将过期则主动 refresh 一次
        var session = try await client.auth.session
        var token = session.accessToken

        if let payload = JWTParse.decodePayload(token),
           let exp = payload["exp"] as? Double {
            let now = Date().timeIntervalSince1970
            // 小于 60s 视为即将过期，提前刷新，避免 Edge Functions 网关直接拒绝
            if exp - now < 60 {
                Logger.info("[Auth] access token near expiry; refreshing session.")
                _ = try await client.auth.refreshSession()
                session = try await client.auth.session
                token = session.accessToken
            }
        }

        // 避免“换 Supabase 项目但 Keychain 里还留着旧 token”导致 Edge Functions 报 Invalid JWT
        if let payload = JWTParse.decodePayload(token),
           let iss = payload["iss"] as? String,
           let issURL = URL(string: iss) {
            let expectedAuthBase = supabaseUrl.appendingPathComponent("auth/v1").absoluteString
            let issBase = issURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let expectedBase = expectedAuthBase.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

            if issBase != expectedBase {
                Logger.error("[Auth] JWT issuer mismatch. iss=\(issBase), expected=\(expectedBase). Signing out.")
                try? await client.auth.signOut()
                throw NSError(
                    domain: "SupabaseError",
                    code: 401,
                    userInfo: [NSLocalizedDescriptionKey: "Auth session is for a different Supabase project. Please sign in again."]
                )
            }
        }

        return token
    }

    // MARK: - Wallpaper Hub (filters / search)

    func getWallpapersForHub(
        page: Int,
        limit: Int,
        orderColumn: String,
        ascending: Bool,
        categorySlug: String?,
        nameContains: String?,
        freeOnly: Bool,
        paidOnly: Bool
    ) async throws -> [WallpaperTable] {
        var query = client.from("wallpapers")
            .select()
            .eq("is_approved", value: true)

        if let s = categorySlug?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            query = query.eq("category_slug", value: s)
        }
        if let n = nameContains?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
            let escaped = n.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "%", with: "\\%")
                .replacingOccurrences(of: "_", with: "\\_")
            query = query.ilike("name", value: "%\(escaped)%")
        }
        if freeOnly {
            query = query.eq("credits_cost", value: 0)
        } else if paidOnly {
            query = query.gt("credits_cost", value: 0)
        }

        let wallpapers: [WallpaperTable] = try await query
            .order(orderColumn, ascending: ascending)
            .range(from: (page - 1) * limit, to: page * limit - 1)
            .execute()
            .value
        return wallpapers
    }

    func getPurchasedWallpaperIds() async throws -> [UUID] {
        guard let user = try await getCurrentUser() else {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }
        struct Row: Decodable {
            let wallpaperId: UUID
            enum CodingKeys: String, CodingKey {
                case wallpaperId = "wallpaper_id"
            }
        }
        let rows: [Row] = try await client
            .from("wallpaper_entitlements")
            .select("wallpaper_id")
            .eq("user_id", value: user.id)
            .execute()
            .value
        return rows.map(\.wallpaperId)
    }

    func fetchWallpapersByIds(_ ids: [UUID]) async throws -> [WallpaperTable] {
        guard !ids.isEmpty else { return [] }
        let chunkSize = 80
        var out: [WallpaperTable] = []
        var offset = 0
        while offset < ids.count {
            let slice = Array(ids[offset..<min(offset + chunkSize, ids.count)])
            let part: [WallpaperTable] = try await client
                .from("wallpapers")
                .select()
                .eq("is_approved", value: true)
                .in("id", values: slice)
                .execute()
                .value
            out.append(contentsOf: part)
            offset += chunkSize
        }
        return out
    }

    /// 用于「已购买」/「标签搜索」等先得到 id 集合的场景：后续筛选/排序/分页仍全部由数据库执行。
    func getWallpapersForHubByIds(
        ids: [UUID],
        page: Int,
        limit: Int,
        orderColumn: String,
        ascending: Bool,
        categorySlug: String?,
        nameContains: String?,
        freeOnly: Bool,
        paidOnly: Bool
    ) async throws -> [WallpaperTable] {
        guard !ids.isEmpty else { return [] }

        var query = client.from("wallpapers")
            .select()
            .eq("is_approved", value: true)
            .in("id", values: ids)

        if let s = categorySlug?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            query = query.eq("category_slug", value: s)
        }
        if let n = nameContains?.trimmingCharacters(in: .whitespacesAndNewlines), !n.isEmpty {
            let escaped = n.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "%", with: "\\%")
                .replacingOccurrences(of: "_", with: "\\_")
            query = query.ilike("name", value: "%\(escaped)%")
        }
        if freeOnly {
            query = query.eq("credits_cost", value: 0)
        } else if paidOnly {
            query = query.gt("credits_cost", value: 0)
        }

        let wallpapers: [WallpaperTable] = try await query
            .order(orderColumn, ascending: ascending)
            .range(from: (page - 1) * limit, to: page * limit - 1)
            .execute()
            .value
        return wallpapers
    }

    /// 依赖表 `tags`、`wallpaper_tags`；缺失时返回空数组
    func wallpaperIdsMatchingTagSearch(_ raw: String) async throws -> [UUID] {
        let q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        let pattern = "%\(q.replacingOccurrences(of: "%", with: "\\%").replacingOccurrences(of: "_", with: "\\_"))%"
        do {
            let tags: [TagTable] = try await client
                .from("tags")
                .select()
                .ilike("name", value: pattern)
                .execute()
                .value
            let tagIds = tags.map(\.id)
            guard !tagIds.isEmpty else { return [] }
            struct Row: Decodable {
                let wallpaperId: UUID
                enum CodingKeys: String, CodingKey {
                    case wallpaperId = "wallpaper_id"
                }
            }
            var all: [UUID] = []
            var j = 0
            let batch = 50
            while j < tagIds.count {
                let slice = Array(tagIds[j..<min(j + batch, tagIds.count)])
                let rows: [Row] = try await client
                    .from("wallpaper_tags")
                    .select("wallpaper_id")
                    .in("tag_id", values: slice)
                    .execute()
                    .value
                all.append(contentsOf: rows.map(\.wallpaperId))
                j += batch
            }
            return Array(Set(all))
        } catch {
            Logger.warning("Tag search unavailable: \(error.localizedDescription)")
            return []
        }
    }

    /// 批量查询壁纸标签（用于列表展示）；`display_name` 优先，否则 `name`
    func getTagLabelsForWallpaperIds(_ wallpaperIds: [UUID]) async throws -> [UUID: [String]] {
        guard !wallpaperIds.isEmpty else { return [:] }
        struct TagEmbed: Decodable {
            let name: String
            let displayName: String?
            enum CodingKeys: String, CodingKey {
                case name
                case displayName = "display_name"
            }
        }
        struct Row: Decodable {
            let wallpaperId: UUID
            let tags: TagEmbed?
            enum CodingKeys: String, CodingKey {
                case wallpaperId = "wallpaper_id"
                case tags
            }
        }
        var map: [UUID: [String]] = [:]
        let batchSize = 40
        var offset = 0
        while offset < wallpaperIds.count {
            let slice = Array(wallpaperIds[offset..<min(offset + batchSize, wallpaperIds.count)])
            let rows: [Row] = try await client
                .from("wallpaper_tags")
                .select("wallpaper_id, tags(name, display_name)")
                .in("wallpaper_id", values: slice)
                .execute()
                .value
            for row in rows {
                guard let t = row.tags else { continue }
                let d = t.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let label = d.isEmpty ? t.name : d
                if label.isEmpty { continue }
                var list = map[row.wallpaperId] ?? []
                if !list.contains(label) { list.append(label) }
                map[row.wallpaperId] = list
            }
            offset += batchSize
        }
        return map
    }

    func getActiveCategories() async throws -> [WallpaperHubFilterModel.CategoryOption] {
        struct Row: Decodable {
            let name: String
            let displayName: String
            let isActive: Bool
            enum CodingKeys: String, CodingKey {
                case name
                case displayName = "display_name"
                case isActive = "is_active"
            }
        }
        let rows: [Row] = try await client
            .from("categories")
            .select("name, display_name, is_active")
            .eq("is_active", value: true)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows.map { .init(slug: $0.name, displayName: $0.displayName) }
    }
}
