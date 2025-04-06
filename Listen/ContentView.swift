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
    @Query private var audioFiles: [AudioFile]
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPickerPresented = false
    @State private var currentlyPlaying: UUID?
    @State private var showDeleteAlert = false
    @State private var filesToDelete: IndexSet?
    
    var body: some View {
        NavigationView {
            VStack {
                if audioFiles.isEmpty {
                    emptyStateView
                } else {
                    fileListView
                }
                
                importButton
            }
            .navigationTitle("My MP3 Player")
            .toolbar {
                if !audioFiles.isEmpty {
                    EditButton()
                }
            }
            .alert("Delete Files", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteConfirmedFiles()
                }
            } message: {
                Text("Are you sure you want to delete these files?")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No MP3s Imported")
                .font(.title2)
                .foregroundColor(.gray)
            Text("Tap the import button below to add your music")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    private var fileListView: some View {
        List {
            ForEach(audioFiles) { file in
                AudioFileRow(
                    file: file,
                    isPlaying: currentlyPlaying == file.id,
                    action: { playAudio(file: file) }
                )
            }
            .onDelete(perform: confirmDeleteFiles)
        }
        .listStyle(.plain)
    }
    
    private var importButton: some View {
        Button(action: { isPickerPresented = true }) {
            Label("Import MP3", systemImage: "square.and.arrow.down")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
        }
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [.mp3],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result: result)
        }
    }
    
    private func playAudio(file: AudioFile) {
        // Stop currently playing audio if any
        audioPlayer?.stop()
        
        guard let url = URL(string: file.fileURL) else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            
            // Update playback stats
            withAnimation {
                currentlyPlaying = file.id
                file.lastPlayed = Date()
                file.playCount += 1
            }
        } catch {
            print("Playback error: \(error.localizedDescription)")
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                // Check if file already exists
                if !audioFiles.contains(where: { $0.fileURL == url.absoluteString }) {
                    let newFile = AudioFile(fileURL: url)
                    modelContext.insert(newFile)
                }
            }
        case .failure(let error):
            print("File import error: \(error.localizedDescription)")
        }
    }
    
    private func confirmDeleteFiles(_ offsets: IndexSet) {
        filesToDelete = offsets
        showDeleteAlert = true
    }
    
    private func deleteConfirmedFiles() {
        guard let indices = filesToDelete else { return }
        
        for index in indices {
            let file = audioFiles[index]
            // Stop playback if deleting currently playing file
            if currentlyPlaying == file.id {
                audioPlayer?.stop()
                currentlyPlaying = nil
            }
            modelContext.delete(file)
        }
        
        filesToDelete = nil
    }
}

struct AudioFileRow: View {
    let file: AudioFile
    let isPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isPlaying ? "play.fill" : "music.note")
                    .foregroundColor(isPlaying ? .blue : .primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.fileName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        if let lastPlayed = file.lastPlayed {
                            Text("Last played: \(lastPlayed.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                        }
                        
                        Spacer()
                        
                        Text("\(file.playCount) plays")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isPlaying {
                    PlayingIndicator()
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct PlayingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach([0.2, 0.4, 0.6], id: \.self) { height in
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 3, height: isAnimating ? 15 * height : 5)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 15, height: 15)
        .onAppear { isAnimating = true }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AudioFile.self, inMemory: true)
}
