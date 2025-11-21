//
//  PDFStore.swift
//  Vitals
//
//  Created by Ayushi on 2025-10-22.
//

import Foundation
import UniformTypeIdentifiers

struct StoredPDF: Codable, Equatable {
    let id: UUID
    let title: String
    let fileName: String
    let createdAt: Date

    var fileURL: URL {
        PDFStore.shared.directory.appendingPathComponent(fileName)
    }
}

extension Notification.Name {
    static let pdfHistoryDidChange = Notification.Name("pdfHistoryDidChange")
}


/// Super-lightweight file store for PDFs + an index (JSON).
final class PDFStore {
    static let shared = PDFStore()

    // MARK: - Public

    let directory: URL
    private let indexURL: URL
    private var cache: [StoredPDF] = []

    /// True if there are no PDFs in the index.
    var isEmpty: Bool {
        cache.isEmpty
    }

    /// Returns all PDFs sorted by newest first.
    func all() -> [StoredPDF] {
        cache.sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func addPDF(data: Data, title: String) throws -> StoredPDF {
        let id = UUID()
        let fileName = "\(id.uuidString).pdf"
        let url = directory.appendingPathComponent(fileName)

        try data.write(to: url, options: .atomic)

        let entry = StoredPDF(
            id: id,
            title: title,
            fileName: fileName,
            createdAt: Date()
        )

        cache.append(entry)
        saveIndex()
        notifyChanged()
        return entry
    }

    @discardableResult
    func addPDF(from tempURL: URL, title: String) throws -> StoredPDF {
        let data = try Data(contentsOf: tempURL)
        return try addPDF(data: data, title: title)
    }

    func delete(_ item: StoredPDF) {
        let url = directory.appendingPathComponent(item.fileName)
        try? FileManager.default.removeItem(at: url)

        cache.removeAll { $0.id == item.id }
        saveIndex()
        notifyChanged()
    }

    func deleteAll() {
        for item in cache {
            let url = directory.appendingPathComponent(item.fileName)
            try? FileManager.default.removeItem(at: url)
        }
        cache.removeAll()
        saveIndex()
        notifyChanged()
    }

    // MARK: - Init

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask).first!

        self.directory = docs.appendingPathComponent("PDFs", isDirectory: true)
        self.indexURL = directory.appendingPathComponent("index.json")

        do {
            try FileManager.default.createDirectory(at: directory,
                                                    withIntermediateDirectories: true)
        } catch {
            print("⚠️ Failed to create PDFs directory:", error)
        }

        loadIndex()
    }

    // MARK: - Index Handling

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL) else {
            cache = []
            return
        }

        cache = (try? JSONDecoder().decode([StoredPDF].self, from: data)) ?? []

        // IMPORTANT: Don't use $0.fileURL (it used to cause recursion).
        cache = cache.filter {
            let url = directory.appendingPathComponent($0.fileName)
            return FileManager.default.fileExists(atPath: url.path)
        }

        saveIndex()
    }

    private func saveIndex() {
        let sorted = cache.sorted { $0.createdAt > $1.createdAt }
        guard let data = try? JSONEncoder().encode(sorted) else {
            print("⚠️ Failed to encode PDF index")
            return
        }

        do {
            try data.write(to: indexURL, options: .atomic)
        } catch {
            print("⚠️ Failed to write PDF index:", error)
        }
    }

    // MARK: - Notifications

    private func notifyChanged() {
        NotificationCenter.default.post(name: .pdfHistoryDidChange, object: nil)
    }
}

