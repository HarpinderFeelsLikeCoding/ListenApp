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
    var fileURL: String // Store the path as string
    var dateAdded: Date
    var lastPlayed: Date?
    var playCount: Int
    
    init(fileURL: URL) {
        self.id = UUID()
        self.fileName = fileURL.lastPathComponent
        self.fileURL = fileURL.absoluteString
        self.dateAdded = Date()
        self.playCount = 0
    }
}
