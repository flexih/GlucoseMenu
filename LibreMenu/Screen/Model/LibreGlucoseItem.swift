//
//  LibreGlucoseItem.swift
//  glu
//

import Foundation
import SwiftData

@Model
public final class LibreGlucoseItem {
    @Attribute(.unique) public var factoryTimestamp: Date
    public var timestamp: Date
    public var type: Int
    public var valueInMgPerDl: Int
    public var value: Double
    public var measurementColor: Int
    public var glucoseUnits: Int
    public var isHigh: Bool
    public var isLow: Bool
    public var trendArrow: Int
    public var trendMessage: String?

    public init(
        factoryTimestamp: Date,
        timestamp: Date,
        type: Int,
        valueInMgPerDl: Int,
        value: Double,
        measurementColor: Int,
        glucoseUnits: Int,
        isHigh: Bool,
        isLow: Bool,
        trendArrow: Int,
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
}
