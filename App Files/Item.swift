//
//  Item.swift
//  Listen
//
//  Created by Harpinder Singh on 4/5/25.
//
import Foundation
import SwiftData

@Model
final class AudioFile: Equatable {
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
    
    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    var fileURL: URL {
        Self.documentsDirectory.appendingPathComponent(storedFileName)
    }
    
    var fileExtension: String {
        (fileName as NSString).pathExtension
    }
    
    var displayName: String {
        (fileName as NSString).deletingPathExtension
    }
    
    func rename(to newName: String, keepExtension: Bool = true) throws {
        guard fileExists else { throw RenameError.fileNotFound }
        guard !newName.isEmpty else { throw RenameError.invalidName }
        
        let finalName: String
        if keepExtension && !fileExtension.isEmpty {
            finalName = newName + "." + fileExtension
        } else {
            finalName = newName
        }
        
        guard finalName != fileName else { return }
        
        let newURL = Self.documentsDirectory.appendingPathComponent(finalName)
        
        if FileManager.default.fileExists(atPath: newURL.path) {
            throw RenameError.nameExists
        }
        
        try FileManager.default.moveItem(at: fileURL, to: newURL)
        fileName = finalName
        storedFileName = finalName
    }
    
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    func incrementPlayCount() {
        playCount += 1
        lastPlayed = Date()
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
