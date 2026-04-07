//
//  LibreScreen.swift
//  glu
//
//  Created by fanxinghua on 2/6/26.
//

import LibreLinkUpKit
import Pow
import SwiftUI

struct LibreScreen: View {
  @Environment(LibreModel.self) private var model

  @State private var loginAttempts = 0
  @State private var errorMessage = ""
  @State private var showPaywall = false
  @FocusState private var focusedField: LoginField?

  @State private var purchaseManager = PurchaseManager.shared

  var showDataListEntry = true

  enum LoginField { case email, password }

  var body: some View {
    Form {
      if model.isLoggedIn {
        logoutView
        connectionsView
      } else {
        loginView
      }
    }
    .formStyle(.grouped)
    .navigationTitle("FreeStyle Libre")
		.task {
			await purchaseManager.checkStatus()
		}
  }

  func resetErrorMessage() {
    if !errorMessage.isEmpty {
      errorMessage = ""
    }
  }

  private func performLogin() {
    NSApplication.shared.resignFirstResponder()
    Task {
      do {
        try await model.login()
      } catch {
        switch error {
        case let APIService.ResultError.dataError(message):
          withAnimation { errorMessage = message }
        default:
          withAnimation { errorMessage = "Something wrong happens" }
        }
        loginAttempts += 1
      }
    }
  }

  @ViewBuilder
  private var loginView: some View {
    @Bindable var model = model
    Section("Device") {
      let allCases = EndPoint.Region.allCases.sorted(by: { $0.regionName.localized() < $1.regionName.localized() })
      Picker("Region", selection: $model.region) {
        ForEach(allCases, id: \.self) { region in
          Text(region.regionName).tag(region)
        }
      }
      .focusable(false)
    }

    Section("LibreLinkUp Account") {
      TextField("Email", text: $model.email)
        .textContentType(.emailAddress)
        .focused($focusedField, equals: .email)
        .onSubmit { focusedField = .password }
        .onChange(of: model.email) { resetErrorMessage() }

      SecureField("Password", text: $model.password)
        .textContentType(.password)
        .focused($focusedField, equals: .password)
        .onSubmit {
          if model.isLoginable { performLogin() }
        }
        .onChange(of: model.password) { resetErrorMessage() }
    }
    .changeEffect(.shake(rate: .fast), value: loginAttempts)
    .disabled(model.isLoggingin)

    if !errorMessage.isEmpty {
      Section {
        Text(errorMessage)
          .foregroundStyle(.red)
          .transition(.move(edge: .top))
      }
    }

    Section {
    } footer: {
      Button {
        performLogin()
      } label: {
        if model.isLoggingin {
          ProgressView()
						.controlSize(.small)
            .frame(maxWidth: .infinity)
						.padding(.vertical, 4)
        } else {
          Text("Login")
            .frame(maxWidth: .infinity)
						.padding(.vertical, 4)
        }
      }
      .keyboardShortcut(.return)
      .disabled(model.isLoggingin || !model.isLoginable)
			.buttonBorderShape(.capsule)
			.buttonStyle(.borderedProminent)
			.padding()
    }
  }

  @ViewBuilder
  private var logoutView: some View {
    Section {
			LabeledContent {
				HStack(spacing: 6) {
					Text(model.email)
					Button("Logout", role: .destructive) {
						model.logout()
					}
					.buttonStyle(.borderedProminent)
				}
			} label: {
				Text("Email")
			}
			if showDataListEntry {
				NavigationLink {
					LibreDataScreen()
				} label: {
					Text("View Data")
				}
			}
		} header: {
			HStack {
				Text("Account")
				Spacer()
				NavigationLink {
					PaywallScreen()
				} label: {
					HStack {
						if purchaseManager.isSubscribed {
							Image(systemName: "checkmark.seal.fill")
								.foregroundStyle(.yellow)
							Text("Pro")
						} else {
							Image(systemName: "star.circle.fill")
								.foregroundStyle(.yellow)
							Text("Upgrade to Pro")
						}
					}
				}
				.focusable(false)
//				if purchaseManager.isSubscribed {
//					LabeledContent("Pro") {
//						Image(systemName: "checkmark.seal.fill")
//							.foregroundStyle(.yellow)
//					}
//				} else {
//					NavigationLink {
//						PaywallScreen()
//					} label: {
//						HStack {
//							Image(systemName: "star.circle.fill")
//								.foregroundStyle(.yellow)
//							Text("Upgrade to Pro")
//						}
//					}
//					.focusable(false)
//				}
			}
		}
  }

  @ViewBuilder
  private var connectionsView: some View {
    @Bindable var model = model
    Section("Connections") {
      if let connections = model.connections {
        Picker("Connections", selection: $model.selectedPatientId) {
          ForEach(connections) { connection in
            Text(model.personName(of: connection))
              .tag(connection.patientId)
          }
        }
        .labelsHidden()
        .pickerStyle(.inline)
        .disabled(model.isLoadingConnections)
      } else {
        ProgressView()
					.controlSize(.small)
          .frame(maxWidth: .infinity)
      }
    }
    .task {
      do {
        try await model.fetchConnections()
      } catch {}
    }
  }
}

#Preview {
  NavigationStack {
    LibreScreen()
  }
}
