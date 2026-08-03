import SwiftUI

struct AboutFlipCard: View {
    let topic: AboutTopic
    @State private var isFlipped = false

    var body: some View {
        ZStack {
            frontFace
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

            backFace
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(height: 220)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isFlipped)
        .onTapGesture {
            isFlipped.toggle()
        }
    }

    private var frontFace: some View {
        ZStack(alignment: .bottomLeading) {
            Image(topic.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .bottom) {
                Text(topic.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill")
                    Text("Flip")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding()
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.uscCardinal.opacity(0.15), lineWidth: 1)
        )
        .shadow(radius: 3, y: 2)
    }

    private var backFace: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(topic.backTitle)
                .font(.title3.bold())
                .foregroundStyle(.uscCardinal)

            Divider()

            ForEach(topic.facts, id: \.self) { fact in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .padding(.top, 7)

                    Text(fact)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 10)

            HStack {
                Spacer()

                Image("uscLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                    .opacity(0.85)

                Text("✌️ Fight On!")
                    .font(.headline.bold())
                    .foregroundStyle(.uscCardinal)

                Spacer()
            }

            Text("Tap anywhere to flip back")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    AboutFlipCard(
        topic: AboutTopic(
            title: "History",
            imageName: "championship_2004",
            backTitle: "USC Football History",
            facts: [
                "USC played its first football season in 1888.",
                "Howard Jones helped turn USC into a national power in the 1920s and 1930s.",
                "The program has stayed one of the most recognizable names in college football for more than a century."
            ]
        )
    )
    .padding()
    .background(Color.appBackground)
}
