//
//  LibreModel.swift
//  glu
//
//  Created by fanxinghua on 2/24/26.
//

import Combine
import SwiftData
import Foundation
import KeychainAccess
import LibreLinkUpKit

@Observable
@MainActor
final class LibreModel {
	
	init(with context: ModelContext) {
    let user = User.load()
    email = user?.email ?? ""
    password = ""
    self.user = user
    selectedPatientId = user?.patientId ?? ""
    let region = (user?.region).flatMap { EndPoint.Region(rawValue: $0) } ?? .cn
    self.region = region
    service = .init(region: region)
		self.context = context
  }
	
	@ObservationIgnored
	private var context: ModelContext
	
	var glucoseUnit: GluUnit = .current

  var region: EndPoint.Region

  var email: String
  var password: String

  var isLoggingin = false
  var isLoadingConnections = false

  private(set) var user: User?

  private(set) var connections: [ConnectionItem]?
  var selectedPatientId: String

  var dataPoints: [GraphDataPoint] = []
  var isLoadingDataPoints = false

  @ObservationIgnored
  private var service: APIService

  var isLoginable: Bool {
    return !email.isEmpty && !password.isEmpty
  }

  var isLoggedIn: Bool {
    return user != nil
  }

  func login() async throws {
		guard !isLoggingin else { return }
    isLoggingin = true
    defer {
      isLoggingin = false
    }
    user = try await service.login(email: email, password: password)
    User.save(user)
    password = ""
  }

  func fetchConnections() async throws {
		guard !isLoadingConnections else { return }
    isLoadingConnections = true
    defer {
      isLoadingConnections = false
    }
    guard let user else {
      return
    }
    connections = try await service.connections(token: user.token, accountId: user.accountId)
    if selectedPatientId.isEmpty, let connection = connections?.first {
      selectedPatientId = connection.patientId
      savePatientId(connection.patientId, of: user)
      self.user = User.load()
    }
  }

  func fetchConnectionGraphData() async throws {
		guard !isLoadingDataPoints else { return }
    isLoadingDataPoints = true
    defer {
      isLoadingDataPoints = false
    }
    guard let user, !selectedPatientId.isEmpty else {
      return
    }
    let result = try await service.connectionGraph(
      patientId: selectedPatientId,
      token: user.token,
      accountId: user.accountId
    )
		var points = try await saveAndFetchDataPoints(result.graphData ?? [], context: context)
    if let glucoseMeasurement = result.connection?.glucoseMeasurement {
      points.append(glucoseMeasurement)
    }
    dataPoints = points
    //    let liveActivityManager = LiveActivityManager.shared
    //    if liveActivityManager.isOn, let last = points.last {
    //      liveActivityManager.update(point: last)
    //    }
  }

  func logout() {
    user = nil
    User.save(nil)
    connections = nil
    dataPoints = []
    selectedPatientId = ""
    password = ""
    email = ""
    stopAutoRefresh()
  }

  func personName(of connection: ConnectionItem) -> String {
    var person = PersonNameComponents()
    person.familyName = connection.lastName
    person.givenName = connection.firstName
    return person.formatted()
  }

  func savePatientId(_ patientId: String?, of user: User) {
    let result = User(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      country: user.country,
      region: user.region,
      tokenKey: user.token,
      accountIdKey: user.accountId,
      userIdKey: user.userId,
      patientId: patientId
    )
    User.save(result)
  }

  @ObservationIgnored
  private var refreshTimerCancellable: AnyCancellable?

  func startAutoRefresh() {
    guard refreshTimerCancellable == nil else { return }
    refreshTimerCancellable?.cancel()
    refreshTimerCancellable = Timer.publish(every: 60, on: .main, in: .common)
      .autoconnect()
      .sink { [self] _ in
        Task { @MainActor in
          try? await fetchConnectionGraphData()
        }
      }
  }

  func stopAutoRefresh() {
    refreshTimerCancellable?.cancel()
    refreshTimerCancellable = nil
  }

  // MARK: - SwiftData

  func saveAndFetchDataPoints(
    _ newPoints: [GraphDataPoint],
    context: ModelContext
  ) async throws -> [GraphDataPoint] {
    saveDataPoints(newPoints, in: context)
    return try fetchTodayDataPoints(in: context)
  }

  private func saveDataPoints(_ points: [GraphDataPoint], in context: ModelContext) {
    guard !points.isEmpty else { return }

    // With SwiftData @Attribute(.unique) on factoryTimestamp, duplicates
    // are automatically handled. We just map GraphDataPoint to LibreGlucoseItem and insert.
    for point in points {
      let item = LibreGlucoseItem(
          factoryTimestamp: point.factoryTimestamp,
          timestamp: point.timestamp,
          type: point.type,
          valueInMgPerDl: point.valueInMgPerDl,
          value: point.value,
          measurementColor: point.measurementColor?.rawValue ?? 0,
          glucoseUnits: point.glucoseUnits ?? 0,
          isHigh: point.isHigh ?? false,
          isLow: point.isLow ?? false,
          trendArrow: point.trendArrow?.rawValue ?? 0,
          trendMessage: point.trendMessage
      )
      context.insert(item)
    }
    
    if context.hasChanges {
      try? context.save()
    }
  }

  private func fetchTodayDataPoints(in context: ModelContext) throws
    -> [GraphDataPoint] {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
		let descriptor = FetchDescriptor<LibreGlucoseItem>(
        predicate: #Predicate { item in
            item.timestamp >= startOfDay && item.timestamp < endOfDay
        },
        sortBy: [SortDescriptor(\.timestamp, order: .forward)]
    )

    let fetchedItems = try context.fetch(descriptor)
    return fetchedItems.map { item in
      GraphDataPoint(
        factoryTimestamp: item.factoryTimestamp,
        timestamp: item.timestamp,
        type: item.type,
        valueInMgPerDl: item.valueInMgPerDl,
        value: item.value,
        measurementColor: MeasurementColor(rawValue: item.measurementColor),
        glucoseUnits: item.glucoseUnits,
        isHigh: item.isHigh,
        isLow: item.isLow,
        trendArrow: TrendArrow(rawValue: item.trendArrow),
        trendMessage: item.trendMessage
      )
    }
  }
}

extension User {
  private enum Keys {
    static let libre = "libre"
  }

  static func load() -> User? {
    let keychain = Keychain().synchronizable(true)
    guard let data = try? keychain.getData(Keys.libre),
      let user = try? JSONDecoder().decode(User.self, from: data)
    else {
      return nil
    }
    return user
  }

  static func save(_ newValue: User?) {
    let keychain = Keychain().synchronizable(true)
    guard let newValue else {
      try? keychain.remove(Keys.libre)
      return
    }
    guard let data = try? JSONEncoder().encode(newValue) else {
      return
    }
    try? keychain.set(data, key: Keys.libre)
  }
}
