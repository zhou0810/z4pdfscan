import SwiftUI

struct CreateVMSheet: View {
    @ObservedObject var viewModel: CreateVMViewModel
    var onCreate: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Create New Virtual Machine")
                .font(.headline)
                .padding()

            Form {
                Section("General") {
                    TextField("VM Name", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Hardware") {
                    Stepper(
                        "CPU Cores: \(viewModel.cpuCount)",
                        value: $viewModel.cpuCount,
                        in: 1...viewModel.maxCPU
                    )

                    Stepper(
                        "Memory: \(viewModel.memorySizeMB) MB",
                        value: $viewModel.memorySizeMB,
                        in: 512...viewModel.maxMemoryMB,
                        step: 512
                    )

                    Stepper(
                        "Disk: \(viewModel.diskSizeGB) GB",
                        value: $viewModel.diskSizeGB,
                        in: 1...500,
                        step: 8
                    )
                }

                Section("Display") {
                    Picker("Resolution", selection: $viewModel.displayWidth) {
                        ForEach(CreateVMViewModel.resolutions, id: \.1) { res in
                            Text(res.0).tag(res.1)
                        }
                    }
                    .onChange(of: viewModel.displayWidth) { newWidth in
                        if let match = CreateVMViewModel.resolutions.first(where: { $0.1 == newWidth }) {
                            viewModel.displayHeight = match.2
                        }
                    }
                }

                Section("Boot ISO") {
                    HStack {
                        TextField("ISO Path", text: $viewModel.isoPath)
                            .textFieldStyle(.roundedBorder)
                        Button("Browse...") {
                            viewModel.browseISO()
                        }
                    }
                }

                Section("Shared Folder (Optional)") {
                    HStack {
                        TextField("Folder Path", text: $viewModel.sharedFolderPath)
                            .textFieldStyle(.roundedBorder)
                        Button("Browse...") {
                            viewModel.browseSharedFolder()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding(.horizontal)

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    onCreate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!viewModel.isValid)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
}
