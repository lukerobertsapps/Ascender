//
//  FontDrawingView.swift
//  FontViewer
//
//  Created by Luke Roberts on 07/02/2026.
//

import SwiftUI

final class FontDrawingView: NSView {

    var ctFont: CTFont?
    var text: String = ""
    var ascender: CGFloat = 0
    var descender: CGFloat = 0

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let font = ctFont else { return }

        context.setFillColor(NSColor.windowBackgroundColor.cgColor)
        context.fill(bounds)

        context.translateBy(x: 50, y: bounds.midY)
        context.scaleBy(x: 1, y: 1)

        drawGuides(font: font, context: context)
        drawText(font: font, context: context)
    }

    private func drawGuides(font: CTFont, context: CGContext) {
        context.setLineWidth(1)

        context.setStrokeColor(NSColor.gray.cgColor)
        strokeLine(y: 0, context: context)

        context.setStrokeColor(NSColor.blue.cgColor)
        strokeLine(y: ascender, context: context)

        context.setStrokeColor(NSColor.red.cgColor)
        strokeLine(y: descender, context: context)
    }

    private func strokeLine(y: CGFloat, context: CGContext) {
        context.move(to: CGPoint(x: 0, y: y))
        context.addLine(to: CGPoint(x: bounds.width, y: y))
        context.strokePath()
    }

    private func drawText(font: CTFont, context: CGContext) {
        let text = text

        let attrString = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: NSColor.labelColor
            ]
        )

        let line = CTLineCreateWithAttributedString(attrString)
        context.textPosition = CGPoint(x: 0, y: 0)
        CTLineDraw(line, context)
    }
}
