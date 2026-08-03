import SwiftUI

struct AccoladeCard: View {
    let category: AccoladeCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.title)
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .padding(.horizontal, 2)

            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(.gray.opacity(0.12))

                Image(category.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 190)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .offset(y: category.imageOffset)
                    .clipped()
                

                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(category.imageCaption)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack {
                Text(category.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.uscCardinal.opacity(0.15), lineWidth: 1)
        )
        .shadow(radius: 3, y: 2)
    }
}

#Preview {
    AccoladeCard(
        category: AccoladeCategory(
            title: "Heisman Trophy Winners",
            subtitle: "8 Winners",
            imageName: "reggie_bush_heisman",
            imageCaption: "Reggie Bush • 2005 Heisman Winner",
            items: [], imageOffset: 0
        )
    )
    .padding()
    .background(Color.appBackground)
}
