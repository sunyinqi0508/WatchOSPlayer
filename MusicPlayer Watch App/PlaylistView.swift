//
//  PlaylistView.swift
//  MusicPlayer Watch App
//
//  Created by BillSun on 4/11/23.
//

import SwiftUI

class PlaylistItem : Identifiable {
    static func == (lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
        return lhs.s == rhs.s
    }
    
    var s : String = ""
    init(s: String) {
        self.s = s
    }
}

struct PlaylistView: View {
    @State var playlist : Array<PlaylistItem> = []
    var body: some View {
        NavigationView {
            ForEach(playlist) { p in
                //NavigationLink(p.s, value: p)
            }
            TextFieldLink("Add Playlist") { s in
                playlist.append(PlaylistItem(s: s))
            }
        }
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
    }
}
