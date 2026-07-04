import SwiftUI

struct ConsumeBottleView: View {
    @StateObject private var viewModel = ConsumeBottleViewModel()
    @Environment(\.dismiss) private var dismiss

    var onFinished: () -> Void

    @State private var wineToConfirm: Wine?
    @State private var showConfirmAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading wines...")
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else if viewModel.wines.isEmpty {
                    Text("No available wines")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(viewModel.wines, id: \.id) { wine in
                            Button {
                                wineToConfirm = wine
                                showConfirmAlert = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(wine.name)
                                            .font(.headline)

                                        HStack(spacing: 6) {
                                            if let vintage = wine.vintage {
                                                Text(String(vintage))
                                            }

                                            Text("• \(wine.currentQuantity) btl")

                                            if let location = wine.storageLocation {
                                                Text("• \(location == .cellar ? "Cellar" : "Home")")
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "wineglass.fill")
                                        .foregroundColor(.accentColor)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                if viewModel.isUpdating {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()

                    ProgressView()
                }
            }
            .navigationTitle("Drink a Bottle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadAvailableWines()
            }
            .disabled(viewModel.isUpdating)
            .alert("Drink this wine?", isPresented: $showConfirmAlert) {
                Button("Drink", role: .destructive) {
                    guard let wine = wineToConfirm else { return }

                    Task {
                        let success = await viewModel.drink(wine)

                        if success {
                            onFinished()
                            dismiss()
                        }
                    }
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                if let wine = wineToConfirm {
                    Text("\(wine.name) – this will reduce the quantity by 1. No rating will be recorded.")
                }
            }
        }
    }
}

#Preview {
    ConsumeBottleView {
        print("Finished")
    }
}
