//
//  SongStore+Create.swift
//  songcaptureV2
//
//  Created by Trevor Elliott on 4/11/2025.
//


import Foundation

extension SongStore {
    /// Create a new song with just lyrics (no audio) and add to library
    func createSongFromLyrics(title: String, lyrics: String) {
        var s = Song(title: title)
        s.lyrics = lyrics
        s.chordEvents = []
        songs.insert(s, at: 0)
        save()
    }
}
