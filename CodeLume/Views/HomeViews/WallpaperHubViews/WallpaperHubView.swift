import SwiftUI
import ImageIO

struct WallpaperHubView: View {
    @EnvironmentObject private var filters: WallpaperHubFilterModel
    @State private var wallpapers: [WallpaperTable] = []
    @State private var hubIdFilter: [UUID] = []
    @State private var isUsingIdFilter = false

    @State private var videoInfoByWallpaperId: [UUID: WallpaperVideoInfoTable] = [:]
    @State private var tagLabelsByWallpaperId: [UUID: [String]] = [:]
    @State private var loadingVideoInfoIds: Set<UUID> = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var currentPage = 1
    @State private var hasMorePages = true

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private let pageSize = 20

    @ObservedObject private var supabase = SupabaseManager.shared

    var body: some View {
        Group {
            if isLoading {
                ProgressView(String(localized: "Loading..."))
            } else if !supabase.isAuthenticated {
                ContentUnavailableView(
                    String(localized: "Sign in to access the Wallpaper Hub."),
                    systemImage: "photo.on.rectangle.angled"
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                                wallpaperCard(wallpaper)
                                    .onAppear {
                                        Task { await loadMoreIfNeeded(currentWallpaperID: wallpaper.id, filteredIndex: index) }
                                    }
                            }

                            if isLoadingMore {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .gridCellColumns(columns.count)
                            }
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task(id: supabase.isAuthenticated) {
            if supabase.isAuthenticated {
                if filters.categoryOptions.isEmpty {
                    filters.categoryOptions = (try? await supabase.getActiveCategories()) ?? []
                }
                await loadInitialWallpapers()
            } else {
                wallpapers = []
                hubIdFilter = []
                isUsingIdFilter = false
                videoInfoByWallpaperId = [:]
                tagLabelsByWallpaperId = [:]
                loadingVideoInfoIds = []
                currentPage = 1
                hasMorePages = true
            }
        }
        .onChange(of: filters.queryFingerprint) { _, _ in
            guard supabase.isAuthenticated else { return }
            Task { await loadInitialWallpapers() }
        }
        .onAppear {
            filters.isWallpaperHubDetailVisible = true
        }
        .onDisappear {
            filters.isWallpaperHubDetailVisible = false
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    @ViewBuilder
    private func wallpaperCard(_ wallpaper: WallpaperTable) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            PreviewWallpaperGIF(url: supabase.getWallpaperPreviewURL(wallpaper: wallpaper))
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                Text(wallpaper.name)
                    .font(.headline)
                    .lineLimit(1)

                WallpaperTypeLabel(type: wallpaper.wallpaperType)


                if let tags = tagLabelsByWallpaperId[wallpaper.id], !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                                HStack(spacing: 3) {
                                    Text("#" + tag)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }

                Spacer()

                Text(wallpaper.author.isEmpty ? String(localized: "Unknown Author") : wallpaper.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if isVideoWallpaper(wallpaper) {
                WallpaperVideoInfoInline(
                    info: videoInfoByWallpaperId[wallpaper.id],
                    isLoading: loadingVideoInfoIds.contains(wallpaper.id)
                )
                .task(id: wallpaper.id) {
                    await loadVideoInfoIfNeeded(for: wallpaper)
                }
            }

            Text(wallpaper.description.isEmpty ? String(localized: "No description") : wallpaper.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)

            ServerWallpaperPurchaseView(wallpaper: wallpaper)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private func isVideoWallpaper(_ wallpaper: WallpaperTable) -> Bool {
        wallpaper.wallpaperType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "video"
    }

    @MainActor
    private func fetchTagsForWallpapers(_ ids: [UUID]) async {
        let missing = ids.filter { tagLabelsByWallpaperId[$0] == nil }
        guard !missing.isEmpty else { return }
        do {
            let m = try await supabase.getTagLabelsForWallpaperIds(missing)
            for (k, v) in m {
                tagLabelsByWallpaperId[k] = normalizeTagLabels(v)
            }
            for id in missing where tagLabelsByWallpaperId[id] == nil {
                tagLabelsByWallpaperId[id] = []
            }
        } catch {
            for id in missing {
                tagLabelsByWallpaperId[id] = []
            }
            Logger.warning("Wallpaper tags load failed: \(error.localizedDescription)")
        }
    }

    private func normalizeTagLabels(_ tags: [String]) -> [String] {
        tags
            .map { rawTag in
                var cleaned = rawTag.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.lowercased().hasPrefix("tag.") {
                    cleaned.removeFirst(4)
                }
                return cleaned
            }
            .filter { !$0.isEmpty }
    }

    @MainActor
    private func loadVideoInfoIfNeeded(for wallpaper: WallpaperTable) async {
        guard isVideoWallpaper(wallpaper) else { return }
        guard videoInfoByWallpaperId[wallpaper.id] == nil else { return }
        guard !loadingVideoInfoIds.contains(wallpaper.id) else { return }

        loadingVideoInfoIds.insert(wallpaper.id)
        defer { loadingVideoInfoIds.remove(wallpaper.id) }

        do {
            let info = try await supabase.getWallpaperVideoInfo(wallpaperId: wallpaper.id)
            if let info {
                videoInfoByWallpaperId[wallpaper.id] = info
            }
        } catch {
            guard !(error is CancellationError) else { return }
            let nsError = error as NSError
            guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }
            Logger.warning("Load wallpaper_video_info failed: \(error.localizedDescription)")
        }
    }

    private func loadInitialWallpapers() async {
        isLoading = true
        defer { isLoading = false }
        currentPage = 1
        hasMorePages = true
        videoInfoByWallpaperId = [:]
        tagLabelsByWallpaperId = [:]
        loadingVideoInfoIds = []
        hubIdFilter = []
        isUsingIdFilter = false

        let purchased = filters.purchasedOnly
        let tagQ = filters.tagSearch.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            var ids: [UUID] = []
            if purchased {
                ids = try await supabase.getPurchasedWallpaperIds()
            }
            if !tagQ.isEmpty {
                let tagIds = try await supabase.wallpaperIdsMatchingTagSearch(tagQ)
                if purchased {
                    let set = Set(tagIds)
                    ids = ids.filter { set.contains($0) }
                } else {
                    ids = tagIds
                }
            }

            if purchased || !tagQ.isEmpty {
                isUsingIdFilter = true
                hubIdFilter = ids
                let list = try await supabase.getWallpapersForHubByIds(
                    ids: ids,
                    page: 1,
                    limit: pageSize,
                    orderColumn: filters.orderColumn,
                    ascending: filters.sortAscending,
                    categorySlug: filters.useCategoryFilter ? filters.categorySlug : nil,
                    nameContains: filters.nameSearch.isEmpty ? nil : filters.nameSearch,
                    freeOnly: filters.freeOnly,
                    paidOnly: filters.paidOnly
                )
                wallpapers = list
                hasMorePages = list.count == pageSize
                await fetchTagsForWallpapers(list.map(\.id))
            } else {
                let list = try await supabase.getWallpapersForHub(
                    page: 1,
                    limit: pageSize,
                    orderColumn: filters.orderColumn,
                    ascending: filters.sortAscending,
                    categorySlug: filters.useCategoryFilter ? filters.categorySlug : nil,
                    nameContains: filters.nameSearch.isEmpty ? nil : filters.nameSearch,
                    freeOnly: filters.freeOnly,
                    paidOnly: filters.paidOnly
                )
                wallpapers = list
                hasMorePages = list.count == pageSize
                await fetchTagsForWallpapers(list.map(\.id))
            }
        } catch {
            guard !(error is CancellationError) else { return }
            let nsError = error as NSError
            guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }
            Alert(title: "Load failed", dynamicMessage: error.localizedDescription)
        }
    }

    private func loadMoreIfNeeded(currentWallpaperID: UUID, filteredIndex: Int) async {
        guard hasMorePages, !isLoading, !isLoadingMore else { return }
        guard filteredIndex >= wallpapers.count - 4 else { return }

        guard let sourceIndex = wallpapers.firstIndex(where: { $0.id == currentWallpaperID }) else { return }
        let nearEnd = sourceIndex >= wallpapers.count - 6
        let hasFilters = filters.useCategoryFilter || filters.categorySlug != nil
            || !filters.nameSearch.isEmpty || filters.freeOnly || filters.paidOnly
        guard nearEnd || hasFilters else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let next: [WallpaperTable]
            if isUsingIdFilter {
                next = try await supabase.getWallpapersForHubByIds(
                    ids: hubIdFilter,
                    page: nextPage,
                    limit: pageSize,
                    orderColumn: filters.orderColumn,
                    ascending: filters.sortAscending,
                    categorySlug: filters.useCategoryFilter ? filters.categorySlug : nil,
                    nameContains: filters.nameSearch.isEmpty ? nil : filters.nameSearch,
                    freeOnly: filters.freeOnly,
                    paidOnly: filters.paidOnly
                )
            } else {
                next = try await supabase.getWallpapersForHub(
                    page: nextPage,
                    limit: pageSize,
                    orderColumn: filters.orderColumn,
                    ascending: filters.sortAscending,
                    categorySlug: filters.useCategoryFilter ? filters.categorySlug : nil,
                    nameContains: filters.nameSearch.isEmpty ? nil : filters.nameSearch,
                    freeOnly: filters.freeOnly,
                    paidOnly: filters.paidOnly
                )
            }
            wallpapers.append(contentsOf: next)
            currentPage = nextPage
            hasMorePages = next.count == pageSize
            await fetchTagsForWallpapers(next.map(\.id))
        } catch {
            guard !(error is CancellationError) else { return }
            let nsError = error as NSError
            guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }
            Alert(title: "Load failed", dynamicMessage: error.localizedDescription)
        }
    }
}

#Preview {
    WallpaperHubView()
        .environmentObject(WallpaperHubFilterModel())
}
