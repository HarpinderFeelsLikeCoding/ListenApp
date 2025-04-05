//
//  ContentView.swift
//  Listen
//
//  Created by Harpinder Singh on 4/5/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct ContentView: View {
    @State private var mp3Files: [URL] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPickerPresented = false

    var body: some View {
        NavigationView {
            VStack {
                if mp3Files.isEmpty {
                    Text("No MP3s Selected")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(mp3Files, id: \.self) { fileURL in
                            Button(action: {
                                playAudio(url: fileURL)
                            }) {
                                HStack {
                                    Image(systemName: "music.note")
                                    Text(fileURL.lastPathComponent)
                                }
                            }
                        }
                    }
                }

                Button(action: {
                    isPickerPresented = true
                }) {
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
                    switch result {
                    case .success(let urls):
                        mp3Files.append(contentsOf: urls)
                    case .failure(let error):
                        print("File import error: \(error.localizedDescription)")
                    }
                }
            }
            .navigationTitle("My MP3 Player")
        }
    }

    func playAudio(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Playback error: \(error.localizedDescription)")
        }
    }
}

