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

class TrackInfo : NSObject, Identifiable, ObservableObject {
    @Published var s : String = ""
    @Published var art : Image? = nil
    @Published var m : AVPlayerItem? = nil
    @Published var changed = false
    var cv : ContentView? = nil
    override init() {
        super.init()
    }
    init (str : String, music : AVPlayerItem) {
        self.s = str
        self.m = music
    }
    func equals_to (other: TrackInfo) -> Bool {
        return self.m == other.m
    }
    func from(other : TrackInfo) {
        self.s = other.s
        self.art = other.art
        self.m = other.m
        self.changed = !self.changed
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (change![.newKey] is NSNull) {
            self.changed = !self.changed
            return
        }
        if let cv = self.cv {
            if let idx = cv.music.music.firstIndex(where: { s in
                change![.newKey] as? AVPlayerItem == s.m
            }){
                self.from(other: cv.music.music[idx])
                cv.update_pbv(idx: idx)
            }
        }
    }
}

class ListViewModel: ObservableObject {

    @Published var music = Array<TrackInfo>()

    func addItem(i : String, m : AVPlayerItem) {
        music.append(TrackInfo(str: i, music: m))
   }
    func addItem(str : TrackInfo) {
        music.append(str)
   }
}

class PlaybackViewProxy {
    var pbv : PlaybackView
    var tabpbv : PlaybackView
    init() {
        pbv = PlaybackView()
        tabpbv = PlaybackView()
    }
    init(v : PlaybackView, tabpbv: PlaybackView) {
        self.pbv = v
        self.tabpbv = tabpbv
    }
}

struct ContentView: View {
    @ObservedObject var music = ListViewModel()
    @ObservedObject var nowplaying : TrackInfo
    @State var pushState = false
    @State var geo:CGSize = .zero
    @State var active = false
    //@State var _curr_sel_music : TrackInfo = TrackInfo()
    var pbv : PlaybackViewProxy
    var dir: String
    
    func update_pbv(idx: Int) {
        let m = music.music[idx]
        if (idx != 0) {
            music.music = Array(music.music[idx ... (music.music.endIndex - 1)] + music.music[0...idx - 1])
            self.player.removeAllItems()
            for i in music.music {
                i.m!.seek(to: .zero)
                player.insert(i.m!, after: nil)
            }
        }
        else {
            m.m!.seek(to: CMTime(value: 1, timescale: 10000))
        }
        
        //if !m.equals_to(other: self.nowplaying) {
        if (self.active) {
            self.pbv.tabpbv.update(music: m)
        }
        else {
            self.pbv.pbv.update(music: m)
        }
        
    }
    
    func update_pbv(m: TrackInfo) {
        if let idx = music.music.firstIndex(where: { s in s.s == m.s }){
            self.update_pbv(idx: idx)
        }
    }
    var body: some View {
        NavigationStack {
            TabView {
                GeometryReader { geometry in
                    List() {
                        ForEach(music.music) { m in
                            VStack(){
                                NavigationLink(m.s, value: m)
                                    .ignoresSafeArea(.all)
                                    .cornerRadius(.zero)
                                    .padding(.zero)
                                    .frame(maxHeight: CGFloat(50))
                                    .foregroundColor(.white)
                            }
                        }
                        Label("\(music.music.count) Files.    ", systemImage: "heart.fill").background(.clear).labelStyle(.titleAndIcon).frame(width: geometry.size.width, alignment: .center)
                    }
                    .navigationTitle("Songs")
                    .navigationBarBackButtonHidden(false)
                    .onAppear {
                        self.active = true
                        geo = geometry.size
                        self.pbv.tabpbv.update(music: self.nowplaying)
                    }
                }.navigationDestination(for: TrackInfo.self) { m in
                    {
                        m -> PlaybackView in
                        if self.active {
                            self.active = false
                            update_pbv(m:m)
                        }
                        self.pbv.tabpbv.trackInfo.m = nil
                        return self.pbv.pbv
                    } (m)
                }.navigationBarBackButtonHidden(false)
                    .toolbar(.visible, for: .navigationBar)
                
                self.pbv.tabpbv
            }
        }
        
    }
     
