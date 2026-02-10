//
//  SidebarView.swift
//  FontViewer
//
//  Created by Luke Roberts on 07/02/2026.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var model: FontModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if model.ctFont == nil {
                Text("No font selected")
            } else {
                controls
            }
        }
        .padding()
        .onChange(of: model.fontSize) { oldValue, newValue in
            model.loadFont()
        }
    }

    var controls: some View {
        VStack(alignment: .leading) {
            Text("Adjust Font")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text("Adjust ascender and descender by looking at the preview and changing the sliders")
                .foregroundStyle(.secondary)
                .font(.system(size: 12, weight: .regular, design: .rounded))

            metricSlider(
                title: "Ascender:",
                baseValue: model.ascender,
                offset: $model.ascenderOffset
            )
            .padding(.top)

            metricSlider(
                title: "Descender:",
                baseValue: model.descender,
                offset: $model.descenderOffset
            )
            .padding(.top, 8)

            Divider()
                .padding(.vertical)

            Text("Preview")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            TextField("Custom Text", text: $model.customText, prompt: Text("Custom Text"))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                Text("Preview Size")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                Slider(
                    value: $model.scale,
                    in: 0.5...1.5,
                    step: 0.01
                )
            }
            .padding(.top, 8)

            Spacer()

            HStack {
                Button("Clear") {
                    model.clear()
                }
                Spacer()
                Button("Apply") {
                    model.apply()
                }
            }
        }
    }

    @ViewBuilder
    private func metricSlider(
        title: String,
        baseValue: CGFloat,
        offset: Binding<CGFloat>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(title) \(model.pointsToUnits(baseValue + offset.wrappedValue))")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)

            Slider(
                value: offset,
                in: -100...100,
                step: 0.5
            )
        }
    }
}
