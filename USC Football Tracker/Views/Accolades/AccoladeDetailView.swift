import SwiftUI

struct AccoladeDetailView: View {

    let category: AccoladeCategory

    var body: some View {

        List {
            ForEach(category.items, id: \.self) { item in
                Text(item)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
