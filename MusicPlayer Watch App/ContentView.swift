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

struct ContentView: View {
    @ObservedObject var music = ListViewModel()
    var body: some View {
        
            List() {
                ForEach(music.music) { m in
                    
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
                            
                        }).ignoresSafeArea(.all).cornerRadius(.zero).padding(.zero).frame(maxHeight: CGFloat(50)).foregroundColor(.white)
                    
                    }
                
            }
    }
    var player : AVQueuePlayer? = nil
    
    init() {
        print("'sibal'");
        let base = "https://billsun.dev/webdav/music-test"
        let url = URL(string: base)
        let request: URLRequest = URLRequest(url: url!)
        let session = URLSession(configuration: .default)
        let dir = NSHomeDirectory()
        
        session.dataTask(with: request, completionHandler:
        { (data, response, error) -> Void in
            if (error == nil) { return }
            let reply = String(data: data!, encoding: String.Encoding.utf8)!
            
            do {
                let pattern  = try Regex(#".*(<a\s+href=\"(.*.m4a)\">)"#)
                let matched =  reply.matches(of: pattern)
                
                var s = Set<String>()
                for match in matched {
                    s.insert(String(match.output[2].substring!))
                }
                for file in s {
                    let filepath = dir + "/Documents/" + file
                    var download = true
                    if(FileManager.default.fileExists(atPath: filepath)) {
                        let sz = try! FileManager.default.attributesOfItem(atPath: filepath)[FileAttributeKey.size] as! UInt64
                        download = sz < 1024
                    }
                    if (download)
                    {
                        session.dataTask(with: URLRequest(url: URL(string: base + "/" +  file)!)) {
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
            asset.loadMetadata(for: .iTunesMetadata) {
                items, b in
                for i in items! {
                    if(i.identifier == .iTunesMetadataCoverArt) {
                        Task{
                            let imageData = try await i.load(.dataValue)
                            idstr.art = Image(uiImage: UIImage(data: imageData!)!)
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
