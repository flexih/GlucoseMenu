import Foundation

/// 可能有多个，保存
/// 包含”立即”分钟数据
public struct ConnectionItem: Codable, Identifiable, Hashable, Sendable {
  public var id: String { connectionId }
  public let connectionId: String
  public let patientId: String
  public let firstName: String
  public let lastName: String
  public let targetLow: Int?
  public let targetHigh: Int?
  public let glucoseMeasurement: GraphDataPoint?
  public let sensor: SensorInfo?
  public let patientDevice: PatientDevice?

  enum CodingKeys: String, CodingKey {
    case connectionId = "id"
    case patientId
    case firstName
    case lastName
    case targetLow
    case targetHigh
    case glucoseMeasurement
    case sensor
    case patientDevice
  }

  public func hash(into hasher: inout Hasher) { hasher.combine(connectionId) }
  public static func == (lhs: ConnectionItem, rhs: ConnectionItem) -> Bool { lhs.connectionId == rhs.connectionId }
}

public struct SensorInfo: Codable, Hashable, Sendable {
  public let deviceId: String?
  public let sn: String?

  enum CodingKeys: String, CodingKey {
    case deviceId
    case sn
  }
}

public struct PatientDevice: Codable, Hashable, Sendable {
  public let did: String?
  public let dtid: Int?
  public let v: String?
}
