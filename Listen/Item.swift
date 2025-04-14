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
    
    func rename(to newName: String) throws {
           guard let originalURL = self.fileURL else { throw RenameError.fileNotFound }
           guard !newName.isEmpty else { throw RenameError.invalidName }
           guard newName != fileName else { return } // No change needed
           
           let fileExtension = (fileName as NSString).pathExtension
           let newFileName = (newName as NSString).deletingPathExtension + "." + fileExtension
           
           let documentsURL = FileManager.default.urls(
               for: .documentDirectory,
               in: .userDomainMask
           ).first!
           
           let newURL = documentsURL.appendingPathComponent(newFileName)
           
           // Check if new name already exists
           if FileManager.default.fileExists(atPath: newURL.path) {
               throw RenameError.nameExists
           }
           
           // Perform the actual file system rename
           try FileManager.default.moveItem(at: originalURL, to: newURL)
           
           // Update model properties
           self.fileName = newFileName
       }
    
    enum RenameError: Error, LocalizedError {
        case fileNotFound
        case invalidName
        case nameExists
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound: return "Original file not found"
            case .invalidName: return "Please enter a valid name"
            case .nameExists: return "A file with this name already exists"
            }
        }
    }
}
