//
//  TopicListView.swift
//  FaithBuilderApp
//
//  Created by Trevor Elliott on 20/11/2025.
//


import SwiftUI

struct TopicListView: View {
    private let topics = TopicMetadata.all
    
    var body: some View {
        NavigationStack {
            List(topics) { meta in
                NavigationLink {
                    TopicDetailView(metadata: meta)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meta.title)
                            .font(.headline)
                        Text(meta.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("QuickView Study")
        }
    }
}
