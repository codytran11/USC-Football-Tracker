import SwiftUI

struct AccoladesView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USC Accolades")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.uscCardinal)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)

                        Text("Explore the biggest honors and milestones in USC Football history.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }

                    ForEach(accoladeCategories) { category in
                        NavigationLink {
                            AccoladeDetailView(category: category)
                        } label: {
                            AccoladeCard(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Accolades")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AccoladesView()
}
