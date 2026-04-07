import Foundation

struct LoginRequest: Encodable, Sendable {
  let email: String
  let password: String

  init(email: String, password: String) {
    self.email = email
    self.password = password
  }
}

struct LoginData: Codable, Sendable {
  let user: LoginUser
  let authTicket: AuthTicket
  let invitations: [String]?

  init(user: LoginUser, authTicket: AuthTicket, invitations: [String]? = nil) {
    self.user = user
    self.authTicket = authTicket
    self.invitations = invitations
  }

  struct LoginUser: Codable, Sendable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let country: String
  }
}
