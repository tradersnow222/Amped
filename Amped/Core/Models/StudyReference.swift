import Foundation

/// Represents a scientific research reference for impact calculations
struct StudyReference: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let authors: String
    let journalName: String
    let publicationYear: Int
    let doi: String?
    let url: URL?
    let summary: String
    
    /// Standard initialization
    init(
        id: UUID = UUID(),
        title: String,
        authors: String,
        journalName: String,
        publicationYear: Int,
        doi: String? = nil,
        url: URL? = nil,
        summary: String
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.journalName = journalName
        self.publicationYear = publicationYear
        self.doi = doi
        self.url = url
        self.summary = summary
    }
    
    /// Returns a formatted citation string
    var citation: String {
        "\(authors) (\(publicationYear)). \(title). \(journalName)."
    }
    
    /// Returns a short citation string
    var shortCitation: String {
        let authorComponents = authors.components(separatedBy: ",")
        let firstAuthor = authorComponents.first ?? "Unknown"
        
        if authorComponents.count > 1 {
            return "\(firstAuthor) et al., \(publicationYear)"
        } else {
            return "\(firstAuthor), \(publicationYear)"
        }
    }
    
    static func == (lhs: StudyReference, rhs: StudyReference) -> Bool {
        lhs.id == rhs.id
    }
} 