import SwiftUI

struct VMConsoleView: View {
    @ObservedObject var vmManager: VMManager
    @State private var inputText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(vmManager.consoleOutput)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .textSelection(.enabled)
                        .id("consoleBottom")
                }
                .background(Color.black)
                .foregroundColor(.green)
                .onChange(of: vmManager.consoleOutput) { _ in
                    proxy.scrollTo("consoleBottom", anchor: .bottom)
                }
            }

            HStack {
                TextField("Type command...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit {
                        sendInput()
                    }
                Button("Send") {
                    sendInput()
                }
            }
            .padding(8)
        }
    }

    private func sendInput() {
        let text = inputText + "\n"
        vmManager.sendToConsole(text)
        inputText = ""
    }
}
