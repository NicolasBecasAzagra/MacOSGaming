import SwiftUI
import AppKit

public struct TerminalConsoleView: View {
    public let text: String
    public let placeholder: String

    public init(text: String, placeholder: String = "No hay registros de ejecución activos.") {
        self.text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.red.opacity(0.8)).frame(width: 10, height: 10)
                    Circle().fill(Color.yellow.opacity(0.8)).frame(width: 10, height: 10)
                    Circle().fill(Color.green.opacity(0.8)).frame(width: 10, height: 10)
                }
                Spacer()
                Text("CONSOLA DE SALIDA")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: copyToClipboard) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Copiar registros al portapapeles")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))

            Divider()

            ScrollViewReader { proxy in
                ScrollView([.vertical, .horizontal]) {
                    Text(text.isEmpty ? placeholder : text)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(text.isEmpty ? .secondary : Color(NSColor.textColor))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .id("bottom")
                }
                .frame(minHeight: 180, maxHeight: 300)
                .background(Color(NSColor.textBackgroundColor).opacity(0.95))
                .onChange(of: text) { _, _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
