import Foundation

public struct User: Codable, Sendable {
  public let id: String
  public let firstName: String
  public let lastName: String
  public let email: String
  public let country: String
  public let region: String
  public let token: String
  public let accountId: String
  public let userId: String
  public let patientId: String?

  public init(
    id: String,
    firstName: String,
    lastName: String,
    email: String,
    country: String,
    region: String,
    tokenKey: String,
    accountIdKey: String,
    userIdKey: String,
    patientId: String? = nil
  ) {
    self.id = id
    self.firstName = firstName
    self.lastName = lastName
    self.email = email
    self.country = country
    self.region = region
    self.patientId = patientId
    token = tokenKey
    accountId = accountIdKey
    userId = userIdKey
  }
}
