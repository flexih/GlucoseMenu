//
//  PaywallScreen.swift
//  LibreMenu
//

import RevenueCat
import SwiftUI

struct PaywallScreen: View {
  @Environment(\.dismiss) private var dismiss
  @State private var purchaseManager = PurchaseManager.shared

  var body: some View {
		VStack(spacing: 0) {
			header
			content
			footer
		}
		.frame(width: 340)
		.navigationTitle("")
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				Menu {
					Link("Privacy Policy", destination: URL(string: "https://www.floattower.tech/privacy-en-glucosemenu.html")!)
					Link("Terms of Use", destination: URL(string: "https://www.floattower.tech/terms-en-glucosemenu.html")!)
				} label: {
					Image(systemName: "ellipsis")
				}
			}
		}
		.task {
			async let _ = purchaseManager.fetchOffering()
			async let _ = purchaseManager.checkStatus()
		}
  }

  private var header: some View {
    VStack(spacing: 6) {
      Image(systemName: purchaseManager.isSubscribed ? "star.circle.fill" : "star.circle")
        .font(.system(size: 44))
        .foregroundStyle(.yellow)
      Text(purchaseManager.isSubscribed ? "You're on Pro" : "Upgrade to Pro")
        .font(.title2.bold())
      Text(purchaseManager.isSubscribed ? "Thank you for your support" : "Unlock all premium features")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
		.padding()
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 12) {
      FeatureRow(icon: "menubar.rectangle", text: "Track your glucose on menu bar in real time")
      FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced glucose charts")
      FeatureRow(icon: "arrow.clockwise", text: "Continuous updates & new features")
    }
		.padding()
  }

  @ViewBuilder
  private var packagesSection: some View {
    if purchaseManager.isPurchasing {
      ProgressView()
        .frame(maxWidth: .infinity)
    } else if let offering = purchaseManager.currentOffering {
      VStack(spacing: 8) {
        ForEach(offering.availablePackages, id: \.identifier) { package in
          let isActive = purchaseManager.activeProductIdentifiers.contains(package.storeProduct.productIdentifier)
          PackageRow(package: package, isActive: isActive) {
            Task { await purchaseManager.purchase(package) }
          }
        }
      }
			.padding(.horizontal)
    } else {
      Text("No offerings available")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }
  }

  private var footer: some View {
    VStack(spacing: 0) {
      packagesSection

      if !purchaseManager.errorMessage.isEmpty {
        Text(purchaseManager.errorMessage)
          .font(.caption)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
					.padding([.top, .horizontal])
					.fixedSize(horizontal: false, vertical: true)
      }

      HStack {
        Button("Restore Purchases") {
          Task { await purchaseManager.restorePurchases() }
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
        .disabled(purchaseManager.isPurchasing)

        Spacer()

        Button("Close") { dismiss() }
          .buttonStyle(.plain)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
			.padding()
    }
  }
}

private struct FeatureRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .frame(width: 22)
			Text(text.localized())
        .font(.subheadline)
    }
  }
}

private struct PackageRow: View {
  let package: RevenueCat.Package
  let isActive: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(package.storeProduct.localizedTitle)
            .font(.subheadline.bold())
          Text(package.storeProduct.localizedDescription)
            .font(.caption)
            .foregroundStyle(isActive ? .primary : .secondary)
        }
        Spacer()
        if isActive {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
        }
        Text(package.storeProduct.localizedPriceString)
          .font(.subheadline.bold())
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(isActive ? AnyShapeStyle(.tint.opacity(0.12)) : AnyShapeStyle(.fill.tertiary))
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .strokeBorder(isActive ? Color.accentColor : Color.clear, lineWidth: 1.5)
      )
    }
    .buttonStyle(.plain)
  }
}

