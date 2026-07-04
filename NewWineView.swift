import SwiftUI

struct NewWineView: View {
    @StateObject private var viewModel = NewWineViewModel()
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Wine") {
                    TextField("Name", text: $viewModel.name)
                    Picker("Type", selection: $viewModel.type) {
                        ForEach(WineType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    TextField("Vintage", text: $viewModel.vintage)
                        .keyboardType(.numberPad)
                    TextField("Country", text: $viewModel.country)
                    TextField("Region", text: $viewModel.region)
                    Stepper("Quantity: \(viewModel.quantity)", value: $viewModel.quantity, in: 1...100)
                }

                Section("Grape Varieties") {
                    ForEach(viewModel.grapeVarieties.indices, id: \.self) { index in
                        TextField("Grape variety", text: $viewModel.grapeVarieties[index])
                    }
                    .onDelete { viewModel.grapeVarieties.remove(atOffsets: $0) }

                    Button {
                        viewModel.grapeVarieties.append("")
                    } label: {
                        Label("Add grape variety", systemImage: "plus.circle")
                    }
                }

                Section("Storage & Purchase Location") {
                    Picker("Storage Location", selection: $viewModel.storageLocation) {
                        Text("Home").tag(StorageLocation.home)
                        Text("Cellar").tag(StorageLocation.cellar)
                    }
                    Picker("Purchase Location", selection: $viewModel.purchaseLocation) {
                        ForEach(PurchaseLocation.allCases, id: \.self) { location in
                            Text(location.displayName).tag(location)
                        }
                    }
                    if viewModel.purchaseLocation == .other {
                        TextField("Where did you buy it?", text: $viewModel.purchaseLocationOtherText)
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Wine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.save() {
                                onSaved()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .disabled(viewModel.isSaving)
            .overlay {
                if viewModel.isSaving {
                    ProgressView("Saving…")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

#Preview {
    NewWineView(onSaved: {})
}
