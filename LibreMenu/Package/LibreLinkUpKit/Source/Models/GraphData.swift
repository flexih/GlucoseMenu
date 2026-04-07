import Foundation

/*
 {"FactoryTimestamp":"2/2/2026 3:55:45 AM",
 "Timestamp":"2/2/2026 11:55:45 AM",
 "type":1,
 "ValueInMgPerDl":101,
 "TrendArrow":3,
 "TrendMessage":null,
 "MeasurementColor":1,
 "GlucoseUnits":0,
 "Value":5.6,
 "isHigh":false,
 "isLow":false}
 */

public enum MeasurementColor: Int, Codable, Sendable {
  case green = 1
  case yellow = 2
  case orange = 3
  case red = 4
  case gray = 5
}

public enum TrendArrow: Int, CustomStringConvertible, CaseIterable, Codable, Sendable {
  case notDetermined = 0
  case fallingQuickly = 1
  case falling = 2
  case stable = 3
  case rising = 4
  case risingQuickly = 5

  public var description: String {
    switch self {
    case .notDetermined: "not determined"
    case .fallingQuickly: "falling quickly"
    case .falling: "falling"
    case .stable: "stable"
    case .rising: "rising"
    case .risingQuickly: "rising quickly"
    }
  }

  public var symbol: String {
    switch self {
    case .fallingQuickly: "↓"
    case .falling: "↘︎"
    case .stable: "→"
    case .rising: "↗︎"
    case .risingQuickly: "↑"
    default: "-"
    }
  }
}

public struct GraphDataPoint: Codable, Identifiable, Equatable, Sendable {
  public var id: Date { timestamp }

  /// GMT 时间（API 原始值）
  public let factoryTimestamp: Date
  /// CST 时间（中国标准时间）
  public let timestamp: Date
  /// 1: 立即, 0: 平均值
  public let type: Int
  public let valueInMgPerDl: Int
  public let value: Double
  public let measurementColor: MeasurementColor?
  public let glucoseUnits: Int?
  public let isHigh: Bool?
  public let isLow: Bool?
  public let trendArrow: TrendArrow?
  public let trendMessage: String?

  public var isAverage: Bool { type == 0 }
  public var isImmediate: Bool { type == 1 }

  enum CodingKeys: String, CodingKey {
    case factoryTimestamp = "FactoryTimestamp"
    case timestamp = "Timestamp"
    case type
    case valueInMgPerDl = "ValueInMgPerDl"
    case value = "Value"
    case measurementColor = "MeasurementColor"
    case glucoseUnits = "GlucoseUnits"
    case isHigh
    case isLow
    case trendArrow = "TrendArrow"
    case trendMessage = "TrendMessage"
  }

  private static let gmtFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "M/d/yyyy h:mm:ss a"
    f.locale = Locale(identifier: "en_US")
    f.timeZone = TimeZone(identifier: "GMT")
    return f
  }()

  private static let cstFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "M/d/yyyy h:mm:ss a"
    f.locale = Locale(identifier: "en_US")
    f.timeZone = TimeZone(identifier: "Asia/Shanghai")
    return f
  }()

  public init(
    factoryTimestamp: Date,
    timestamp: Date,
    type: Int,
    valueInMgPerDl: Int,
    value: Double,
    measurementColor: MeasurementColor? = nil,
    glucoseUnits: Int? = nil,
    isHigh: Bool? = nil,
    isLow: Bool? = nil,
    trendArrow: TrendArrow? = nil,
    trendMessage: String? = nil
  ) {
    self.factoryTimestamp = factoryTimestamp
    self.timestamp = timestamp
    self.type = type
    self.valueInMgPerDl = valueInMgPerDl
    self.value = value
    self.measurementColor = measurementColor
    self.glucoseUnits = glucoseUnits
    self.isHigh = isHigh
    self.isLow = isLow
    self.trendArrow = trendArrow
    self.trendMessage = trendMessage
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    factoryTimestamp = try Self.decodeDate(from: c, key: .factoryTimestamp, formatter: Self.gmtFormatter)
    timestamp = try Self.decodeDate(from: c, key: .timestamp, formatter: Self.cstFormatter)
    type = try c.decode(Int.self, forKey: .type)
    valueInMgPerDl = try c.decode(Int.self, forKey: .valueInMgPerDl)
    value = try c.decode(Double.self, forKey: .value)
    measurementColor = try c.decodeIfPresent(MeasurementColor.self, forKey: .measurementColor)
    glucoseUnits = try c.decodeIfPresent(Int.self, forKey: .glucoseUnits)
    isHigh = try c.decodeIfPresent(Bool.self, forKey: .isHigh)
    isLow = try c.decodeIfPresent(Bool.self, forKey: .isLow)
    trendArrow = try c.decodeIfPresent(TrendArrow.self, forKey: .trendArrow)
    trendMessage = try c.decodeIfPresent(String.self, forKey: .trendMessage)
  }

  private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys, formatter: DateFormatter) throws -> Date {
    let raw = try container.decode(String.self, forKey: key)
    guard let date = formatter.date(from: raw) else {
      throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Invalid date format: \(raw)")
    }
    return date
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(Self.gmtFormatter.string(from: factoryTimestamp), forKey: .factoryTimestamp)
    try c.encode(Self.cstFormatter.string(from: timestamp), forKey: .timestamp)
    try c.encode(type, forKey: .type)
    try c.encode(valueInMgPerDl, forKey: .valueInMgPerDl)
    try c.encode(value, forKey: .value)
    try c.encodeIfPresent(measurementColor, forKey: .measurementColor)
    try c.encodeIfPresent(glucoseUnits, forKey: .glucoseUnits)
    try c.encodeIfPresent(isHigh, forKey: .isHigh)
    try c.encodeIfPresent(isLow, forKey: .isLow)
    try c.encodeIfPresent(trendArrow, forKey: .trendArrow)
    try c.encodeIfPresent(trendMessage, forKey: .trendMessage)
  }
}

public struct ConnectionGraphData: Codable, Sendable {
  public let connection: ConnectionItem?
  public let activeSensors: [ActiveSensor]?
  public let graphData: [GraphDataPoint]?
}

public struct ActiveSensor: Codable, Sendable {
  public let sensor: SensorInfo?
  public let device: PatientDevice?
}
