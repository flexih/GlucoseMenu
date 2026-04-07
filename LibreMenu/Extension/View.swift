//
//  View.swift
//  Base
//
//  Created by fanxinghua on 2/26/26.
//

import SwiftUI

public extension View {
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}
