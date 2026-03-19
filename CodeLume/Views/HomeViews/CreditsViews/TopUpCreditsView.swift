import SwiftUI
import StoreKit

struct TopUpCreditsView: View {
    @StateObject private var iapManager = IAPManager.shared
    @ObservedObject private var supabase = SupabaseManager.shared

    @State private var creditsBalanceFallback: Int = 0
    @State private var isLoading = false
    @State private var hasInitialized = false
    @State private var balanceLoadFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(String(localized: "Credits Top Up"))
                .font(.title2.weight(.semibold))

            if !supabase.isAuthenticated {
                ContentUnavailableView(
                    String(localized: "Sign in to top up credits"),
                    systemImage: "person.crop.circle.badge.exclamationmark"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                balanceCard

                Text(String(localized: "Choose a package"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                if isLoading && iapManager.creditPackages.isEmpty {
                    ProgressView(String(localized: "Loading packages…"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // macOS 的 List 使用不透明表视图背景，与外层 .regularMaterial 割裂；用 ScrollView 继承父级视觉
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(packagesSortedByCredits.enumerated()), id: \.element.productId) { index, package in
                                packageRow(package: package)
                                    .padding(.vertical, 10)
                                if index < packagesSortedByCredits.count - 1 {
                                    Divider()
                                        .opacity(0.35)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 200, maxHeight: 360)
                }
            }

            Spacer(minLength: 0)
        }
        .aboutSectionCard()
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .task(id: supabase.isAuthenticated) {
            guard supabase.isAuthenticated else {
                creditsBalanceFallback = 0
                balanceLoadFailed = false
                return
            }

            guard !hasInitialized else {
                await refreshBalance()
                return
            }
            hasInitialized = true

            isLoading = true
            defer { isLoading = false }

            await refreshBalance()
            await iapManager.loadCreditProducts()
        }
    }

    @ViewBuilder
    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Current balance"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if balanceIsLoading {
                    ProgressView()
                        .controlSize(.regular)
                    Text(String(localized: "Loading balance…"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else if balanceLoadFailed && supabase.creditsBalance == nil {
                    Text("—")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.tertiary)
                    Text(String(localized: "Balance unavailable"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(balanceNumberText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    Text(String(localized: "Credits"))
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "Current balance"))
            .accessibilityValue(balanceAccessibilityValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.secondary.opacity(0.2), lineWidth: 1)
                }
        }
    }

    private var balanceIsLoading: Bool {
        supabase.isAuthenticated
            && supabase.isCreditsLoading
            && supabase.creditsBalance == nil
            && creditsBalanceFallback == 0
            && !balanceLoadFailed
    }

    private var balanceNumberText: String {
        if let b = supabase.creditsBalance {
            return "\(b)"
        }
        return "\(creditsBalanceFallback)"
    }

    private var balanceAccessibilityValue: String {
        if balanceIsLoading { return String(localized: "Loading balance…") }
        if balanceLoadFailed && supabase.creditsBalance == nil { return String(localized: "Balance unavailable") }
        return "\(balanceNumberText) \(String(localized: "Credits"))"
    }

    private var packagesSortedByCredits: [CreditPackageTable] {
        iapManager.creditPackages.sorted(by: { $0.credits < $1.credits })
    }

    @ViewBuilder
    private func packageRow(package: CreditPackageTable) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(package.credits) \(String(localized: "Credits"))")
                    .font(.headline)
                Text(package.productId)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let product = iapManager.products.first(where: { $0.id == package.productId }) {
                Button {
                    Task { await purchase(product: product) }
                } label: {
                    Text(product.displayPrice)
                        .frame(minWidth: 64)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            } else {
                Text("--")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func refreshBalance() async {
        balanceLoadFailed = false
        await supabase.refreshCreditsBalance()
        if supabase.creditsBalance != nil {
            creditsBalanceFallback = supabase.creditsBalance ?? 0
            return
        }
        do {
            creditsBalanceFallback = try await supabase.getUserCredits()
            await MainActor.run {
                supabase.creditsBalance = creditsBalanceFallback
                supabase.isCreditsLoading = false
            }
        } catch {
            balanceLoadFailed = true
        }
    }

    private func purchase(product: Product) async {
        isLoading = true
        defer { isLoading = false }

        let success = await iapManager.purchase(product: product)
        if success {
            await refreshBalance()
        } else if let message = iapManager.lastErrorMessage {
            Alert(title: "Purchase failed", dynamicMessage: message)
        }
    }
}

#Preview {
    NavigationStack {
        TopUpCreditsView()
    }
}

