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
                // Edit button (shown when files exist)
                if !audioFiles.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
                
                // Playback controls (shown when a track is playing)
                if currentlyPlaying != nil {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button(action: previousTrack) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 20))
                        }
                        .disabled(currentlyPlaying == nil)
                        
                        Spacer()
                        
                        Button(action: togglePlayback) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                        }
                        
                        Spacer()
                        
                        Button(action: nextTrack) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 20))
                        }
                        .disabled(currentlyPlaying == nil)
                    }
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
            .alert("Playback Error", isPresented: $showErrorAlert) {
                Button("OK") {}
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
                Button(action: togglePlayback) {
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
    
    private var playbackToolbar: some View {
        Group {
            Button(action: previousTrack) {
                Image(systemName: "backward.fill")
            }
            
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            
            Button(action: nextTrack) {
                Image(systemName: "forward.fill")
            }
        }
    }
    
    // MARK: - Audio Functions
    
    private func playAudio(file: AudioFile) {
        audioPlayer?.stop()
        isPlaying = false
        
        guard let url = URL(string: file.fileURL) else {
            errorMessage = "Invalid file URL"
            showErrorAlert = true
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = makePlayerDelegate()
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            
            // Update progress timer
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                guard let player = audioPlayer else {
                    timer.invalidate()
                    return
                }
                playbackProgress = player.currentTime / player.duration
                if !player.isPlaying {
                    timer.invalidate()
                    isPlaying = false
                }
            }
            
            withAnimation {
                currentlyPlaying = file.id
                file.lastPlayed = Date()
                file.playCount += 1
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func makePlayerDelegate() -> AVAudioPlayerDelegate {
        class Delegate: NSObject, AVAudioPlayerDelegate {
            var onFinish: (() -> Void)?
            
            func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
                onFinish?()
            }
        }
        
        let delegate = Delegate()
        delegate.onFinish = {
            self.isPlaying = false
            self.playbackProgress = 1.0
        }
        return delegate
    }
    
    private func togglePlayback() {
        guard audioPlayer != nil else { return }
        
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }
    
    private func previousTrack() {
        guard let currentId = currentlyPlaying,
              let index = audioFiles.firstIndex(where: { $0.id == currentId }) else { return }
        
        let prevIndex = index > 0 ? index - 1 : audioFiles.count - 1
        playAudio(file: audioFiles[prevIndex])
    }
    
    private func nextTrack() {
        guard let currentId = currentlyPlaying,
              let index = audioFiles.firstIndex(where: { $0.id == currentId }) else { return }
        
        let nextIndex = index < audioFiles.count - 1 ? index + 1 : 0
        playAudio(file: audioFiles[nextIndex])
    }
    
    // MARK: - File Management
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                if !audioFiles.contains(where: { $0.fileURL == url.absoluteString }) {
                    let newFile = AudioFile(fileURL: url)
                    modelContext.insert(newFile)
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showErrorAlert = true
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
            if currentlyPlaying == file.id {
                audioPlayer?.stop()
                currentlyPlaying = nil
                isPlaying = false
            }
            modelContext.delete(file)
        }
        
        filesToDelete = nil
    }
    
    // MARK: - Helpers
    
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
