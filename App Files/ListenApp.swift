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
    @State private var audioError: AudioError?
    @State private var showErrorAlert = false
    
    let container: ModelContainer
    
    init() {
        // Initialize container first
        do {
            container = try ModelContainer(for: AudioFile.self)
        } catch {
            modelError = ModelError(error: error)
            showErrorAlert = true
            
            // Fallback container
            container = try! ModelContainer(
                for: AudioFile.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
        
        // Then setup audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetoothA2DP, .interruptSpokenAudioAndMixWithOthers]
            )
            try session.setActive(true)
        } catch {
            audioError = AudioError(error: error)
            showErrorAlert = true
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .errorAlert(
                    isPresented: $showErrorAlert,
                    title: modelError != nil ? "Database Error" : "Audio Error",
                    message: modelError?.localizedDescription ?? audioError?.localizedDescription ?? "Unknown error"
                )
        }
        .modelContainer(container)
    }
}

struct ModelError: LocalizedError {
    let error: Error
    
    var errorDescription: String? {
        "Failed to setup database: \(error.localizedDescription)"
    }
    
    var recoverySuggestion: String? {
        "Using temporary storage. Data may not persist between sessions."
    }
}

struct AudioError: LocalizedError {
    let error: Error
    
    var errorDescription: String? {
        "Audio setup failed: \(error.localizedDescription)"
    }
    
    var recoverySuggestion: String? {
        "Some audio features may not work properly."
    }
}

extension View {
    func errorAlert(isPresented: Binding<Bool>, title: String, message: String?) -> some View {
        alert(title, isPresented: isPresented) {
            Button("OK") { }
        } message: {
            Text(message ?? "An unknown error occurred")
        }
    }
}
