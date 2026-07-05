//
//  StoreManager.swift
//  The Clock School
//
//  Created by Sebastian Strus on 7/5/26.
//

import Foundation
import Combine
import StoreKit

@MainActor
final class StoreManager: ObservableObject {

    static let shared = StoreManager()

    nonisolated static let premiumProductID = "com.sebastianstrus.theclockschool.premium"
    private let purchasedKey = "isPremiumPurchased"

    @Published private(set) var premiumProduct: Product?
    @Published private(set) var isPremium: Bool
    @Published private(set) var isPurchasing: Bool = false
    @Published var purchaseError: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        self.isPremium = UserDefaults.standard.bool(forKey: purchasedKey)
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Locking

    func isCategoryUnlocked(_ category: TaskCategory) -> Bool {
        if category.difficulty == .easy { return true }
        return isPremium
    }

    // MARK: - Loading

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            self.premiumProduct = products.first
        } catch {
            self.purchaseError = error.localizedDescription
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product = premiumProduct else {
            await loadProducts()
            guard premiumProduct != nil else {
                purchaseError = "Product unavailable. Please try again later.".localized
                return
            }
            await purchase()
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                setPremium(true)
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Restore

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPremium {
                purchaseError = "No previous purchases found.".localized
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        setPremium(owned)
    }

    private func setPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: purchasedKey)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try await self.checkVerified(result)
                    if transaction.productID == StoreManager.premiumProductID,
                       transaction.revocationDate == nil {
                        await MainActor.run { self.setPremium(true) }
                    }
                    await transaction.finish()
                } catch {
                    await MainActor.run { self.purchaseError = error.localizedDescription }
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed.".localized
        }
    }
}
