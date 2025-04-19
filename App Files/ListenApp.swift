//
//  ListenApp.swift
//  Listen
//
//  Created by Harpinder Singh on 4/5/25.
//

import SwiftUI
import SwiftData
import AVFAudio

@main
struct ListenApp: App {
    @State private var modelError: ModelError?
    @State private var showErrorAlert = false
    let container: ModelContainer
    
    init() {
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session configuration error: \(error)")
        }
        
        // Configure SwiftData container
        do {
            container = try ModelContainer(for: AudioFile.self)
        } catch {
            modelError = ModelError(error: error)
            showErrorAlert = true
            container = try! ModelContainer(for: AudioFile.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .alert("Database Error", isPresented: $showErrorAlert) {
                    Button("OK") { }
                } message: {
                    Text(modelError?.localizedDescription ?? "An unknown error occurred")
                }
        }
        .modelContainer(container)
    }
}

struct ModelError: LocalizedError {
    let error: Error
    
    var errorDescription: String? {
        "Database Error: \(error.localizedDescription)"
    }
    
    var recoverySuggestion: String? {
        "Using temporary storage. Some data may not persist between sessions."
    }
}
