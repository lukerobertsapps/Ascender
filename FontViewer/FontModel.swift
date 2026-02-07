//
//  FontModel.swift
//  FontViewer
//
//  Created by Luke Roberts on 07/02/2026.
//

import SwiftUI
import CoreText
import Combine
import UniformTypeIdentifiers

final class FontModel: ObservableObject {
    @Published var ctFont: CTFont?

    @Published var ascender: CGFloat = 0
    @Published var descender: CGFloat = 0

    @Published var ascenderOffset: CGFloat = 0
    @Published var descenderOffset: CGFloat = 0

    @Published var fontSize: CGFloat = 42

    @Published var showingMissingTools = false

    var unitsPerEm: UInt32 = 0
    var cachedURL: URL?

    var convertedAscender: Int {
        pointsToUnits(ascender + ascenderOffset)
    }
    var convertedDescender: Int {
        pointsToUnits(descender + descenderOffset)
    }

    func loadFont(from url: URL? = nil) {
        guard
            let fontURL = url ?? cachedURL,
            let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as? [CTFontDescriptor],
            let descriptor = descriptors.first
        else {
            print("Failed to load font")
            return
        }

        let font = CTFontCreateWithFontDescriptor(descriptor, fontSize, nil)
        ctFont = font

        ascender = CTFontGetAscent(font)
        descender = -CTFontGetDescent(font)

        if url != nil {
            ascenderOffset = 0
            descenderOffset = 0
        }

        self.unitsPerEm = CTFontGetUnitsPerEm(font)
        self.cachedURL = fontURL
    }

    func checkFontToolsInstalled() {
        let fontTools = locateExecutable()
        showingMissingTools = fontTools == nil
    }

    func apply() {
        do {
            try applyChangeToFont()
        } catch {
            print(error)
        }
    }

    func pointsToUnits(_ points: CGFloat) -> Int {
        Int(round(points / fontSize * CGFloat(unitsPerEm)))
    }

    private func applyChangeToFont() throws {
        let tempRoot = FileManager.default.temporaryDirectory
        let workDir = tempRoot.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: workDir,
            withIntermediateDirectories: true
        )

        guard let cachedURL else { return }
        let tempFontURL = workDir.appendingPathComponent(cachedURL.lastPathComponent)
        try FileManager.default.copyItem(at: cachedURL, to: tempFontURL)

        guard let toolURL = locateExecutable() else {
            print("ftxdumperfuser not found")
            return
        }

        try runFTX(toolURL: toolURL, fontURL: tempFontURL)
        let fontBaseName = tempFontURL.deletingPathExtension().lastPathComponent
        let hheaFileName = "\(fontBaseName).hhea.xml"
        let hheaURL = workDir.appendingPathComponent(hheaFileName)

        var contents = try String(contentsOf: hheaURL, encoding: .utf8)
        contents = contents.replacingOccurrences(
            of: #"ascender="[-\d]+""#,
            with: #"ascender="\#(convertedAscender)""#,
            options: .regularExpression
        )
        contents = contents.replacingOccurrences(
            of: #"descender="[-\d]+""#,
            with: #"descender="\#(convertedDescender)""#,
            options: .regularExpression
        )
        try contents.write(to: hheaURL, atomically: true, encoding: .utf8)

        try runFTX(toolURL: toolURL, fontURL: tempFontURL, recombine: true)
        promptToSaveFont(finalFontURL: tempFontURL, suggestedName: tempFontURL.lastPathComponent) {
            try? FileManager.default.removeItem(at: workDir)
        }
    }

    func promptToSaveFont(
        finalFontURL: URL,
        suggestedName: String,
        cleanup: @escaping () -> Void
    ) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.font]
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let destinationURL = panel.url else {
                return
            }

            do {
                try FileManager.default.copyItem(
                    at: finalFontURL,
                    to: destinationURL
                )
                cleanup()
            } catch {
                print("Failed to save font:", error)
            }
        }
    }

    func locateExecutable() -> URL? {
        let candidates = [
            "/opt/homebrew/bin/ftxdumperfuser",
            "/usr/local/bin/ftxdumperfuser",
            "/usr/bin/ftxdumperfuser",
            "/Library/Apple/usr/bin/ftxdumperfuser"
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }

    func runFTX(
        toolURL: URL,
        fontURL: URL,
        recombine: Bool = false
    ) throws {
        let process = Process()
        process.executableURL = toolURL
        let arg = recombine ? "f" : "d"
        process.arguments = [
            "-t", "hhea",
            "-A", arg,
            fontURL.path
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        _ = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let error = String(decoding: errorData, as: UTF8.self)
            throw NSError(
                domain: "FTXError",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: error]
            )
        }
    }

    func clear() {
        self.ctFont = nil
        self.cachedURL = nil
    }
}
