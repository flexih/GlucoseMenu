//
//  LibreMenuApp.swift
//  LibreMenu
//
//  Created by flexih on 3/11/26.
//

import AppKit
import SwiftData
import SwiftUI
import LibreLinkUpKit
import ServiceManagement
import Combine

@main
struct LibreMenuApp: App {
	
	@Environment(\.openWindow) private var openWindow
	
	@State private var container: ModelContainer
	@State private var libre: LibreModel
	
	@AppStorage("showTrend", store: AppGroups.storage) var showTrend: Bool = true
	@AppStorage("launchAtStartup", store: AppGroups.storage) var launchAtStartup: Bool = false
	@AppStorage("glucoseUnit", store: AppGroups.storage) var glucoseUnit: GluUnit = .current

	//@State private var now = Date()

	init() {
		PurchaseManager.configure()
		let container = try! ModelContainer(for: LibreGlucoseItem.self)
		self._container = State(initialValue: container)
		self._libre = State(initialValue: LibreModel(with: container.mainContext))
	}

	var body: some Scene {
		MenuBarExtra {
			if libre.isLoggedIn {
				if let timestamp = libre.dataPoints.last?.timestamp {
					Section {
						Button {
							openWindow(id: Keys.login)
							bringMainWindowToFront()
						} label: {
							Text(timestamp, style: .time)
						}
					} header: {
						Text("Update Time")
					}
				}
				Button(logoutText) {
					libre.logout()
				}
			} else {
				Button("FreeStyle LinkUp") {
					openWindow(id: Keys.login)
					bringMainWindowToFront()
				}
			}
			Toggle("Show Trend Arrow", isOn: $showTrend)
			Picker("Unit", selection: $glucoseUnit) {
				ForEach(GluUnit.allCases, id: \.self) { unit in
					Text(unit.description.localized())
						.tag(unit)
				}
			}
			Divider()
			Toggle("Launch at Startup", isOn: $launchAtStartup)
			Button("Quit") {
				NSApplication.shared.terminate(nil)
			}
			.keyboardShortcut("q")
		} label: {
			Text(menuText)
				.task {
					if libre.isLoggedIn {
						await refreshData()
					}
					checkLaunchAtStartupState()
				}
//				.task {
//					for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect().values {
//						now = Date()
//					}
//				}
				.onChange(of: libre.isLoggedIn) { oldValue, newValue in
					if newValue {
						Task {
							await refreshData()
						}
					} else {
						libre.stopAutoRefresh()
					}
				}
				.onChange(of: libre.selectedPatientId) {
					if libre.isLoggedIn {
						Task {
							await refreshData()
						}
					}
				}
				.onChange(of: glucoseUnit) { _, newValue in
					libre.glucoseUnit = newValue
				}
				.onChange(of: launchAtStartup) {
					Task {
						await updateLaunchAtStartup()
					}
				}
		}
		.modelContainer(container)
		.environment(libre)

		Window(Keys.title, id: Keys.login) {
			NavigationStack {
				LibreScreen()
			}
			.environment(libre)
			.modelContainer(container)
			.focusEffectDisabled()
		}
		.defaultSize(width: 430, height: 310)
		.windowResizability(.contentSize)
		
		Window(Keys.title, id: Keys.data) {
			NavigationStack {
				LibreDataScreen()
			}
			.environment(libre)
			.modelContainer(container)
			.focusEffectDisabled()
		}
		.defaultSize(width: 430, height: 310)
		.windowResizability(.contentSize)
	}
	
	var logoutText: String {
		var seperates: [String] = [String(localized: "Logout")]
		if let email = libre.user?.email {
			seperates.append(email)
		}
		return seperates.joined(separator: " ")
	}
	
	var menuText: String {
		guard let last = libre.dataPoints.last else {
			return "--"
		}
		let glu = GluQuantity(last.value, unit: .mmolL)
		let value = glu.value(for: glucoseUnit).formatted(.number.precision(.fractionLength(1)))
		let text: String
		if showTrend, let symbol = last.trendArrow?.symbol {
			text = "\(value) \(symbol)"
		} else {
			text = value
		}
		return text
	}

//	private func relativeTime(_ date: Date) -> String {
//		let seconds = Int(now.timeIntervalSince(date))
//		switch seconds {
//		case ..<60:
//			return String(localized: "\(seconds)s ago")
//		case 60..<3600:
//			let minutes = seconds / 60
//			let remainSeconds = seconds % 60
//			return String(localized: "\(minutes)m \(remainSeconds)s ago")
//		default:
//			let minutes = seconds / 60
//			return String(localized: "\(minutes) mins ago")
//		}
//	}

	private func refreshData() async {
		do {
			try await libre.fetchConnectionGraphData()
		} catch {
			print(error)
		}
		libre.startAutoRefresh()
	}
	
	private enum Keys {
		static let title = "GlucoseMenu"
		static let login = "login"
		static let data = "data"
	}
	
	private func bringMainWindowToFront() {
		NSApp.activate()
		if !makeKeyAndOrderFront() {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				makeKeyAndOrderFront()
			}
		}
	}

	@discardableResult
	private func makeKeyAndOrderFront() -> Bool {
		guard let window = NSApp.windows.first(
			where: { $0.identifier?.rawValue == Keys.login || $0.identifier?.rawValue == Keys.data
			}) else {
			return false
		}
		window.makeKeyAndOrderFront(nil)
		window.orderFrontRegardless()
		return true
	}
	
	// MARK: - launch at startup support
	private func updateLaunchAtStartup() async {
		if launchAtStartup {
			enableLaunchAtStartup()
		} else {
			await disableLaunchAtStartup()
		}
	}

	private func enableLaunchAtStartup() {
		do {
			try SMAppService.mainApp.register()
		} catch {
			print("Failed to register launch at startup: \(error)")
		}
	}

	private func disableLaunchAtStartup() async {
		do {
			try await SMAppService.mainApp.unregister()
		} catch {
			print("Failed to unregister launch at startup: \(error)")
		}
	}
	
	private func checkLaunchAtStartupState() {
		if launchAtStartup, SMAppService.mainApp.status != .enabled {
			launchAtStartup = false
		}
	}
	
}
