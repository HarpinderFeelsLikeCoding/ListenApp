//
//  Item.swift
//  Listen
//
//  Created by Harpinder Singh on 4/5/25.
//

import Foundation
import SwiftData

@Model
final class AudioFile {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var storedFileName: String
    var dateAdded: Date
    var lastPlayed: Date?
    
    var playCount: Int = 0
    var lastPlaybackPosition: Double = 0.0
    
    init(fileURL: URL) {
        self.id = UUID()
        self.fileName = fileURL.lastPathComponent
        self.storedFileName = fileURL.lastPathComponent
        self.dateAdded = Date()
    }
    
    var fileURL: URL? {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
        return documentsURL?.appendingPathComponent(storedFileName)
    }
}
