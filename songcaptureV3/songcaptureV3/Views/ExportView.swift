// Views/ExportView.swift
import SwiftUI

struct ExportView: View {
    var song: Song
    var aligned: [[AlignedLine]]
    @State private var pdfURL: URL?

    var body: some View {
        HStack(spacing: 16) {
            Button {
                pdfURL = PDFExporter.export(song: song, aligned: aligned)
            } label: {
                Label("Export PDF", systemImage: "doc.richtext")
            }

            if let pdfURL {
                ShareLink(item: pdfURL) {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}
