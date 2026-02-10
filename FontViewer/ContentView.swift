//
//  ContentView.swift
//  FontViewer
//
//  Created by Luke Roberts on 28/01/2026.
//

import SwiftUI
import CoreText
import Combine
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = FontModel()

    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var showFileImporter = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(model: model)
                .frame(minWidth: 220)
        } detail: {
            ZStack {
                if let font = model.ctFont {
                    VStack {
                        if !model.customText.isEmpty {
                            FontPreviewView(
                                ctFont: font,
                                displayText: model.customText,
                                ascender: model.ascender + model.ascenderOffset,
                                descender: model.descender + model.descenderOffset
                            )
                            .scaleEffect(model.scale)
                        } else {
                            FontPreviewView(
                                ctFont: font,
                                displayText: "abcdefghijklmnopqrstuzwxyz",
                                ascender: model.ascender + model.ascenderOffset,
                                descender: model.descender + model.descenderOffset
                            )
                            .scaleEffect(model.scale)
                            FontPreviewView(
                                ctFont: font,
                                displayText: "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
                                ascender: model.ascender + model.ascenderOffset,
                                descender: model.descender + model.descenderOffset
                            )
                            .scaleEffect(model.scale)
                            FontPreviewView(
                                ctFont: font,
                                displayText: "0123456789",
                                ascender: model.ascender + model.ascenderOffset,
                                descender: model.descender + model.descenderOffset
                            )
                            .scaleEffect(model.scale)
                        }
                    }
                } else {
                    if model.showingMissingTools {
                        missingTools
                    } else {
                        uploadFont
                    }
                }
            }
            .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                handleDrop(providers)
            }
            .onChange(of: model.ctFont) { oldValue, newValue in
                if newValue != nil {
                    columnVisibility = .all
                }
            }
            .onAppear {
                model.checkFontToolsInstalled()
            }
        }
    }

    private var missingTools: some View {
        VStack {
            Image(systemName: "hammer.fill")
                .resizable().scaledToFit().frame(width: 64, height: 64)
                .padding(.bottom)
            Text("Apple font tools are required to use this application")
            Button("Download Tools") {
                let url = URL(string: "https://developer.apple.com/fonts/")!
                if NSWorkspace.shared.open(url) {
                    print("default browser was successfully opened")
                }
            }
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var uploadFont: some View {
        VStack {
            Image(systemName: "arrow.up.document")
                .resizable().scaledToFit().frame(width: 64, height: 64)
                .padding(.bottom)
            Text("Drop a font file (.ttf / .otf) or")
            Button("Select File") {
                showFileImporter = true
            }
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.font]) { result in
                switch result {
                case .success(let success):
                    if success.startAccessingSecurityScopedResource() {
                        model.loadFont(from: success)
                        success.stopAccessingSecurityScopedResource()
                    }

                case .failure(let failure):
                    print("Ohno: \(failure)")
                }
            }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard
                let data = item as? Data,
                let url = URL(dataRepresentation: data, relativeTo: nil)
            else { return }

            DispatchQueue.main.async {
                model.loadFont(from: url)
            }
        }
        return true
    }
}