    var player : AVQueuePlayer
    func add_music (filename: String) {
        
        let file_url = URL(filePath: dir + "/Documents/" + filename)
        let asset = AVAsset(url: file_url)
        let track = TrackInfo()
    
        asset.loadMetadata(for: .iTunesMetadata) {
            items, b in
            if (items == nil) { return }
            for i in items! {
                if(i.identifier == .iTunesMetadataCoverArt) {
                    Task{
                        let imageData = try await i.load(.dataValue)
                        track.art = Image(uiImage: UIImage(data: imageData!)!)
                        /*if (track.art != nil) {
                            track.art!.resizable().scaledToFill().frame(width: geo.width, height: geo.height)
                        }*/
                    }
                }
            }
        }
        let item = AVPlayerItem(url: file_url)
        track.s = filename.prefix(filename.count - 4).removingPercentEncoding!
        track.m = item
        self.music.addItem(str: track)
        //item.addObserver(self, forKeyPath: "status", context: nil)
        self.player.insert(item, after: nil)
        
        if (self.player.status == .failed) {
            print(self.player.error!)
        }
        else {
            self.player.play()
        }
    }
    init() {
        self.pbv = PlaybackViewProxy()
        let base = "https://billsun.dev/webdav/music-test"
        let url = URL(string: base)
        var request: URLRequest = URLRequest(url: url!)
        let session = URLSession(configuration: .default)
        self.dir = NSHomeDirectory()
        let dir = self.dir
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playback, mode: .default, policy: .longFormAudio, options: .duckOthers)
        } catch {
            print(error)
        }
        self.player = AVQueuePlayer()
        self.nowplaying = TrackInfo()
        
        self.nowplaying.cv = self
        
        self.pbv.pbv.parent = self
        self.pbv.tabpbv.parent = self
        
        self.player.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        
        self.player.addObserver(self.nowplaying, forKeyPath: "currentItem",options: [.old, .new], context: &self)
        
        session.dataTask(with: request, completionHandler:
        { [self] (data, response, error) -> Void in
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
                        var tries = 16
                        /*
                        func try_save_response (data: Data?, response: URLResponse?, error: Error?) -> Void {
                            if (error == nil) {
                                let fp = fopen(filepath, "wb")
                                data!.withUnsafeBytes({ ptr in
                                    fwrite(ptr, 1, data!.count, fp)
                                })
                                fclose(fp)
                                add_music(filename: file)
                            }
                            else {
                                if (tries > 0) {
                                    tries -= 1
                                    session.dataTask(with: URLRequest(url: URL(string: base + "/" +  _file)!, timeoutInterval: TimeInterval(100000 * (5 - tries))), completionHandler: try_save_response).resume()
                                }
                            }
                        }*/
                        
                        var req = URLRequest(url: URL(string: base + "/" +  _file)!, timeoutInterval: 65536)
                        func try_download (u: URL?, r: URLResponse?, e: Error?) -> Void { // use download to avoid memory overflow
                            if (e == nil) {
                                do {
                                    try FileManager.default.moveItem(at: u!, to: URL(filePath: filepath))
                                } catch { print(error) }
                                add_music(filename: file)
                            } else if (tries > 0) {
                                tries -= 1
                                if let e = e as? NSError,
                                   let data = e.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                                    session.downloadTask(withResumeData: data, completionHandler: try_download).resume()
                                }
                                else {
                                    session.downloadTask(with: req, completionHandler: try_download).resume()
                                }
                            }
                        }
                        session.downloadTask(with: req, completionHandler: try_download).resume()
                        
                    
                        //session.dataTask(with: URLRequest(url: URL(string: base + "/" +  _file)!, timeoutInterval: TimeInterval(65535)), completionHandler: try_save_response).resume()
                    }
                }
            }catch{}
        }
        ).resume()
        
        let enumerator = FileManager.default.enumerator(atPath: dir + "/Documents/")
        enumerator!.forEach({ e in add_music(filename: (e as! String))})
        
        self.pbv.pbv.update(music: self.nowplaying)
        self.pbv.tabpbv.update(music: self.nowplaying)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().ignoresSafeArea(.all).cornerRadius(.zero).padding(.zero)
    }
    
}
