import SwiftUI

/// 壁纸中心专用侧边栏筛选（宽度与导航栏一致，内容可滚动）
struct WallpaperHubSidebarFiltersView: View {
    @ObservedObject var filters: WallpaperHubFilterModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Hub filters"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(String(localized: "Search by name"), text: $filters.nameSearch)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            TextField(String(localized: "Search by tag"), text: $filters.tagSearch)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            Toggle(String(localized: "Purchased only"), isOn: $filters.purchasedOnly)
                .font(.caption)
                .toggleStyle(.checkbox)

            Divider().opacity(0.4)

            Text(String(localized: "Sort by"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)

            Toggle(String(localized: "Downloads"), isOn: Binding(
                get: { filters.sortByDownloads },
                set: { filters.setSortDownloads($0) }
            ))
            .font(.caption)
            .toggleStyle(.checkbox)

            Toggle(String(localized: "Purchases"), isOn: Binding(
                get: { filters.sortByPurchases },
                set: { filters.setSortPurchases($0) }
            ))
            .font(.caption)
            .toggleStyle(.checkbox)

            Toggle(String(localized: "Price"), isOn: Binding(
                get: { filters.sortByPrice },
                set: { filters.setSortPrice($0) }
            ))
            .font(.caption)
            .toggleStyle(.checkbox)

            Toggle(String(localized: "Ascending order"), isOn: $filters.sortAscending)
                .font(.caption)
                .toggleStyle(.checkbox)

            Divider().opacity(0.4)

            Toggle(String(localized: "Filter by category"), isOn: $filters.useCategoryFilter)
                .font(.caption)
                .toggleStyle(.checkbox)

            if filters.useCategoryFilter {
                Picker(String(localized: "Category"), selection: Binding(
                    get: { filters.categoryId ?? -1 },
                    set: { filters.categoryId = $0 < 0 ? nil : $0 }
                )) {
                    Text(String(localized: "All categories")).tag(-1)
                    ForEach(filters.categoryOptions, id: \.self) { id in
                        Text("\(String(localized: "Category")) \(id)").tag(id)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Toggle(String(localized: "Free only"), isOn: Binding(
                get: { filters.freeOnly },
                set: { v in
                    filters.freeOnly = v
                    if v { filters.paidOnly = false }
                }
            ))
            .font(.caption)
            .toggleStyle(.checkbox)

            Toggle(String(localized: "Paid only"), isOn: Binding(
                get: { filters.paidOnly },
                set: { v in
                    filters.paidOnly = v
                    if v { filters.freeOnly = false }
                }
            ))
            .font(.caption)
            .toggleStyle(.checkbox)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
