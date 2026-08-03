import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(spacing: 8) {
                        Text("About USC Football")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.uscCardinal)

                        Text("Explore the traditions, history, and spirit that make USC Football one of the most iconic programs in college football.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)

                    ForEach(aboutTopics) { topic in
                        AboutFlipCard(topic: topic)
                    }

                    VStack(spacing: 12) {
                        Image("uscLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)

                        Text("✌️ Fight On!")
                            .font(.title2.bold())
                            .foregroundStyle(.uscCardinal)

                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AboutView()
}
