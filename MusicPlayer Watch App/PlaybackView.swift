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
let sp = window_height - 0.88 * window_width
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
    
    @State private var appearSelf = 3
    
    @ObservedObject var appearTimer = AppearTimer()
    @ObservedObject var trackInfo : TrackInfo = TrackInfo()
    @State var showAlert : Bool = false
    @State var pin : Bool = false
    
    func appear() -> Bool {
        return self.pin || self.appearTimer.appear
    }
    
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
                        }
                        else {
                            Image(uiImage: trackInfo.art!).resizable().scaledToFill()
                        }
                    }.frame(width : window_width, height: window_height * 0.8)
                        .background(appear() ? Color.gray : Color.clear)
                        .opacity(appear() ? 0.35 : 1)
                        .blur(radius: appear() ? 3 : 0)
                        
                    if appear() {
                        VStack {
                            HStack {
                                Button {
                                    self.showAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(.trailing, 0.07*window_width)
                                        .frame(width:window_width/4.8 + 0.07*window_width, height: window_width/4.8)
                                }.buttonStyle(.plain)
                                    .alert("Sure to delete \(trackInfo.s)", isPresented: self.$showAlert) {
                                        
                                        Button("Confirm") {
                                            //self.showAlert = false
                                            parent?.player.pause()

                                            do {
                                                let tri_m = trackInfo.m
                                                var tri_f : String? = nil
                                                parent?.music.music.removeAll(where: { t in
                                                    if(t.m == tri_m) {
                                                        if let tm = tri_m {
                                                            parent?.player.remove(tm)
                                                            tri_f = t.filename
                                                        }
                                                        return true
                                                    }
                                                    return false
                                                })
                                                if let tri_f = tri_f, tri_f.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                                                    try FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Documents/" + tri_f
                                                    )
                                                }
                                            } catch {}
                                            parent?.player.play()
                                            self.appearTimer.appear()
                                        }
                                        Button("Cancel") {
                                            //self.showAlert = false
                                            self.appearTimer.appear()
                                        }
                                        
                                    }
                                Button {
                                    self.appearTimer.appear()
                                } label: {
                                    Image(systemName: "star")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(.trailing, 0.07*window_width)
                                        .frame(width:window_width/4.8 + 0.07*window_width, height: window_width/4.8)
                                }.buttonStyle(.plain)
                                Button {
                                    self.pin.toggle()
                                    self.appearTimer.appear()
                                } label: {
                                    Image(systemName: self.pin ? "pin.fill" : "pin")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width:window_width/4.8, height: window_width/4.8)
                                }.buttonStyle(.plain)
                                    
                            }.frame(height: window_width * 0.3)
                                .frame(height: window_width * 0.3)
                                .padding(.top, window_width*0.03)
                                .padding(.bottom, window_width*0.02)
                            HStack {
                                Button {
                                    let curr = parent!.player.currentItem
                                    
                                    curr!.seek(to: .zero)
                                    parent!.player.play()
                                    appearTimer.appear()
                                } label : {
                                    Image(systemName: "chevron.backward")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: window_width/7, height: window_height/7)
                                }
                                    .frame(width: window_width/4, height: window_height/4)
                                    .buttonStyle(.plain)
                                    .padding(.leading, window_width * 0.03)
                                Button {
                                    if ( parent!.player.timeControlStatus == .playing ) {
                                        parent!.player.pause()
                                    } else {
                                        parent!.player.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
                                        parent!.play()
                                        appearTimer.appear()
                                    }
                                } label: {
                                    (
                                        self.parent!.player.timeControlStatus == .playing ?
                                        Image(systemName: "stop") :
                                            Image(systemName: "play")
                                    )
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: window_width/5.5)
                                }
                                    .padding(.leading, window_width * 0.01)
                                    .frame(width: window_width/2.5)
                                    .buttonStyle(.plain)
                                
                                Button {
                                    let curr = parent!.player.currentItem
                                    parent!.player.advanceToNextItem()
                                    curr!.seek(to: .zero)
                                    parent!.player.play()
                                    appearTimer.appear()
                                } label : {
                                    Image(systemName: "chevron.forward")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: window_width/7, height: window_height/7)
                                }.frame(width: window_width/4, height: window_height/4)
                                 .buttonStyle(.plain)
                            }.padding(.trailing, window_width*0.05)
                                .frame(height: window_width * 0.3)
                            ProgressView(value: self.parent!.player.currentTime().seconds, total: self.parent!.player.currentItem?.duration.seconds ?? 0)
                                .progressViewStyle(.linear)
                                .scaleEffect(x: 1, y: 0.4, anchor: .center)
                                .padding(.top, window_width * 0.08)
                                .padding(.bottom, window_width*0.1)
                                .frame(width: window_width * 0.92)
                            
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
                .transition(.opacity.animation(.easeInOut))
       }
   }
    
    init() { }
    init(parent:ContentView, music: TrackInfo? = nil) {
        if music != nil && music!.art != nil {
            self.parent = parent
        }
    }
    
    mutating func update (music: TrackInfo) {
        self.trackInfo.from(other: music)
        self.title = music.s
    }
}

struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackView()
    }
}
