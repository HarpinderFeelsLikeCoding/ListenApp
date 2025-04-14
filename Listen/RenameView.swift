//
//  RenameView.swift
//  Listen
//
//  Created by Harpinder Singh on 4/14/25.
//

struct RenameView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var file: AudioFile
    @State private var newName: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("File name", text: $newName)
                        .autocorrectionDisabled()
                        .onAppear {
                            newName = (file.fileName as NSString).deletingPathExtension
                        }
                }
                
                Section {
                    Button("Rename") {
                        do {
                            try file.rename(to: newName)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                    .disabled(newName.isEmpty || newName == (file.fileName as NSString).deletingPathExtension)
                }
            }
            .navigationTitle("Rename File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Rename Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}
