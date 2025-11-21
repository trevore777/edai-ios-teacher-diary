//
//  AboutView.swift
//  FaithBuilderApp
//
//  Created by Trevor Elliott on 20/11/2025.
//


import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // App Title
                Text("FaithBuilder Bible Study App")
                    .font(.largeTitle.bold())
                
                Divider()
                
                // COPYRIGHT
                Group {
                    Text("Copyright")
                        .font(.headline)
                    Text("© 2025 Trevor David Elliott. All rights reserved.")
                }
                
                Divider()
                
                // ACKNOWLEDGEMENTS
                Group {
                    Text("Acknowledgements")
                        .font(.headline)
                    
                    Text("""
This app includes spiritually relevant questions contributed by **Tully Hastie**, specifically crafted to support students who are genuinely seeking to grow in their faith, understand Scripture more clearly, and walk closer with Jesus Christ.

Their contributions have helped shape the clarity, tone, and student-friendly spiritual focus of this learning tool.
""")
                        .font(.body)
                }
                
                Divider()
                
                // STUDY MATERIAL SOURCE
                Group {
                    Text("Study Framework")
                        .font(.headline)
                    
                    Text("""
This app uses the *Search for Truth* Bible study course as a reference framework for spiritual themes, doctrinal clarity, and structured discipleship-based learning.

All Bible Scriptures displayed in-app are from the **King James Version (KJV)** (public domain).
""")
                }
                
                Divider()
                
                // APP PURPOSE
                Text("Purpose of This App")
                    .font(.headline)
                
                Text("""
FaithBuilder was created to equip Christian school students with a safe, respectful, Scripture-focused environment where they can explore questions about:
- Prayer
- Hearing God
- Repentance
- Spiritual identity
- Following Jesus
- Spiritual growth
- Sharing the Gospel
- Biblical wisdom
- Overcoming temptation
- Unity in the Body of Christ
""")
                
                Text("""
This tool is intentionally designed for Christian education contexts and is not a substitute for pastoral counselling, chaplain support, or personal discipleship.
""")
                .font(.caption)
                .foregroundColor(.secondary)
                
                Divider()
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("About & Credits")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
