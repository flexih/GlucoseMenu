//
//  AppGroups.swift
//  glu
//
//  Created by fanxinghua on 2025/5/8.
//

import Foundation

public enum AppGroups {
  public enum Environment: String, CaseIterable {
    case app
    case `extension`
  }

  public static var environment: Environment {
    return Bundle.main.bundlePath.hasSuffix(".app") ? .app : .extension
  }

  public static let name = "group.com.flexih.LibreMenu"
	public static let storage = UserDefaults.standard

  public static var subscriptionActive: Bool {
    get {
      return storage.bool(forKey: "subscriptionActive")
    }
    set {
      storage.set(newValue, forKey: "subscriptionActive")
    }
  }

  public static var productName: String {
    Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "LibreMenu"
  }
}
