
import Foundation

struct AccoladeCategory: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
    let imageCaption: String
    let items: [String]
    
    let imageOffset: CGFloat
}

