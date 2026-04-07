
import Foundation
import HealthKit

public extension NSNotification.Name {
  static let gluUnitChanged = Notification.Name("GluUnitChanged")
}

public enum GluQuantity {
  case mmolL(Double)
  case mgdL(Double)

  public init(_ value: Double, unit: GluUnit = .current) {
    switch unit {
    case .mmolL:
      self = .mmolL(value)
    case .mgdL:
      self = .mgdL(value)
    }
  }

  public var hkQuantity: HKQuantity {
    switch self {
    case let .mgdL(value):
      return HKQuantity(unit: GluUnit.mgdLUnit, doubleValue: value)
    case let .mmolL(value):
      return HKQuantity(unit: GluUnit.mmolLUnit, doubleValue: value)
    }
  }

  public func value(for unit: GluUnit) -> Double {
    switch self {
    case let .mgdL(value):
      switch unit {
      case .mgdL:
        return value
      case .mmolL:
        let glucoseInMgdL = HKQuantity(unit: GluUnit.mgdLUnit, doubleValue: value)
        return glucoseInMgdL.doubleValue(for: unit.unit)
      }
    case let .mmolL(value):
      switch unit {
      case .mgdL:
        let glucosemmolL = HKQuantity(unit: GluUnit.mmolLUnit, doubleValue: value)
        return glucosemmolL.doubleValue(for: unit.unit)
      case .mmolL:
        return value
      }
    }
  }

  public var unit: GluUnit {
    switch self {
    case .mgdL:
      return .mgdL
    case .mmolL:
      return .mmolL
    }
  }
}

extension GluQuantity: Codable {}

extension GluQuantity: Comparable {
  public static func < (lhs: GluQuantity, rhs: GluQuantity) -> Bool {
    return lhs.value(for: .mmolL) < rhs.value(for: .mmolL)
  }

  public static func == (lhs: GluQuantity, rhs: GluQuantity) -> Bool {
    return lhs.value(for: .mmolL) == rhs.value(for: .mmolL)
  }
}

/// default unit is mmol/L in CoreData
public enum GluUnit: Int, CaseIterable {
  case mmolL
  case mgdL
}

extension GluUnit: CustomStringConvertible, Identifiable {
  public var id: String {
    description
  }

  public var description: String {
    switch self {
    case .mgdL:
      return "mg/dL"
    case .mmolL:
      return "mmol/L"
    }
  }
}

public extension GluUnit {
  static var mgdLUnit: HKUnit {
    HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
  }

  static var mmolLUnit: HKUnit {
    HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter())
  }

  var unit: HKUnit {
    switch self {
    case .mgdL:
      return GluUnit.mgdLUnit
    case .mmolL:
      return GluUnit.mmolLUnit
    }
  }

  static var current: GluUnit {
      guard let unitValue = AppGroups.storage.value(forKey: "glucoseUnit") as? Int,
          let unit = GluUnit(rawValue: unitValue)
    else {
      return .mmolL
    }
    return unit
  }

  static var store: GluUnit = .mmolL
}

extension GluUnit: Codable {}
