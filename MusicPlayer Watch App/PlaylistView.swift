//
//  PlaylistView.swift
//  MusicPlayer Watch App
//
//  Created by BillSun on 4/11/23.
//

import SwiftUI

class IDStr : Identifiable {
    var s : String = ""
}

struct PlaylistView: View {
    var playlist : Array<IDStr> = []
    var body: some View {
        List {
            ForEach(playlist) { p in 
                    
            }
        }
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
    }
}
