import Foundation

public struct AuthTicket: Codable, Sendable {
  public let token: String
  public let expires: Int
  public let duration: Int

  public init(token: String, expires: Int, duration: Int) {
    self.token = token
    self.expires = expires
    self.duration = duration
  }
}
