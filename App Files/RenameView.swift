//
//  RenameView.swift
//  Listen
//
//  Created by Harpinder Singh on 4/14/25.
//

import SwiftUI

struct RenameView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var file: AudioFile
    
    @State private var newName: String = ""
    @State private var errorMessage: String?
    @State private var isRenaming = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("File name", text: $newName)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .disabled(isRenaming)
                        
                        if !file.fileExtension.isEmpty {
                            Text(".\(file.fileExtension)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("New Name")
                } footer: {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Rename") {
                        renameFile()
                    }
                    .disabled(!isNameValid || isRenaming)
                    .overlay {
                        if isRenaming {
                            ProgressView()
                        }
                    }
                }
            }
            .navigationTitle("Rename File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isRenaming)
                }
            }
            .onAppear {
                newName = file.displayName
            }
            .onTapGesture {
                dismissKeyboard()
            }
        }
    }
    
    private var isNameValid: Bool {
        !newName.isEmpty &&
        newName.sanitizedForFilename() == newName &&
        newName != file.displayName
    }
    
    private func renameFile() {
        errorMessage = nil
        isRenaming = true
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // Small delay for smooth UI
                
                try file.rename(to: newName)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                    isRenaming = false
                }
            }
        }
    }
    
    private func handleError(_ error: Error) {
        if let renameError = error as? AudioFile.RenameError {
            errorMessage = renameError.localizedDescription
        } else {
            errorMessage = "An unexpected error occurred"
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
