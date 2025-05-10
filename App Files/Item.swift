//
//  Item.swift
//  Listen
//
//  Created by Harpinder Singh on 4/5/25.
//
import Foundation
import SwiftData
import AVFoundation

@Model
final class AudioFile: Equatable {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var storedFileName: String
    var dateAdded: Date
    var lastPlayed: Date?
    var playCount: Int = 0
    var lastPlaybackPosition: Double = 0.0
    
    init(fileURL: URL) throws {
        guard !fileURL.lastPathComponent.isEmpty else {
            throw InitializationError.invalidURL
        }
        
        self.id = UUID()
        self.fileName = fileURL.lastPathComponent
        self.storedFileName = fileURL.lastPathComponent
        self.dateAdded = Date()
    }
    
    static func == (lhs: AudioFile, rhs: AudioFile) -> Bool {
        lhs.id == rhs.id
    }
    
    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    var fileURL: URL {
        Self.documentsDirectory.appendingPathComponent(storedFileName)
    }
    
    var fileExtension: String {
        (fileName as NSString).pathExtension.lowercased()
    }
    
    var displayName: String {
        (fileName as NSString).deletingPathExtension
    }
    
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    var fileSize: Int64 {
        guard fileExists,
              let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path) else {
            return 0
        }
        return attrs[.size] as? Int64 ?? 0
    }
    
    var duration: TimeInterval {
        guard fileExists else { return 0 }
        let asset = AVURLAsset(url: fileURL)
        return CMTimeGetSeconds(asset.duration)
    }
    
    func rename(to newName: String) throws {
        let sanitizedName = newName.sanitizedForFilename()
        guard !sanitizedName.isEmpty else {
            throw RenameError.invalidName
        }
        
        let finalName: String
        if !fileExtension.isEmpty {
            finalName = "\(sanitizedName).\(fileExtension)"
        } else {
            finalName = sanitizedName
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
    
    enum InitializationError: Error {
        case invalidURL
    }
}

extension String {
    func sanitizedForFilename() -> String {
        var invalidChars = CharacterSet(charactersIn: "/\\?%*|\"<>")
        invalidChars.formUnion(.newlines)
        invalidChars.formUnion(.controlCharacters)
        
        return self
            .components(separatedBy: invalidChars)
            .joined(separator: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
