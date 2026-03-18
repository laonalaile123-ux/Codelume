import Foundation
import SwiftUI

/// 壁纸中心侧边栏筛选状态（与详情区 `WallpaperHubView` 共享）
@MainActor
final class WallpaperHubFilterModel: ObservableObject {
    /// 由 `WallpaperHubView` onAppear/onDisappear 更新，供侧栏显示筛选区
    @Published var isWallpaperHubDetailVisible: Bool = false
    @Published var categoryOptions: [Int] = []

    @Published var nameSearch: String = ""
    @Published var tagSearch: String = ""
    @Published var purchasedOnly: Bool = false
    /// 勾选「分类」后才按分类筛选
    @Published var useCategoryFilter: Bool = false
    @Published var categoryId: Int? = nil
    @Published var freeOnly: Bool = false
    @Published var paidOnly: Bool = false

    @Published var sortByDownloads: Bool = false
    @Published var sortByPurchases: Bool = false
    @Published var sortByPrice: Bool = false
    @Published var sortAscending: Bool = false

    /// 用于触发列表重载（Equatable 指纹）
    var queryFingerprint: String {
        [
            nameSearch,
            tagSearch,
            "\(purchasedOnly)",
            "\(useCategoryFilter)",
            "\(categoryId.map(String.init) ?? "")",
            "\(freeOnly)",
            "\(paidOnly)",
            "\(sortByDownloads)",
            "\(sortByPurchases)",
            "\(sortByPrice)",
            "\(sortAscending)"
        ].joined(separator: "|")
    }

    var orderColumn: String {
        if sortByDownloads { return "total_downloads" }
        if sortByPurchases { return "total_purchases" }
        if sortByPrice { return "credits_cost" }
        return "created_at"
    }

    func setSortDownloads(_ on: Bool) {
        sortByDownloads = on
        if on {
            sortByPurchases = false
            sortByPrice = false
        }
    }

    func setSortPurchases(_ on: Bool) {
        sortByPurchases = on
        if on {
            sortByDownloads = false
            sortByPrice = false
        }
    }

    func setSortPrice(_ on: Bool) {
        sortByPrice = on
        if on {
            sortByDownloads = false
            sortByPurchases = false
        }
    }

    var needsClientSideMode: Bool {
        purchasedOnly || !tagSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
