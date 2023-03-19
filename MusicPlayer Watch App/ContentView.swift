//
//  ContentView.swift
//  MusicPlayer Watch App
//
//  Created by BillSun on 3/18/23.
//

import SwiftUI
import Network
import AVFoundation
import UIKit

class IDStr : Identifiable {
    var s : String = ""
    var art : Image?
    var m : AVPlayerItem?
    init () {self.m = nil}
    init (str : String, music : AVPlayerItem) {
        self.s = str
        self.m = music
    }
}

class ListViewModel: ObservableObject {

    @Published var music = Array<IDStr>()
    
    func addItem(i : String, m : AVPlayerItem) {
        music.append(IDStr(str: i, music: m))
   }
    func addItem(str : IDStr) {
        music.append(str)
   }
}

class PlaybackViewProxy {
    var pbv : PlaybackView
    init(v : PlaybackView) {
        self.pbv = v
    }
}

struct ContentView: View {
    @ObservedObject var music = ListViewModel()
    @State var pushState = false
    @State var geo :CGSize = .zero
    @State var _curr_sel_music : IDStr = IDStr()
    let pbv : PlaybackViewProxy
    var body: some View {
        GeometryReader { geometry in
            NavigationView(){
                List() {
                    ForEach(music.music) { m in
                        VStack(){
                            Button(m.s, action: {
                                let idx = music.music.firstIndex { s in
                                    s.s == m.s
                                }
                                if (idx != nil) {
                                    if (idx != 0) {
                                        music.music = Array(music.music[idx! ... (music.music.endIndex - 1)] + music.music[0...idx! - 1])
                                        self.player?.removeAllItems()
                                        for i in music.music {
                                            i.m!.seek(to: .zero)
                                            player?.insert(i.m!, after: nil)
                                        }
                                    }
                                    else {
                                        m.m!.seek(to: .zero)
                                    }
                                }
                                self._curr_sel_music = m
                                self.pbv.pbv.update(music: _curr_sel_music)
                                pushState = true
                            }).ignoresSafeArea(.all).cornerRadius(.zero).padding(.zero).frame(maxHeight: CGFloat(50)).foregroundColor(.white)
                            
                            NavigationLink(destination: self.pbv.pbv, isActive: $pushState) {
                                EmptyView()
                            }
                        }
                    }
                    Label("\(music.music.count) Files.    ", systemImage: "heart.fill").background(.clear).labelStyle(.titleAndIcon).frame(width: geometry.size.width, alignment: .center)
                }
            }.onAppear {
                geo = geometry.size
                self.pbv.pbv.parent = self
            }
        }
        }
     
    var player : AVQueuePlayer? = nil
    
    init() {
        self.pbv = PlaybackViewProxy(v: PlaybackView())
        let base = "https://billsun.dev/webdav/music-test"
        let url = URL(string: base)
        let request: URLRequest = URLRequest(url: url!)
        let session = URLSession(configuration: .default)
        let dir = NSHomeDirectory()
        
        session.dataTask(with: request, completionHandler:
        { (data, response, error) -> Void in
            if (error != nil) { return }
            let reply = String(data: data!, encoding: String.Encoding.utf8)!
            
            do {
                let pattern  = try Regex(#".*(<a\s+href=\"(.*.(m4a|mp3|wav))\">)"#)
                let matched =  reply.matches(of: pattern)
                
                var s = Set<String>()
                for match in matched {
                    s.insert(String(match.output[2].substring!))
                }
                for _file in s {
                    var file = _file
                    if _file.count > 68 {
                        file = _file.removingPercentEncoding ?? _file
                        if file.count > 36 {
                            file = String(file.prefix(31) + file.suffix(5))
                        }
                    }
                    let filepath = dir + "/Documents/" + file
                    var download = true
                    let check_file =  { fpath -> Void in
                        if(FileManager.default.fileExists(atPath: fpath)) {
                            let sz = try! FileManager.default.attributesOfItem(atPath: fpath)[FileAttributeKey.size] as! UInt64
                            download = sz < 40960 // (ignore files <40k)
                        }
                    }
                    
                    check_file(filepath)
                    check_file("\(dir)/Documents/\(_file)")
                    if (download) {
                        session.dataTask(with: URLRequest(url: URL(string: base + "/" +  _file)!)) {
                            (data, response, error) -> Void in
                            if (error == nil) {
                                let fp = fopen(filepath, "wb")
                                data!.withUnsafeBytes({ ptr in
                                    fwrite(ptr, 1, data!.count, fp)
                                })
                                fclose(fp)
                            }
                        }.resume()
                    }
                }
            }catch{}
        }
        ).resume()
        let enumerator = FileManager.default.enumerator(atPath: dir + "/Documents/")
        enumerator!.forEach({ e in
            if (self.player == nil) {
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(AVAudioSession.Category.playback)
                } catch {
                    print(error)
                }
                self.player = AVQueuePlayer()
            }
            let filename = (e as! String)
            let file_url = URL(filePath: dir + "/Documents/" + filename)
            let asset = AVAsset(url: file_url)
            let idstr = IDStr()
            let geo = self.geo
            asset.loadMetadata(for: .iTunesMetadata) {
                items, b in
                if (items == nil) { return }
                for i in items! {
                    if(i.identifier == .iTunesMetadataCoverArt) {
                        Task{
                            let imageData = try await i.load(.dataValue)
                            idstr.art = Image(uiImage: UIImage(data: imageData!)!)
                            /*if (idstr.art != nil) {
                                idstr.art!.resizable().scaledToFill().frame(width: geo.width, height: geo.height)
                            }*/
                        }
                    }
                }
            }
            let item = AVPlayerItem(url: file_url)
            idstr.s = filename.prefix(filename.count - 4).removingPercentEncoding!
            idstr.m = item
            self.music.addItem(str: idstr)
            //item.addObserver(self, forKeyPath: "status", context: nil)
            self.player?.insert(item, after: nil)
            
            if (self.player?.status == .failed) {
                print(self.player!.error!)
            }
            else {
                self.player?.play()
            }
        })
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().ignoresSafeArea(.all).cornerRadius(.zero).padding(.zero)
    }
    
}
