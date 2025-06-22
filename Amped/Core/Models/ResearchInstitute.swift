import Foundation

/// Research institutes that provide scientific backing for the app's algorithms
enum ResearchInstitute: String, CaseIterable {
    case stanford = "Stanford"
    case ucla = "UCLA" 
    case berkeley = "Berkeley"
    case nyu = "NYU"
    
    /// Full name of the institute
    var fullName: String {
        switch self {
        case .stanford:
            return "Stanford University"
        case .ucla:
            return "University of California, Los Angeles"
        case .berkeley:
            return "University of California, Berkeley"
        case .nyu:
            return "New York University"
        }
    }
} 