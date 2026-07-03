import SwiftUI

struct WineDetailView: View {
    @StateObject private var viewModel: WineDetailViewModel
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void
    @State private var showDeleteConfirmation = false

    init(wine: Wine, onSaved: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: WineDetailViewModel(wine: wine))
        self.onSaved = onSaved
    }

    var body: some View {
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
                Stepper("Quantity: \(viewModel.currentQuantity)", value: $viewModel.currentQuantity, in: 0...100)
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

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete Wine")
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
        .navigationTitle("Edit Wine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .task {
            await viewModel.loadGrapeVarieties()
        }
        .alert("Delete this wine?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.delete() {
                        onSaved()
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
