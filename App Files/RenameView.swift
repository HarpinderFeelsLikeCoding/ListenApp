//
//  RenameView.swift
//  Listen
//
//  Created by Harpinder Singh on 4/14/25.
//

import SwiftUI

struct RenameView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var file: AudioFile
    @State private var newName: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("File name", text: $newName)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                        
                        if !file.fileExtension.isEmpty {
                            Text(".\(file.fileExtension)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("New Name")
                } footer: {
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Rename") {
                        renameFile()
                    }
                    .disabled(!isNameValid)
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
            .onAppear {
                newName = file.displayName
            }
            .alert("Rename Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isNameValid: Bool {
        !newName.isEmpty &&
        !newName.contains("/") &&
        !newName.contains(":") &&
        newName != file.displayName
    }
    
    private func renameFile() {
        do {
            try file.rename(to: newName)
            dismiss()
        } catch let error as AudioFile.RenameError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = "An unexpected error occurred"
            showError = true
        }
    }
}
