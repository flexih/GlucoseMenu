//
//  APIService.swift
//  LibreLinkUpKit
//
//  Created by fanxinghua on 2/4/26.
//

import Alamofire
import CryptoKit
import Foundation

/// Reference:
/// https://github.com/gui-dos/DiaBLE/blob/eb5beeee0e22f2282b4b641cd9fdb474609cd99b/DiaBLE/LibreLink.swift#L172

public final class APIService {
  public enum ResultError: Error {
    case invalidAuth
    case dataError(String)
    case unknown
  }

  private static let session: Session = {
    var configuration = URLSessionConfiguration.af.default
    configuration.headers.add(name: "version", value: "4.17.0")
    configuration.headers.add(name: "product", value: "llu.ios")
    let session = Session(configuration: configuration)
    return session
  }()

  private let region: EndPoint.Region

  private init() {
    region = .cn
  }

  public init(region: EndPoint.Region) {
    self.region = region
  }

  public func login(email: String, password: String) async throws -> User {
    let endpoint = EndPoint.auth
    let result = try await withCheckedThrowingContinuation { continuation in
      APIService.session.request(
        endpoint.fullURL(with: region),
        method: endpoint.method,
        parameters: LoginRequest(email: email, password: password),
        encoder: JSONParameterEncoder()
      )
      .responseDecodable(of: Response<LoginData>.self) { response in
        switch response.result {
        case let .success(result):
          if let resultData = result.data {
            continuation.resume(returning: resultData)
          } else {
            if let error = result.error {
              continuation.resume(throwing: ResultError.dataError(error.message))
            } else {
              continuation.resume(throwing: ResultError.unknown)
            }
          }
        case let .failure(error):
          continuation.resume(throwing: error)
        }
      }
    }
    return generateUser(from: result)
  }

  public func connections(token: String, accountId: String) async throws -> [ConnectionItem] {
    let endpoint = EndPoint.connections
    return try await withCheckedThrowingContinuation { continuation in
      APIService.session.request(
        endpoint.fullURL(with: region),
        method: endpoint.method,
        headers: [.authorization(bearerToken: token),
                  .init(name: "Account-Id", value: accountId)]
      )
      .responseDecodable(of: Response<[ConnectionItem]>.self) { response in
        switch response.result {
        case let .success(result):
          if let resultData = result.data {
            continuation.resume(returning: resultData)
          } else {
            if let error = result.error {
              continuation.resume(throwing: ResultError.dataError(error.message))
            } else {
              continuation.resume(throwing: ResultError.unknown)
            }
          }
        case let .failure(error):
          continuation.resume(throwing: error)
        }
      }
    }
  }

  public func connectionGraph(patientId: String, token: String, accountId: String) async throws -> ConnectionGraphData {
    let endpoint = EndPoint.connection(patientId: patientId)
    return try await withCheckedThrowingContinuation { continuation in
      APIService.session.request(
        endpoint.fullURL(with: region),
        method: endpoint.method,
        headers: [.authorization(bearerToken: token),
                  .init(name: "Account-Id", value: accountId)]
      )
      .responseDecodable(of: Response<ConnectionGraphData>.self) { response in
        switch response.result {
        case let .success(result):
          if let resultData = result.data {
            continuation.resume(returning: resultData)
          } else {
            if let error = result.error {
              continuation.resume(throwing: ResultError.dataError(error.message))
            } else {
              continuation.resume(throwing: ResultError.unknown)
            }
          }
        case let .failure(error):
          continuation.resume(throwing: error)
        }
      }
    }
  }

  private func generateUser(from data: LoginData) -> User {
    let tokenKey = data.authTicket.token
    let userId = data.user.id
    let accountId = deriveAccountId(userId: userId)
    let user = User(
      id: userId,
      firstName: data.user.firstName,
      lastName: data.user.lastName,
      email: data.user.email,
      country: data.user.country,
      region: region.rawValue,
      tokenKey: tokenKey,
      accountIdKey: accountId,
      userIdKey: userId
    )
    return user
  }

  private func deriveAccountId(userId: String) -> String {
    guard let data = userId.data(using: .utf8) else { return userId }
    let hash = SHA256.hash(data: data)
    return hash.map { String(format: "%02x", $0) }.joined()
  }

  private struct Response<T: Decodable>: Decodable {
    struct ErrorMessage: Decodable {
      let message: String
    }

    let status: Int
    let data: T?
    let error: ErrorMessage?
  }
}
