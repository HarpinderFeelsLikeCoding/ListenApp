//
//  TimeDisplayView.swift
//  Listen
//
//  Created by Harpinder Singh on 5/9/25.
//

// TimeDisplayView.swift
struct TimeDisplayView: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    
    var body: some View {
        HStack {
            Text(timeString(time: currentTime))
            Spacer()
            Text(timeString(time: duration))
        }
        .font(.caption.monospacedDigit())
        .padding(.horizontal)
    }
    
    private func timeString(time: TimeInterval) -> String {
        let minute = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minute, seconds)
    }
}
