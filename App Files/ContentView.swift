//
//  ContentView.swift
//  Listen
//
//  Created by Harpinder Singh on 4/5/25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AudioFile.lastPlayed, order: .reverse) private var audioFiles: [AudioFile]
    
    @StateObject private var playerManager = AudioPlayerManager()
    @State private var isPickerPresented = false
    @State private var showDeleteAlert = false
    @State private var filesToDelete: IndexSet?
    @State private var showRenameSheet = false
    @State private var fileToRename: AudioFile?

    var body: some View {
        NavigationStack {
            VStack {
                if audioFiles.isEmpty {
                    EmptyStateView(importAction: { isPickerPresented = true })
                } else {
                    FileListView(
                        files: audioFiles,
                        currentlyPlaying: playerManager.currentFile?.id,
                        onPlay: { file in playerManager.togglePlayback(for: file) },
                        onRename: { file in
                            fileToRename = file
                            showRenameSheet = true
                        },
                        onDelete: confirmDeleteFiles
                    )
                }
                
                if let currentFile = playerManager.currentFile {
                    PlayerControlsView(
                        player: playerManager,
                        currentFile: currentFile,
                        progress: $playerManager.playbackProgress,
                        isPlaying: $playerManager.isPlaying
                    )
                }
                
                ImportButton(isPresented: $isPickerPresented)
            }
            .navigationTitle("My MP3 Player")
            .toolbar {
                if !audioFiles.isEmpty {
                    EditButton()
                }
            }
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result: result)
            }
            .alert("Delete Files", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteConfirmedFiles()
                }
            }
            .sheet(isPresented: $showRenameSheet) {
                if let file = fileToRename {
                    RenameView(file: file)
                }
            }
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        // Implementation remains same as before
    }
    
    private func confirmDeleteFiles(_ offsets: IndexSet) {
        filesToDelete = offsets
        showDeleteAlert = true
    }
    
    private func deleteConfirmedFiles() {
        // Implementation remains same as before
    }
}

// MARK: - Subviews
struct EmptyStateView: View {
    let importAction: () -> Void
    
    var body: some View {
        ContentUnavailableView(
            "No MP3s Imported",
            systemImage: "music.note.list",
            description: Text("Tap the import button below to add your music")
        )
    }
}

struct FileListView: View {
    let files: [AudioFile]
    let currentlyPlaying: UUID?
    let onPlay: (AudioFile) -> Void
    let onRename: (AudioFile) -> Void
    let onDelete: (IndexSet) -> Void
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("My MP3 Player")
                .toolbar(content: toolbarContent)
                .fileImporter(
                    isPresented: $isPickerPresented,
                    allowedContentTypes: [.audio],
                    allowsMultipleSelection: true,
                    onCompletion: handleFileImport
                )
                .alert("Delete Files", isPresented: $showDeleteAlert, actions: deleteAlertButtons)
                .sheet(item: $fileToRename) { file in
                    RenameView(file: file)
                }
        }
    }

}

struct PlayerControlsView: View {
    @ObservedObject var player: AudioPlayerManager
    let currentFile: AudioFile
    @Binding var progress: Double
    @Binding var isPlaying: Bool
    
    var body: some View {
        VStack {
            ProgressView(value: progress, total: 1.0)
                .padding(.horizontal)
            
            ControlButtonsView(player: player, isPlaying: $isPlaying)
            
            TimeDisplayView(
                currentTime: player.currentTime,
                duration: currentFile.duration
            )
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct ImportButton: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        Button(action: { isPresented = true }) {
            Label("Import MP3", systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding()
        }
    }
}
