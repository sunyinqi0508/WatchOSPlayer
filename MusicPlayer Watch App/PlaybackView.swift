//
//  PlaybackView.swift
//  MusicPlayer Watch App
//
//  Created by BillSun on 3/18/23.
//

import SwiftUI
import UIKit



struct PlaybackView: View {
    
    var placeholder: Image? = nil
    var music : IDStr? = nil
    var parent : ContentView? = nil
    //@ObservedObject var timeout = Timeout(timeout: 5)
    var title = ""
    @State var playing = true
    @State private var appearSelf = true
    
    var body: some View {
        if parent != nil {
            GeometryReader { geo in
                ZStack {
                    if(placeholder == nil) {
                        Image(systemName: "square")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(.black)
                    }
                    else {
                        placeholder!.resizable().scaledToFill()
                    }
                    if (appearSelf)
                    {
                       NavigationView{
                            VStack{
                                HStack{
                                    Button {
                                        if ( parent!.player!.timeControlStatus == .playing ) {
                                            parent!.player!.pause()
                                            self.playing = false
                                        } else {
                                            parent!.player!.play()
                                            self.playing = true
                                        }
                                    } label: {
                                        (
                                            self.playing ?
                                            Image(systemName: "stop") :
                                                Image(systemName: "play")
                                        )
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geo.size.width/5.5)
                                    }.background(Color(red: 0,green: 0,blue: 0,opacity: 0.2))
                                        .frame(width: geo.size.width/2.5)
                                        .cornerRadius(90, antialiased: true)
                                        .foregroundColor(.white)
                                        .opacity(1)
                                        .buttonStyle(.plain)
                                    Button {
                                        let curr = parent!.player!.currentItem
                                        parent!.player!.advanceToNextItem()
                                        curr!.seek(to: .zero)
                                        parent!.player!.play()
                                        self.playing = true
                                    } label : {
                                        Image(systemName: "chevron.forward")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: geo.size.width/7, height: geo.size.height/7)
                                    }.background(Color.clear)
                                        .clipShape(Circle())
                                        .foregroundColor(.white)
                                        .frame(width: geo.size.width/4, height: geo.size.height/4)
                                        .padding(0)
                                        .opacity(1)
                                        .buttonStyle(.plain)
                                }
                            }.onAppear(){
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                                    appearSelf = false
                                })
                            }.navigationTitle("\(self.title)")
                       }.opacity(0.65).navigationBarBackButtonHidden(false)
                    }
                }.onTapGesture {
                    appearSelf = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                        appearSelf = false
                    })
                }
            }
       }
   }
    
    init() { }
    init(parent:ContentView, music: IDStr? = nil) {
        if music != nil && music!.art != nil {
            self.placeholder = music!.art!
            self.music = music
            self.parent = parent
            self.playing = parent.player!.timeControlStatus == .playing
        }
    }
    
    mutating func update (music: IDStr) {
        self.placeholder = music.art
        self.music = music
        self.title = music.s
        self.playing = self.parent!.player!.timeControlStatus == .playing
    }
}

struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackView()
    }
}
