//
//  ControlButtonsView.swift
//  Listen
//
//  Created by Harpinder Singh on 5/9/25.
//

// ControlButtonsView.swift
struct ControlButtonsView: View {
    @ObservedObject var player: AudioPlayerManager
    @Binding var isPlaying: Bool
    
    var body: some View {
        HStack {
            Button(action: { player.skip(seconds: -5) }) {
                Image(systemName: "gobackward.5")
                    .font(.title2)
            }
            
            Button(action: { player.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.title2)
            }
            
            Spacer()
            
            Button(action: { player.togglePlayback() }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 40))
            }
            
            Spacer()
            
            Button(action: { player.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            
            Button(action: { player.skip(seconds: 5) }) {
                Image(systemName: "goforward.5")
                    .font(.title2)
            }
        }
        .padding(.horizontal)
    }
}
