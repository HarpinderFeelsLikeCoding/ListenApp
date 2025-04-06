//
//  ContentView.swift
//  Listen
//
//  Created by Harpinder Singh on 4/5/25.
//

import SwiftUI
import SwiftData
import AVFoundation
import Combine  // Add this line with other imports

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AudioFile.dateAdded, order: .reverse) private var audioFiles: [AudioFile]
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPickerPresented = false
    @State private var currentlyPlaying: UUID?
    @State private var showDeleteAlert = false
    @State private var filesToDelete: IndexSet?
    @State private var playbackProgress: Double = 0
    @State private var isPlaying = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if audioFiles.isEmpty {
                    emptyStateView
                } else {
                    fileListView
                }
                
                importButton
                
                if currentlyPlaying != nil {
                    playbackControls
                }
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
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
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
    
    private var playbackControls: some View {
        VStack {
            ProgressView(value: playbackProgress, total: 1.0)
                .padding(.horizontal)
            
            HStack {
                Button(action: { togglePlayback() }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                
                Spacer()
                
                Text(timeString(time: audioPlayer?.currentTime ?? 0))
                    .font(.caption.monospacedDigit())
                
                Spacer()
                
                Text(timeString(time: audioPlayer?.duration ?? 0))
                    .font(.caption.monospacedDigit())
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Audio Functions
    
    private func playAudio(file: AudioFile) {
        guard let url = file.fileURL else {
            showError(message: "File location invalid")
            return
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            showError(message: "File not found: \(url.lastPathComponent)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            // ... rest of your playback logic ...
        } catch {
            showError(message: "Couldn't play \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
    
    private func setupPlaybackTimer() {
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak audioPlayer] _ in
                guard let player = audioPlayer else { return }
                playbackProgress = player.currentTime / player.duration
                if !player.isPlaying {
                    isPlaying = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }
    
    // MARK: - File Management
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                // Start security-scoped access
                guard url.startAccessingSecurityScopedResource() else {
                    showError(message: "Couldn't access file: \(url.lastPathComponent)")
                    continue
                }
                
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    // Copy to app's documents directory
                    let newURL = try copyToDocumentsDirectory(sourceURL: url)
                    
                    // Create new AudioFile with the local URL
                    let newFile = AudioFile(fileURL: newURL)
                    
                    // Check for duplicates by filename
                    if !audioFiles.contains(where: { $0.fileName == newFile.fileName }) {
                        modelContext.insert(newFile)
                    }
                } catch {
                    showError(message: "Failed to import \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        case .failure(let error):
            showError(message: error.localizedDescription)
        }
    }
    
    private func copyToDocumentsDirectory(sourceURL: URL) throws -> URL {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let destinationURL = documentsURL.appendingPathComponent(sourceURL.lastPathComponent)
        
        // Delete if already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        // Perform the copy
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        
        return destinationURL
    }
    
    private func confirmDeleteFiles(_ offsets: IndexSet) {
        filesToDelete = offsets
        showDeleteAlert = true
    }
    
    private func deleteConfirmedFiles() {
        guard let indices = filesToDelete else { return }
        
        for index in indices {
            let file = audioFiles[index]
            
            // Delete physical file
            if let url = file.fileURL {
                try? FileManager.default.removeItem(at: url)
            }
            
            // Delete from database
            modelContext.delete(file)
            
            // Stop playback if deleting current file
            if currentlyPlaying == file.id {
                audioPlayer?.stop()
                currentlyPlaying = nil
                isPlaying = false
            }
        }
        
        filesToDelete = nil
    }
    
    // MARK: - Helpers
    
    private func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    private func timeString(time: TimeInterval) -> String {
        let minute = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minute, seconds)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Subcomponents

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
