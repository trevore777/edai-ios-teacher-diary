//
//  StudyTopic.swift
//  FaithBuilderApp
//
//  Created by Trevor Elliott on 20/11/2025.
//

import Foundation

// MARK: - StudyTopic

enum StudyTopic: String, CaseIterable, Identifiable, Codable {
    case authorityOfTheBlood
    case growPrayerLife
    case callingAndFollowingGod
    case repentance
    case hearingGod
    case growingCloserToGod
    case temptationAndEnemy
    case unityNotDivision
    case powerOfTheTongue
    case spreadingTheGospel
    case prayingForPeople
    case healingPeople
    case writingASermon
    case sharingTestimony
    case identityInChrist
    case obedienceToGod
    case servingOthers
    case creationVsEvolution   // 👈 NEW TOPIC
    
    var id: String { rawValue }
}

// MARK: - TopicMetadata

struct TopicMetadata: Identifiable, Codable {
    let id: StudyTopic
    let title: String
    let subtitle: String
    let description: String
    let keyVerseRefs: [String]
    let starterQuestions: [String]
}

extension TopicMetadata {
    
    // All predefined topics
    static let all: [TopicMetadata] = [
        .init(
            id: .authorityOfTheBlood,
            title: "Authority & Power in the Blood of Christ",
            subtitle: "Walking in the victory Jesus purchased",
            description: """
This topic focuses on the true authority and power we have through the blood of Jesus and the anointing of the Holy Ghost. It connects strongly with the New Covenant and the work of Christ as shown in the Search for Truth study.
""",
            keyVerseRefs: [
                "Hebrews 9:14",
                "Revelation 12:11",
                "Acts 1:8"
            ],
            starterQuestions: [
                "What does the Bible say about the power of the blood of Jesus?",
                "How does the blood of Christ give us victory over sin and the enemy?",
                "What does it mean to be anointed by God in everyday life?"
            ]
        ),
        
        .init(
            id: .growPrayerLife,
            title: "Growing Your Prayer Life",
            subtitle: "Learning to talk with God daily",
            description: """
This topic helps students see prayer as a living relationship with God, not just a duty. It ties into the Search for Truth emphasis on walking with God, obedience, and daily fellowship.
""",
            keyVerseRefs: [
                "Luke 11:1–4",
                "1 Thessalonians 5:17",
                "Philippians 4:6–7"
            ],
            starterQuestions: [
                "How can I grow a stronger daily prayer life?",
                "What should I pray about when I don't know what to say?",
                "How can I stay focused when I'm praying?"
            ]
        ),
        
        .init(
            id: .callingAndFollowingGod,
            title: "Our Calling & Fully Following God",
            subtitle: "Surrendering to God's will",
            description: """
This topic explores what it means to be called by God and to fully follow Him, using examples like Abraham, Moses, the disciples, and the church from the Search for Truth lessons.
""",
            keyVerseRefs: [
                "Romans 12:1–2",
                "Matthew 16:24",
                "Ephesians 4:1"
            ],
            starterQuestions: [
                "How do I know what God is calling me to do?",
                "What does it mean to fully follow Jesus, not just partly?",
                "How do I surrender my plans to God's will?"
            ]
        ),
        
        .init(
            id: .repentance,
            title: "Repentance",
            subtitle: "Turning from sin to God",
            description: """
This topic explains repentance as a heartfelt turning from sin and turning toward God. It draws from the Search for Truth teaching on salvation, the New Covenant, and the life of the believer.
""",
            keyVerseRefs: [
                "Acts 2:38",
                "2 Corinthians 7:10",
                "1 John 1:9"
            ],
            starterQuestions: [
                "What is real repentance according to the Bible?",
                "How do I know if I have truly repented?",
                "Why is repentance the first step in salvation?"
            ]
        ),
        
        .init(
            id: .hearingGod,
            title: "Hearing God More",
            subtitle: "Recognising the Lord's voice",
            description: """
This topic focuses on how God speaks through His Word, His Spirit, and godly leadership, and how we can grow in discernment and obedience.
""",
            keyVerseRefs: [
                "John 10:27",
                "Hebrews 1:1–2",
                "James 1:22"
            ],
            starterQuestions: [
                "How can I tell if it's God speaking or just my own thoughts?",
                "What are safe ways to grow in hearing God?",
                "How does the Bible help me learn God's voice?"
            ]
        ),
        
        .init(
            id: .growingCloserToGod,
            title: "Growing Closer to God",
            subtitle: "Abiding in Christ",
            description: """
This topic helps students understand spiritual growth through prayer, the Word, obedience, and fellowship, consistent with Search for Truth's focus on living in the kingdom.
""",
            keyVerseRefs: [
                "John 15:4–5",
                "James 4:8",
                "Colossians 2:6–7"
            ],
            starterQuestions: [
                "What are practical ways I can grow closer to God every week?",
                "How does obedience help me grow in my relationship with God?",
                "What should I do when I feel spiritually dry or distant?"
            ]
        ),
        
        .init(
            id: .temptationAndEnemy,
            title: "Temptation & the Enemy",
            subtitle: "Recognising the enemy's strategies",
            description: """
This topic covers the ways the enemy tries to open us to temptation and draw us away from God, starting with the Fall in Genesis and moving through spiritual warfare teaching.
""",
            keyVerseRefs: [
                "Genesis 3:1–6",
                "Ephesians 6:10–12",
                "1 Corinthians 10:13"
            ],
            starterQuestions: [
                "How does the enemy usually tempt Christians today?",
                "What doors should I be careful not to open to temptation?",
                "What does the Bible say about resisting the devil?"
            ]
        ),
        
        .init(
            id: .unityNotDivision,
            title: "Unity, Not Division",
            subtitle: "One body in Christ",
            description: """
This topic explores God's heart for unity among believers, drawing from Israel's division and restoration and the New Testament church.
""",
            keyVerseRefs: [
                "Psalm 133:1",
                "John 17:20–23",
                "Ephesians 4:3"
            ],
            starterQuestions: [
                "Why is unity so important to God?",
                "How should I respond when I see division or gossip?",
                "What can I do personally to bring unity to my youth group or school?"
            ]
        ),
        
        .init(
            id: .powerOfTheTongue,
            title: "The Power of Life and Death in Our Tongues",
            subtitle: "Speaking blessing, not destruction",
            description: """
This topic highlights how our words carry spiritual weight. It draws on Proverbs and New Testament teaching about the tongue, encouragement, and holiness.
""",
            keyVerseRefs: [
                "Proverbs 18:21",
                "James 3:8–10",
                "Ephesians 4:29"
            ],
            starterQuestions: [
                "What does the Bible mean by 'life and death are in the power of the tongue'?",
                "How can I change my speech to honour God?",
                "Why are gossip and complaining so dangerous spiritually?"
            ]
        ),
        
        .init(
            id: .spreadingTheGospel,
            title: "Spreading the Gospel",
            subtitle: "Sharing the good news with the world",
            description: """
This topic builds on Search for Truth's focus on the Great Commission and the spread of the gospel in the Book of Acts.
""",
            keyVerseRefs: [
                "Matthew 28:19–20",
                "Mark 16:15",
                "Acts 1:8"
            ],
            starterQuestions: [
                "How can I effectively share the gospel with my friends?",
                "What is the core message of the gospel?",
                "What if I feel nervous or afraid to talk about Jesus?"
            ]
        ),
        
        .init(
            id: .prayingForPeople,
            title: "Praying for People",
            subtitle: "Standing in the gap",
            description: """
This topic teaches intercession and praying for others in a way that honours God, respects people, and fits a school context.
""",
            keyVerseRefs: [
                "1 Timothy 2:1–2",
                "James 5:16",
                "Ephesians 6:18"
            ],
            starterQuestions: [
                "How should I pray for someone who is struggling?",
                "What is intercession and how do I do it?",
                "How can I pray for my school, teachers, and leaders?"
            ]
        ),
        
        .init(
            id: .healingPeople,
            title: "Healing & Praying for the Sick",
            subtitle: "Trusting God while acting wisely",
            description: """
This topic looks at how believers can pray for the sick, trusting God's power, while also respecting medical care and school guidelines.
""",
            keyVerseRefs: [
                "James 5:14–15",
                "Mark 16:17–18",
                "Psalm 103:2–3"
            ],
            starterQuestions: [
                "How should I pray for someone who is sick?",
                "What does the Bible say about healing and God's will?",
                "How do I balance praying for healing with using doctors and medicine?"
            ]
        ),
        
        .init(
            id: .writingASermon,
            title: "How to Write a Sermon",
            subtitle: "Preparing a Bible-based message",
            description: """
This topic introduces basic steps for building a Bible-centred sermon or devotion, rooted in Scripture and the themes taught in Search for Truth.
""",
            keyVerseRefs: [
                "2 Timothy 2:15",
                "2 Timothy 4:2",
                "Nehemiah 8:8"
            ],
            starterQuestions: [
                "How do I choose a Bible passage for a sermon?",
                "What are the main parts of a simple sermon or devotion?",
                "How can I make sure what I preach stays faithful to the Bible?"
            ]
        ),
        
        .init(
            id: .sharingTestimony,
            title: "Sharing Your Testimony",
            subtitle: "Telling what Jesus has done in you",
            description: """
This topic helps students shape and share their testimony in a clear, God-honouring, and safe way.
""",
            keyVerseRefs: [
                "Revelation 12:11",
                "Mark 5:19",
                "1 Peter 3:15"
            ],
            starterQuestions: [
                "How can I share my testimony in a simple way?",
                "What parts of my story are helpful to share, and what should I keep private?",
                "How can my testimony point people to Jesus, not just to me?"
            ]
        ),
        
        .init(
            id: .identityInChrist,
            title: "Identity in Christ",
            subtitle: "Who we are in Him",
            description: """
This topic explores what it means to be a new creation in Christ, part of God's family, and secure in His love.
""",
            keyVerseRefs: [
                "2 Corinthians 5:17",
                "Galatians 2:20",
                "1 Peter 2:9"
            ],
            starterQuestions: [
                "What does the Bible say about who I am in Christ?",
                "How can I let God's Word shape my identity instead of social media?",
                "What changes when I really believe I am a new creation?"
            ]
        ),
        
        .init(
            id: .obedienceToGod,
            title: "Obedience to God",
            subtitle: "Loving Him by doing what He says",
            description: """
This topic connects obedience with love and faith. It echoes Search for Truth's emphasis on covenant, commandments, and living for God's kingdom.
""",
            keyVerseRefs: [
                "John 14:15",
                "Deuteronomy 6:4–5",
                "James 1:22"
            ],
            starterQuestions: [
                "Why is obedience to God so important?",
                "How do I obey when God's way is hard or unpopular?",
                "What helps me obey God consistently, not just at camp or youth nights?"
            ]
        ),
        
        .init(
            id: .servingOthers,
            title: "Serving Others",
            subtitle: "Living out the love of Christ",
            description: """
This topic explores how following Jesus leads us to serve others with humility, love, and practical action. It connects serving to Jesus’ example, the call to love our neighbour, and using our gifts to build up the Body of Christ and bless people around us.
""",
            keyVerseRefs: [
                "Mark 10:45",
                "John 13:14–15",
                "Galatians 5:13",
                "Matthew 25:35–40"
            ],
            starterQuestions: [
                "What does Jesus teach us about serving others?",
                "Why is serving others such an important part of following Jesus?",
                "What are some practical ways you could serve others at school this week?",
                "How does serving others change your heart and draw you closer to God?",
                "What gets in the way of serving others, and how can God help you overcome that?"
            ]
        ),
        
        .init(
            id: .creationVsEvolution,
            title: "Creation vs Evolution",
            subtitle: "Trusting God’s Word about our origins",
            description: """
This topic helps students compare the Bible’s account of creation with evolutionary ideas. It teaches that Genesis is real history, that God created everything good in six days, and that Adam and Eve were real people whose sin brought death into the world (Romans 5:12). It also shows how a global Flood in Noah’s day can explain much of the fossil record and rock layers.

The focus is to build confidence in the authority of Scripture, encourage respectful discussion, and show that the gospel depends on real sin, a real Fall, and a real Saviour.
""",
            keyVerseRefs: [
                "Genesis 1:1",
                "Genesis 1:26–27",
                "Genesis 7:19–20",
                "Romans 5:12",
                "Hebrews 11:3"
            ],
            starterQuestions: [
                "What does Genesis 1–3 teach about how God created the world and human beings?",
                "Why does it matter whether Adam and Eve were real historical people?",
                "How does a global Flood in Noah’s day help explain fossils and rock layers?",
                "How is evolution a different worldview from the Bible’s account of creation and the Fall?",
                "How does what we believe about creation affect how we understand sin, the cross, and the gospel?"
            ]
        )
    ]
    
    // MARK: - Lookup
    
    static func metadata(for topic: StudyTopic) -> TopicMetadata {
        if let found = all.first(where: { $0.id == topic }) {
            return found
        }
        
        // Fallback for topics not configured yet
        return TopicMetadata(
            id: topic,
            title: prettyTitle(for: topic),
            subtitle: "Custom topic",
            description: "This is a custom topic that has not been fully configured in TopicMetadata yet.",
            keyVerseRefs: [],
            starterQuestions: []
        )
    }
    
    /// Turn `servingOthers` into "Serving Others", `creationVsEvolution` into "Creation Vs Evolution", etc.
    private static func prettyTitle(for topic: StudyTopic) -> String {
        let raw = topic.rawValue
        let withSpaces = raw.replacingOccurrences(
            of: #"([a-z])([A-Z])"#,
            with: "$1 $2",
            options: .regularExpression
        )
        return withSpaces.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
