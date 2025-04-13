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
    
    init() {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Audio session setup error: \(error)")
            }
        }
    
    var modelContainer: ModelContainer {
        do {
            let schema = Schema([
                AudioFile.self
            ])
            
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fallback to in-memory container if persistent storage fails
            modelError = ModelError(error: error)
            showErrorAlert = true
            
            do {
                let inMemoryConfig = ModelConfiguration(
                    schema: Schema([AudioFile.self]),
                    isStoredInMemoryOnly: true
                )
                return try ModelContainer(for: AudioFile.self, configurations: inMemoryConfig)
            } catch {
                // Only fatal error if even in-memory fails
                fatalError("Failed to create model container: \(error.localizedDescription)")
            }
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
        .modelContainer(modelContainer)
    }
}

struct ModelError: LocalizedError {
    let error: Error
    
    var errorDescription: String? {
        """
        Could not load persistent storage.
        Using temporary in-memory storage.
        
        Error: \(error.localizedDescription)
        """
    }
    
    var recoverySuggestion: String? {
        "Restart the app to try again. Some data may not be saved between sessions."
    }
}
