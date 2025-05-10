//
//  AudioFile.swift
//  Listen
//
//  Created by Harpinder Singh on 5/9/25.
//

// AudioFileRow.swift
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
                    Text(file.displayName)
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
            }
        }
        .frame(width: 15, height: 15)
        .onAppear { isAnimating = true }
        .foregroundColor(.blue)
    }
}
