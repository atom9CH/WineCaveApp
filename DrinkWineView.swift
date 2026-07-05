import SwiftUI
import PhotosUI

struct DrinkWineView: View {
    @StateObject private var viewModel: DrinkWineViewModel
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(wineId: UUID, currentQuantity: Int, onSaved: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: DrinkWineViewModel(wineId: wineId, currentQuantity: currentQuantity))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Rating") {
                    HStack(spacing: 8) {
                        ForEach(0...5, id: \.self) { star in
                            Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
                                .font(.system(size: 24))
                                .foregroundStyle(star <= viewModel.rating ? .yellow : .secondary)
                                .onTapGesture {
                                    viewModel.rating = star
                                }
                        }
                        Spacer()
                        Text("\(viewModel.rating)/5")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Tasting Note") {
                    TextEditor(text: $viewModel.note)
                        .frame(minHeight: 100)
                }

                Section("Photo (optional)") {
                    if let image = viewModel.selectedImage {
                        HStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Spacer()
                            Button(role: .destructive) {
                                viewModel.selectedImage = nil
                                selectedPhotoItem = nil
                            } label: {
                                Text("Remove")
                            }
                        }
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Add Photo", systemImage: "camera")
                        }
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
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle("Drink a Bottle")
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
                    .disabled(viewModel.isSaving)
                }
            }
            .disabled(viewModel.isSaving)
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.selectedImage = uiImage
                    }
                }
            }
        }
    }
}
