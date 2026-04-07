//
//  LibreDataDetailScreen.swift
//  glu
//
//  Created by fanxinghua on 2/27/26.
//

import LibreLinkUpKit
import SwiftUI

struct LibreDataDetailScreen: View {
  @Environment(LibreModel.self) private var model

  var body: some View {
    Form {
      Section {
        ForEach(model.dataPoints) { point in
          curveDataRow(point)
        }
      } header: {
        if let first = model.dataPoints.first?.timestamp, let last = model.dataPoints.last?.timestamp {
            Text("\(Text(first, style: .date)) - \(Text(last, style: .date))")
        } else {
          Text(model.dataPoints.last?.timestamp ?? Date(), style: .date)
        }
      }
    }
		.formStyle(.grouped)
		.navigationTitle("Detail")
  }

  private func curveDataRow(_ point: GraphDataPoint) -> some View {
    LabeledContent {
      HStack(alignment: .firstTextBaseline, spacing: 2) {
        let quantity = GluQuantity(point.value, unit: .mmolL)
        let value = quantity.value(for: model.glucoseUnit)
        Text(value.formatted(.number.precision(.fractionLength(1))))
        Text(model.glucoseUnit.description.localized())
      }
			.textSelection(.enabled)
    } label: {
      Text(point.timestamp, style: .time)
    }
  }
}

#Preview {
  LibreDataDetailScreen()
}
