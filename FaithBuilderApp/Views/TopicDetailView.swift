import SwiftUI

struct TopicDetailView: View {
    let metadata: TopicMetadata
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(metadata.title)
                    .font(.largeTitle.bold())
                
                Text(metadata.subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                Text("Overview")
                    .font(.headline)
                Text(metadata.description)
                    .font(.body)
                
                // MARK: - Key verses
                if !metadata.keyVerseRefs.isEmpty {
                    Divider()
                    Text("Key verses to explore")
                        .font(.headline)
                    
                    // Show key verses as a simple bullet list (no ForEach)
                    let bulletText = metadata.keyVerseRefs
                        .map { "• \($0)" }
                        .joined(separator: "\n")
                    
                    Text(bulletText)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    
                    // Link the first key verse to an online KJV Bible
                    if let firstRef = metadata.keyVerseRefs.first,
                       let url = BibleLinkBuilder.url(forReference: firstRef) {
                        Link(destination: url) {
                            Label("Open first key verse online (KJV)", systemImage: "safari")
                        }
                        .font(.caption)
                        .padding(.top, 4)
                    }
                }
                
                // MARK: - Starter questions
                if !metadata.starterQuestions.isEmpty {
                    Divider()
                    Text("Starter questions you could ask")
                        .font(.headline)
                    
                    let starterText = metadata.starterQuestions
                        .map { "• \($0)" }
                        .joined(separator: "\n")
                    
                    Text(starterText)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
                
                Divider()
                
                NavigationLink {
                    AskQuestionView(topic: metadata.id, metadata: metadata)
                } label: {
                    Label("Ask a question with AI", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding()
        }
        .navigationTitle(metadata.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
