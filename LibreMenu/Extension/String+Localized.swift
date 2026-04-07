
import Foundation

public extension String {
  func localized(comment: String = "") -> String {
    return NSLocalizedString(self, comment: comment)
  }

  func localized(with arguments: CVarArg..., comment: String = "") -> String {
    return String(format: NSLocalizedString(self, comment: comment), arguments: arguments)
  }
}
