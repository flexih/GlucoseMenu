//
//  PurchaseManager.swift
//  LibreMenu
//

import Foundation
import RevenueCat

@Observable
@MainActor
final class PurchaseManager {
  static let shared = PurchaseManager()

  private(set) var isSubscribed = AppGroups.subscriptionActive
  private(set) var activeProductIdentifiers: Set<String> = []
  private(set) var currentOffering: Offering?
  private(set) var isPurchasing = false
  var errorMessage = ""

  private init() {}

  static func configure() {
		Purchases.proxyURL = URL(string: "https://api.rc-backup.com/")!
		#if DEBUG && false
		Purchases.configure(withAPIKey: "test_eAVNJOnKZWNZDPKbbhWipBjbSDt")
		#else
		Purchases.configure(withAPIKey: "appl_hJooINmPlzQNvpXYpsHgkLiLGkB")
		#endif
    #if DEBUG
    Purchases.logLevel = .warn
    #endif
  }

  func checkStatus() async {
    do {
      let info = try await Purchases.shared.customerInfo()
      apply(info)
    } catch {}
  }

  func fetchOffering() async {
    do {
      let offerings = try await Purchases.shared.offerings()
      currentOffering = offerings.current
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func purchase(_ package: Package) async {
    guard !isPurchasing else { return }
    isPurchasing = true
    errorMessage = ""
    defer { isPurchasing = false }
    do {
      let result = try await Purchases.shared.purchase(package: package)
      if !result.userCancelled {
        apply(result.customerInfo)
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func restorePurchases() async {
    guard !isPurchasing else { return }
    isPurchasing = true
    errorMessage = ""
    defer { isPurchasing = false }
    do {
      let info = try await Purchases.shared.restorePurchases()
      apply(info)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func apply(_ info: CustomerInfo) {
    let entitlement = info.entitlements["pro"]
    let active = entitlement?.isActive == true
    isSubscribed = active
    AppGroups.subscriptionActive = active
    if let productId = entitlement?.productIdentifier, active {
      activeProductIdentifiers = [productId]
    } else {
      activeProductIdentifiers = []
    }
  }
}
