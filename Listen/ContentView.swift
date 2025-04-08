//
//  ContentView.swift
//  Listen
//
//  Created by Harpinder Singh on 4/5/25.
//

import SwiftUI
import SwiftData
import AVFoundation
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
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
    @State private var cancellables = Set<AnyCancellable>()

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
            .onChange(of: scenePhase) { newPhase in
                handleScenePhaseChange(newPhase)
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
                    action: { handlePlayback(for: file) }
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
                // 5-second back button
                Button(action: skipBackward) {
                    Image(systemName: "gobackward.5")
                        .font(.title2)
                }
                
                // Previous track button
                Button(action: previousTrack) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }
                
                Spacer()
                
                // Play/pause button
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                }
                
                Spacer()
                
                // Next track button
                Button(action: nextTrack) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                
                // 5-second forward button
                Button(action: skipForward) {
                    Image(systemName: "goforward.5")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            // Time indicators
            HStack {
                Text(timeString(time: audioPlayer?.currentTime ?? 0))
                Spacer()
                Text(timeString(time: audioPlayer?.duration ?? 0))
            }
            .font(.caption.monospacedDigit())
            .padding(.horizontal)
        }
    }
    
    // MARK: - Playback Functions
    private func skipBackward() {
        guard let player = audioPlayer else { return }
        player.currentTime = max(0, player.currentTime - 5)
        saveCurrentPlaybackPosition()
    }

    private func skipForward() {
        guard let player = audioPlayer else { return }
        player.currentTime = min(player.duration, player.currentTime + 5)
        saveCurrentPlaybackPosition()
    }
    
    private func handlePlayback(for file: AudioFile) {
        if currentlyPlaying == file.id {
            togglePlayback()
        } else {
            playAudio(file: file)
        }
    }
    
    private func playAudio(file: AudioFile) {
        do {
            audioPlayer?.stop()
            
            guard let url = file.fileURL else {
                throw NSError(domain: "AudioError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid file URL"])
            }
            
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw NSError(domain: "AudioError", code: -2, userInfo: [NSLocalizedDescriptionKey: "File not found"])
            }
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = makePlayerDelegate()
            audioPlayer?.currentTime = file.lastPlaybackPosition
            audioPlayer?.prepareToPlay()
            
            if isPlaying {
                audioPlayer?.play()
            }
            
            withAnimation {
                currentlyPlaying = file.id
                file.lastPlayed = Date()
                if !isPlaying {
                    isPlaying = true
                    audioPlayer?.play()
                }
            }
            
            setupPlaybackTimer()
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    private func togglePlayback() {
        guard audioPlayer != nil else { return }
        
        if isPlaying {
            audioPlayer?.pause()
            saveCurrentPlaybackPosition()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }
    
    private func previousTrack() {
        guard let currentId = currentlyPlaying,
              let currentIndex = audioFiles.firstIndex(where: { $0.id == currentId }) else { return }
        
        let previousIndex = currentIndex > 0 ? currentIndex - 1 : audioFiles.count - 1
        playAudio(file: audioFiles[previousIndex])
    }
    
    private func nextTrack() {
        guard let currentId = currentlyPlaying,
              let currentIndex = audioFiles.firstIndex(where: { $0.id == currentId }) else { return }
        
        let nextIndex = currentIndex < audioFiles.count - 1 ? currentIndex + 1 : 0
        playAudio(file: audioFiles[nextIndex])
    }
    
    private func setupPlaybackTimer() {
        cancellables.removeAll()
        
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard let player = self.audioPlayer else { return }
                
                self.playbackProgress = player.currentTime / player.duration
                
                if !player.isPlaying && self.isPlaying {
                    self.isPlaying = false
                }
                
                // Auto-save position periodically
                if Int(player.currentTime) % 5 == 0 {
                    self.saveCurrentPlaybackPosition()
                }
            }
            .store(in: &cancellables)
    }
    
    private func makePlayerDelegate() -> AVAudioPlayerDelegate {
        class Delegate: NSObject, AVAudioPlayerDelegate {
            var onFinish: (() -> Void)?
            
            func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
                onFinish?()
            }
        }
        
        let delegate = Delegate()
        delegate.onFinish = { [currentlyPlaying] in
            // Update state directly without capturing self
            DispatchQueue.main.async {
                self.isPlaying = false
                self.playbackProgress = 1.0
                self.saveCurrentPlaybackPosition()
                
                // Auto-play next track if available
                if let currentId = currentlyPlaying,
                   let currentIndex = self.audioFiles.firstIndex(where: { $0.id == currentId }) {
                    let nextIndex = currentIndex < self.audioFiles.count - 1 ? currentIndex + 1 : 0
                    self.playAudio(file: self.audioFiles[nextIndex])
                }
            }
        }
        return delegate
    }
    
    // MARK: - State Persistence
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .inactive, .background:
            saveCurrentPlaybackPosition()
            audioPlayer?.pause()
        case .active:
            restorePlaybackState()
        @unknown default:
            break
        }
    }
    
    private func saveCurrentPlaybackPosition() {
        guard let player = audioPlayer,
              let currentId = currentlyPlaying,
              let file = audioFiles.first(where: { $0.id == currentId }) else { return }
        
        file.lastPlaybackPosition = player.currentTime
        try? modelContext.save()
    }
    
    private func restorePlaybackState() {
        guard let currentId = currentlyPlaying,
              let file = audioFiles.first(where: { $0.id == currentId }),
              let url = file.fileURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = makePlayerDelegate()
            audioPlayer?.currentTime = file.lastPlaybackPosition
            audioPlayer?.prepareToPlay()
            
            if isPlaying {
                audioPlayer?.play()
                setupPlaybackTimer()
            }
        } catch {
            showError(message: "Failed to restore playback: \(error.localizedDescription)")
        }
    }
    
    // MARK: - File Management
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else {
                    showError(message: "Couldn't access file: \(url.lastPathComponent)")
                    continue
                }
                
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let newURL = try copyToDocumentsDirectory(sourceURL: url)
                    
                    if !audioFiles.contains(where: { $0.fileName == newURL.lastPathComponent }) {
                        let newFile = AudioFile(fileURL: newURL)
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
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
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
            
            if let url = file.fileURL {
                try? FileManager.default.removeItem(at: url)
            }
            
            modelContext.delete(file)
            
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
