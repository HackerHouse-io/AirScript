import SwiftUI

struct RecommendationBanner: View {
    let modelName: String

    private var ramGB: Int {
        Int(Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024))
    }

    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
            Text("Recommended for your Mac (\(ramGB)GB RAM): **\(modelName)**")
                .font(.subheadline)
        }
        .padding(8)
        .background(.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
