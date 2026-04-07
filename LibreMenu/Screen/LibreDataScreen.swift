//
//  LibreDataScreen.swift
//  glu
//
//  Created by fanxinghua on 2/25/26.
//

import Charts
import LibreLinkUpKit
import SwiftUI
import ActivityKit

struct LibreDataScreen: View {
  
  @Environment(LibreModel.self) private var model
  @State private var selectedDate: Date?
  @State private var rawSelectedDate: Date?
  @State private var positionDate = Date()
  //@State private var selectionFeedback = UISelectionFeedbackGenerator()
  @State private var showAlert = false
  @State private var showActivityAlert = false
  @State private var waitLocationAuthorization = false
  @State private var showLogin = false
  @State private var errorMessage = ""

  var body: some View {
		Form {
      if !model.dataPoints.isEmpty {
        Section {
          timelineChart(points: model.dataPoints)
            .padding(.vertical, 8)
        } header: {
          Text(model.dataPoints.last?.timestamp ?? Date(), style: .date)
        }
        Section {
          let point = model.dataPoints.last!
          LabeledContent {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
              let quantity = GluQuantity(point.value, unit: .mmolL)
							let value = quantity.value(for: model.glucoseUnit)
              Text(value.formatted(.number.precision(.fractionLength(1))))
                .contentTransition(.numericText())
              Text(model.glucoseUnit.description.localized())
            }
          } label: {
            HStack(alignment: .firstTextBaseline) {
              Text(point.factoryTimestamp, style: .time)
              Text(point.factoryTimestamp, style: .relative)
                .foregroundStyle(.secondary)
                .font(.footnote)
            }
          }
        } header: {
          HStack {
            Text("Data")
            Spacer()
            if model.isLoadingDataPoints {
              ProgressView()
								.controlSize(.small)
            }
          }
        }
        Section {
          NavigationLink("View Data") {
            LibreDataDetailScreen()
          }
        }
      }
    }
		.formStyle(.grouped)
    .overlay {
      if model.dataPoints.isEmpty {
        if model.isLoadingDataPoints {
          ProgressView()
        } else if !model.isLoggedIn {
          ContentUnavailableView(label: {
            Text("No Data Available")
          }, description: {
            Text("Please login to your LibreLinkUp account to view your data.")
          }, actions: {
            Button("Login") {
              showLogin = true
            }
          })
        } else if !errorMessage.isEmpty {
          Text(errorMessage)
            .foregroundStyle(.secondary)
            .transition(.move(edge: .top))
        }
      }
    }
    .refreshable {
      await fetchData()
    }
    .task {
      await fetchData()
      if model.isLoggedIn {
        model.startAutoRefresh()
      }
    }
//    .onDisappear {
//      if !liveActivityManager.isOn {
//        model.stopAutoRefresh()
//      }
//    }
    .onChange(of: model.isLoggedIn) { oldValue, newValue in
      if newValue {
        model.startAutoRefresh()
      } else {
        model.stopAutoRefresh()
      }
    }
    .onChange(of: model.selectedPatientId) { oldValue, newValue in
      if oldValue.isEmpty, !newValue.isEmpty, model.dataPoints.isEmpty {
        Task {
          await fetchData()
        }
      }
    }
    .onChange(of: model.dataPoints) { oldValues, newValues in
      if !newValues.isEmpty, let last = newValues.last,
         selectedDate == nil || oldValues.last?.timestamp == selectedDate
      {
        positionDate = last.timestamp
        rawSelectedDate = last.timestamp
      }
    }
    .sheet(isPresented: $showLogin) {
      NavigationStack {
        LibreScreen()
      }
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
		.navigationTitle("Data")
  }
  
  func fetchData() async {
    do {
      try await model.fetchConnectionGraphData()
    } catch {
      withAnimation {
        errorMessage = error.localizedDescription
      }
    }
  }

  func isSelected(_ point: GraphDataPoint, in points: [GraphDataPoint]) -> Bool {
    if let selectedDate,
       let selectedPoint = findExactPoint(at: selectedDate, in: points)
    {
      return selectedPoint.id == point.id
    }
    return false
  }

