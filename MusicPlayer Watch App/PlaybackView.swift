//
//  PlaybackView.swift
//  MusicPlayer Watch App
//
//  Created by BillSun on 3/18/23.
//

import SwiftUI

struct PlaybackView: View {
    
    var placeholder: Image? = nil

   var body: some View {
           placeholder == nil ?
               nil : placeholder!.resizable().scaledToFill()
       
   }
    
    init() {}
    init(parent:ContentView, music: IDStr) {
        if music.art != nil {
            self.placeholder = music.art!
        }
    }
}

struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackView()
    }
}
