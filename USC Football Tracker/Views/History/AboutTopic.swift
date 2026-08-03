import Foundation
struct AboutTopic: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let backTitle: String
    let facts: [String]
}