  @ViewBuilder
  private func timelineChart(points: [GraphDataPoint]) -> some View {
    let enableScroll = shouldEnableScroll(points: points)
    let domain = chartXDomain(points: points)
    // let yRange = chartYRange(points: points)
    // let yAxisValues = chartYAxisValues(points: points)

    Chart {
      ForEach(points) { point in
        let quantity = GluQuantity(point.value, unit: .mmolL)
        let value = quantity.value(for: model.glucoseUnit)
        let isSelected = isSelected(point, in: points)
        BarMark(
          x: .value("Time", point.timestamp),
          y: .value("Value", value)
          // width: .fixed(8)
        )
        .foregroundStyle(isSelected ? Color.blue.gradient : Color.blue.opacity(0.7).gradient)
        .annotation(position: .top, spacing: 12, overflowResolution: .init(x: .fit(to: .chart), y: .padScale /* .fit(to: .chart) */ )) {
          if isSelected {
            Text(value.formatted(.number.precision(.fractionLength(1))))
              .font(.footnote)
          }
        }
      }
    }
    .chartScrollPosition(x: $positionDate)
    .chartXScale(range: .plotDimension(padding: 16))
    .chartXScale(domain: domain)
    .chartScrollableAxes(enableScroll ? .horizontal : [])
    .if(enableScroll) { view in
      view.chartXVisibleDomain(length: 6 * 60 * 60)
    }
    .chartXSelection(value: $rawSelectedDate)
    .onChange(of: rawSelectedDate) { _, newValue in
      if let newValue {
        selectedDate = newValue
        if findExactPoint(at: newValue, in: points) != nil {
          //selectionFeedback.selectionChanged()
        }
      }
    }
    .chartXAxis {
      if let selectedDate, let point = findExactPoint(at: selectedDate, in: points) {
        AxisMarks(preset: .aligned, position: .bottom, values: [point.timestamp]) { value in
          AxisGridLine()
          AxisValueLabel(verticalSpacing: 12) {
            if let date = value.as(Date.self) {
              Text(selectedFormatter.string(from: date))
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize()
            }
          }
        }
      } else {
        AxisMarks(preset: .aligned, position: .bottom, values: .automatic()) { value in
          AxisGridLine()
          AxisValueLabel(verticalSpacing: 12) {
            if let date = value.as(Date.self) {
              Text(hourFormatter.string(from: date))
                .fixedSize()
            }
          }
        }
      }
    }
    //    .chartYAxis {
    //      AxisMarks(values: yAxisValues) { value in
    //        AxisGridLine()
    //        AxisValueLabel {
    //          if let v = value.as(Double.self) {
    //            Text(glucoseAxisLabel(v))
    //          }
    //        }
    //      }
    //    }
    .frame(height: 180)
  }

  private var hourFormatter: DateFormatter {
    let formatter = DateFormatter()
		formatter.dateFormat = String(localized: .hourFormatChart)
    return formatter
  }

  private var selectedFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = .none
    formatter.timeStyle = .short
    return formatter
  }

  private func findExactPoint(at date: Date, in points: [GraphDataPoint]) -> GraphDataPoint? {
    let tolerance: TimeInterval = 60 + 30
    for point in points {
      if abs(point.timestamp.timeIntervalSince(date)) <= tolerance {
        return point
      }
    }
    return nil
  }

  private func glucoseAxisLabel(_ value: Double) -> String {
    let measurement = Measurement(value: value, unit: UnitConcentrationMass.millimolesPerLiter(withGramsPerMole: 0.01))
    return measurement.formatted(.measurement(
      width: .abbreviated,
      usage: .asProvided,
      numberFormatStyle: .number.precision(.fractionLength(1))
    ))
  }

  /// Y 轴范围，含上下留白，并保证最大值在刻度上
  private func chartYRange(points: [GraphDataPoint]) -> ClosedRange<Double> {
    let values = points.map { GluQuantity($0.value, unit: .mmolL).value(for: model.glucoseUnit) }
    guard let minV = values.min(), let maxV = values.max() else {
      return 0 ... 10
    }
    let padding = max(0.5, (maxV - minV) * 0.1)
    return (minV - padding) ... (maxV + padding)
  }

  /// Y 轴刻度，包含最小值与最大值
  private func chartYAxisValues(points: [GraphDataPoint]) -> [Double] {
    let values = points.map { GluQuantity($0.value, unit: .mmolL).value(for: model.glucoseUnit) }
    guard let minV = values.min(), let maxV = values.max(), maxV > minV else {
      if let single = values.first { return [single] }
      return [0, 10]
    }
    let count = 5
    let step = (maxV - minV) / Double(count - 1)
    return (0 ..< count).map { minV + step * Double($0) }
  }

  /// X 轴显示全部数据范围
  private func chartXDomain(points: [GraphDataPoint]) -> ClosedRange<Date> {
    guard let first = points.first, let last = points.last else {
      let end = Date()
      return Calendar.current.date(byAdding: .hour, value: -6, to: end)! ... end
    }
    return first.timestamp ... last.timestamp
  }

  /// 判断是否需要启用滚动（时间跨度大于 6 小时）
  private func shouldEnableScroll(points: [GraphDataPoint]) -> Bool {
    guard let first = points.first, let last = points.last else {
      return false
    }
    let timeSpan = last.timestamp.timeIntervalSince(first.timestamp)
    return timeSpan > 6 * 60 * 60 // 6 小时
  }
}

#Preview {
  LibreDataScreen()
}
