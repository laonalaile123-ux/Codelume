//
//  Table.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/27.
//
import Foundation

struct UserTable: Codable {
    let id: UUID
    let email: String?
    let username: String
    let avatarUrl: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WallpaperTable: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let description: String
    let author: String
    let authorEmail: String
    let wallpaperType: String
    /// 后端字段：`category_slug`（例如 nature / city / other）
    let categorySlug: String
    let bundleSizeMB: Decimal
    let totalDownloads: Int
    let totalPurchases: Int
    let creditsCost: Int
    let isApproved: Bool
    let bundleSHA256: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case author
        case authorEmail = "author_email"
        case wallpaperType = "type"
        case categorySlug = "category_slug"
        case bundleSizeMB = "bundle_size_mb"
        case totalDownloads = "total_downloads"
        case totalPurchases = "total_purchases"
        case creditsCost = "credits_cost"
        case isApproved = "is_approved"
        case bundleSHA256 = "bundle_sha256"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreditPackageTable: Codable, Identifiable {
    let id: UUID
    let productId: String
    let credits: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case credits
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserBalanceTable: Codable {
    let userId: UUID
    let credits: Int
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case credits
        case updatedAt = "updated_at"
    }
}

struct PurchaseTransactionTable: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let transactionId: String
    let originalTransactionId: String?
    let productId: String
    let creditsGranted: Int
    let status: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case productId = "product_id"
        case creditsGranted = "credits_granted"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WallpaperEntitlementTable: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let wallpaperId: UUID
    let source: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case wallpaperId = "wallpaper_id"
        case source
        case createdAt = "created_at"
    }
}

struct WallpaperVideoInfoTable: Codable {
    let wallpaperId: UUID
    let width: Int
    let height: Int
    /// 后端字段：`size_bytes`
    let sizeBytes: Int64
    let duration: Int
    let format: String
    let loop: Bool
    let isEncrypted: Bool
    /// 后端字段：`key_id`（仅当加密时存在）
    let keyId: String?

    /// 便于 UI 继续展示 MB
    var sizeMB: Decimal {
        Decimal(Double(max(sizeBytes, 0)) / 1024.0 / 1024.0)
    }

    var resolutionText: String {
        "\(width)x\(height)"
    }

    enum CodingKeys: String, CodingKey {
        case wallpaperId = "wallpaper_id"
        case width
        case height
        case sizeBytes = "size_bytes"
        case duration = "duration"
        case format
        case loop
        case isEncrypted = "is_encrypted"
        case keyId = "key_id"
    }
}

struct Download: Codable {
    let id: Int
    let userId: UUID
    let wallpaperId: UUID
    let amount: Double
    let serviceFee: Double
    let status: String
    let createdAt: Date
    let completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case wallpaperId = "wallpaper_id"
        case amount
        case serviceFee = "service_fee"
        case status
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}

struct Payment: Codable {
    let id: String
    let userId: UUID
    let downloadId: Int
    let amount: Double
    let currency: String
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case downloadId = "download_id"
        case amount
        case currency
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Follow: Codable {
    let id: Int
    let followerId: UUID
    let followingId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
    }
}

/// `tags` 表（壁纸标签）；与 `wallpaper_tags` 关联
struct TagTable: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
}
