//
//  AudioPlayerManager.swift
//  Listen
//
//  Created by Harpinder Singh on 5/9/25.
//

import AVFoundation
import Combine

final class AudioPlayerManager: NSObject, ObservableObject {
    @Published var currentFile: AudioFile?
    @Published var isPlaying = false
    @Published var playbackProgress: Double = 0
    @Published var currentTime: TimeInterval = 0
    
    private var player: AVAudioPlayer?
    private var cancellables = Set<AnyCancellable>()
    
    func togglePlayback(for file: AudioFile) {
        if currentFile?.id == file.id {
            togglePlayback()
        } else {
            play(file: file)
        }
    }
    
    func play(file: AudioFile) {
        do {
            stop()
            
            guard file.fileExists else {
                throw NSError(domain: "AudioError", code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "File not found"])
            }
            
            player = try AVAudioPlayer(contentsOf: file.fileURL)
            player?.delegate = self
            player?.currentTime = file.lastPlaybackPosition
            player?.prepareToPlay()
            
            currentFile = file
            play()
            
            setupPlaybackTimer()
        } catch {
            print("Playback error: \(error.localizedDescription)")
        }
    }
    
    func togglePlayback() {
        guard let player = player else { return }
        
        if player.isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func skip(seconds: Double) {
        guard let player = player else { return }
        player.currentTime = max(0, min(player.duration, player.currentTime + seconds))
    }
    
    private func play() {
        player?.play()
        isPlaying = true
    }
    
    private func pause() {
        player?.pause()
        isPlaying = false
        saveCurrentPosition()
    }
    
    private func stop() {
        player?.stop()
        isPlaying = false
        saveCurrentPosition()
    }
    
    private func saveCurrentPosition() {
        guard let player = player, let file = currentFile else { return }
        file.lastPlaybackPosition = player.currentTime
    }
    
    private func setupPlaybackTimer() {
        cancellables.removeAll()
        
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let player = self.player else { return }
                
                self.currentTime = player.currentTime
                self.playbackProgress = player.duration > 0 ?
                    player.currentTime / player.duration : 0
                
                if !player.isPlaying && self.isPlaying {
                    self.isPlaying = false
                }
            }
            .store(in: &cancellables)
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        playbackProgress = 1.0
        saveCurrentPosition()
    }
}
