//
//  URL+Extension.swift
//  glu
//
//  Created by fanxinghua on 2025/5/8.
//

import Foundation

extension URL: @retroactive Identifiable {
  public var id: String {
    absoluteString
  }
}

public extension URL {
  // Returns a URL for the given app group and database pointing to the sqlite database.
  static func storeURL(for appGroup: String) -> URL {
    guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
      fatalError("Shared file container could not be created.")
    }

    return fileContainer
  }
}
