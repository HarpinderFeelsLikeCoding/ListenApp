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
    var id: UUID
    var fileName: String
    var storedPath: String  // Changed from fileURL to storedPath
    var dateAdded: Date
    var lastPlayed: Date?
    var playCount: Int
    
    init(fileURL: URL) {
        self.id = UUID()
        self.fileName = fileURL.lastPathComponent
        self.storedPath = fileURL.lastPathComponent  // Just store filename
        self.dateAdded = Date()
        self.playCount = 0
    }
    
    // Computed property to get full URL
    var fileURL: URL? {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
        return documentsURL?.appendingPathComponent(storedPath)
    }
}
