import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    var storeManager = StoreManager.shared

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    productsSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    purchaseButton
                    restoreButton
                    termsSection
                }
                .padding()
            }
            .navigationTitle("æstel Pro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if storeManager.products.isEmpty {
                    await storeManager.loadProducts()
                }
                // Default select yearly
                selectedProduct = storeManager.yearlyProduct ?? storeManager.products.first
            }
            #if os(macOS)
            .frame(minWidth: 380, idealWidth: 420, minHeight: 500, idealHeight: 600)
            #endif
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow.gradient)

            Text("Unlock Everything")
                .font(.title.bold())

            Text("Take your reading to the next level")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(icon: "books.vertical.fill", color: .blue,
                       title: "Unlimited Books",
                       subtitle: "Free plan limited to \(StoreManager.freeBookLimit) books")
            featureRow(icon: "medal.fill", color: .yellow,
                       title: "All Badges",
                       subtitle: "Unlock all 29 achievement badges")
            featureRow(icon: "chart.bar.fill", color: .purple,
                       title: "Advanced Statistics",
                       subtitle: "Reading speed, trends & insights")
            featureRow(icon: "app.fill", color: .green,
                       title: "Custom App Icons",
                       subtitle: "Choose from 6 beautiful icon styles")
            featureRow(icon: "note.text", color: .orange,
                       title: "Unlimited Notes",
                       subtitle: "Free plan limited to 3 notes per book")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func featureRow(icon: String, color: Color, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Products

    private var productsSection: some View {
        VStack(spacing: 10) {
            if storeManager.isLoadingProducts {
                ProgressView()
                    .padding()
            } else if let error = storeManager.loadProductsError {
                VStack(spacing: 8) {
                    Text("Failed to load products")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Button("Retry") {
                        Task { await storeManager.loadProducts() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if storeManager.products.isEmpty {
                Text("No products available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(storeManager.products) { product in
                    productCard(product)
                }
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let isYearly = product.id == StoreManager.yearlyID
        let isLifetime = product.id == StoreManager.lifetimeID

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(displayName(for: product))
                        .font(.subheadline.bold())
                    if isYearly {
                        Text("Best Value")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green, in: Capsule())
                    }
                    if isLifetime {
                        Text("One-Time")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange, in: Capsule())
                    }
                }
                if product.subscription != nil {
                    Text(subDescription(product: product))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(product.displayPrice)
                .font(.headline)
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 0 : 1)
        )
        .foregroundStyle(isSelected ? .white : .primary)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedProduct = product
            }
            HapticManager.selection()
        }
    }

    private func displayName(for product: Product) -> String {
        switch product.id {
        case StoreManager.monthlyID:  return String(localized: "Monthly")
        case StoreManager.yearlyID:   return String(localized: "Yearly")
        case StoreManager.lifetimeID: return String(localized: "Lifetime")
        default: return product.displayName
        }
    }

    private func subDescription(product: Product) -> String {
        if product.id == StoreManager.yearlyID {
            let monthly = product.price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceFormatStyle.locale
            let monthlyStr = formatter.string(from: monthly as NSDecimalNumber) ?? ""
            return String(localized: "\(monthlyStr)/month")
        }
        return ""
    }

    private var purchaseButtonLabel: LocalizedStringKey {
        guard let product = selectedProduct else { return "Continue" }
        if product.id == StoreManager.lifetimeID {
            return "Purchase"
        }
        return "Subscribe Now"
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            Task {
                isPurchasing = true
                errorMessage = nil
                do {
                    let result: StoreManager.PurchaseResult = try await storeManager.purchase(product)
                    switch result {
                    case .success:
                        HapticManager.notification(.success)
                        dismiss()
                    case .pending:
                        errorMessage = String(localized: "Purchase is pending approval. You'll get access once it's approved.")
                    case .cancelled:
                        break
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    HapticManager.notification(.error)
                }
                isPurchasing = false
            }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(purchaseButtonLabel)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(selectedProduct == nil || isPurchasing)
    }

    // MARK: - Restore

    @State private var isRestoring = false

    private var restoreButton: some View {
        Button {
            Task {
                isRestoring = true
                errorMessage = nil
                do {
                    try await storeManager.restorePurchases()
                    if storeManager.isPro {
                        HapticManager.notification(.success)
                        dismiss()
                    } else {
                        errorMessage = String(localized: "No previous purchases found.")
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    HapticManager.notification(.error)
                }
                isRestoring = false
            }
        } label: {
            if isRestoring {
                ProgressView()
            } else {
                Text("Restore Purchases")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(isRestoring)
    }

    // MARK: - Terms

    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Settings.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                if let termsURL = URL(string: "https://jasonyeyuhe.github.io/leaflet-reader/terms.html") {
                    Link("Terms of Use", destination: termsURL)
                }
                Text("·")
                if let privacyURL = URL(string: "https://jasonyeyuhe.github.io/leaflet-reader/privacy.html") {
                    Link("Privacy Policy", destination: privacyURL)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
