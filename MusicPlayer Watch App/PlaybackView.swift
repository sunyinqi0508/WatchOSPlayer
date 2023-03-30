//
//  PlaybackView.swift
//  MusicPlayer Watch App
//
//  Created by BillSun on 3/18/23.
//

import SwiftUI
import UIKit
import WatchKit

let window_width = WKInterfaceDevice.current().screenBounds.width
let window_height = WKInterfaceDevice.current().screenBounds.height

class AppearTimer : ObservableObject {
    @Published var appear = false
    var timeout = 0
    let lock : NSLock = NSLock()
    
    func appear(time: Int = 5, _appear: Bool = false) {
        self.lock.lock()
        self.timeout = self.timeout + time
        self.appear = timeout > 0
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(time)),
            execute: {
                self.lock.lock()
                self.timeout -= time
                self.appear = self.timeout > 0
                self.lock.unlock()
            }
        )
        self.lock.unlock()
    }
}


struct PlaybackView: View {
    //var music : TrackInfo? = nil
    var parent : ContentView? = nil
    //@ObservedObject var timeout = Timeout(timeout: 5)
    var title = ""
    
    @State var playing = true
    @State private var appearSelf = 3
    
    @ObservedObject var appearTimer = AppearTimer()
    @ObservedObject var trackInfo : TrackInfo = TrackInfo()
    

    var body: some View {
        if trackInfo.m != nil {
            GeometryReader { geo in
                ZStack {
                    ZStack{
                        if(trackInfo.art == nil) {
                            
                            Image(systemName: "music.note")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(width: window_width*0.7, height: window_height*0.7)
                            //.padding(.leading, window_width*0.05)
                            //.padding(.bottom, window_height * 0.15)
                            
                            //.padding(.top, window_height*0.08)
                        }
                        else {
                            Image(uiImage: trackInfo.art!).resizable().scaledToFill()
                        }
                    }.frame(width : window_width, height: window_height * 0.8)
                        .background(appearTimer.appear ? Color.gray : Color.clear).opacity(appearTimer.appear ? 0.3 : 1).blur(radius: appearTimer.appear ? 5 : 0)
                    if (appearTimer.appear)
                    {
                        VStack {
                            HStack {
                                Button {
                                    if ( parent!.player.timeControlStatus == .playing ) {
                                        parent!.player.pause()
                                        self.playing = false
                                    } else {
                                        parent!.player.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
                                        parent!.play()
                                        self.playing = true
                                        appearTimer.appear()
                                    }
                                } label: {
                                    (
                                        self.playing ?
                                        Image(systemName: "stop") :
                                            Image(systemName: "play")
                                    )
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: window_width/5.5)
                                }.background(Color(red: 0,green: 0,blue: 0,opacity: 0.2))
                                    .frame(width: window_width/2.5)
                                    .cornerRadius(90, antialiased: true)
                                    .foregroundColor(.white)
                                    .opacity(1)
                                    .buttonStyle(.plain)
                                Button {
                                    let curr = parent!.player.currentItem
                                    parent!.player.advanceToNextItem()
                                    curr!.seek(to: .zero)
                                    parent!.player.play()
                                    self.playing = true
                                    appearTimer.appear()
                                } label : {
                                    Image(systemName: "chevron.forward")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: window_width/7, height: window_height/7)
                                }.background(Color.clear)
                                    .clipShape(Circle())
                                    .foregroundColor(.white)
                                    .frame(width: window_width/4, height: window_height/4)
                                    .padding(0)
                                    .opacity(1)
                                    .buttonStyle(.plain)
                            }
                        }.zIndex(5)
                    }
                }.onTapGesture {
                    appearTimer.appear()
                }
            }.navigationBarBackButtonHidden(false)
                .navigationTitle(trackInfo.s)
                .toolbar(.visible, for: .navigationBar)
                .onAppear() {
                    appearTimer.appear(time: 3, _appear: true)
                }
       }
   }
    
    init() { }
    init(parent:ContentView, music: TrackInfo? = nil) {
        if music != nil && music!.art != nil {
            self.parent = parent
            self.playing = parent.player.timeControlStatus == .playing
        }
    }
    
    mutating func update (music: TrackInfo) {
        self.trackInfo.from(other: music)
        self.title = music.s
        self.playing = self.parent!.player.timeControlStatus == .playing
    }
}

struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackView()
    }
}
