import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("BookQuotes")
                    .font(.largeTitle)
                    .bold()
                Text("Your quote library starts here.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Library")
        }
    }
}

#Preview {
    ContentView()
}
