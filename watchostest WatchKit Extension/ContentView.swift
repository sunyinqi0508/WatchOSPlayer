//
//  ContentView.swift
//  watchostest WatchKit Extension
//
//  Created by BillSun on 1/10/20.
//  Copyright © 2020 BillSun. All rights reserved.
//
import SwiftUI
import CoreGraphics
class attributes{
    var text = ""
    init(){
        
    }
}
struct ContentView: View {
    @State var image: UIImage = UIImage()
    @State var imgupdated:Bool = true
    @State var text: String? = "あげましておめでとう"
    @State var textupdated: Bool = true
    var parent:HostingController?
    let attr = attributes()
    func updatetext() -> String{
        let dir = NSHomeDirectory()
        var file = fopen(dir + "/Documents/test.txt", "w")
        var str = "testtest!"
        for _ in 0...8     {
            str += str
        }
        for i in 0 ... 1 {
            let filei = fopen(dir + "/Documents/test" + String(i) + ".txt", "w")
            for _ in 0...1{
                fputs(UnsafePointer<Int8>(str), filei)
            }
            fclose(filei)
        }
        fputs(UnsafePointer<Int8>(str), file)
        fclose(file)
        
        var text = ""
        var empty = "          "
        let sstr = UnsafeMutableRawPointer(&empty)
        
        file =  fopen(dir + "/Documents/test.txt", "r")
        fread(sstr, 1, 9, file)
        fclose(file)
        sstr.storeBytes(of: Int8(0), toByteOffset: 9, as: Int8.self)
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info))/4
        
        
        let ptr_info = UnsafeMutablePointer<task_basic_info>(&info)
        let task_info_ptr = unsafeBitCast(ptr_info, to: UnsafeMutablePointer<integer_t>.self)
        
        task_info(mach_task_self_,
                  task_flavor_t(TASK_BASIC_INFO),
                  task_info_t(task_info_ptr),
                  &count)
        let memsize = String(ProcessInfo.processInfo.physicalMemory)
        var filesize = String("Error!")
        do{
            let attr = try FileManager.default.attributesOfItem(atPath: dir + "/Documents/test1.txt")
            filesize = String(attr[FileAttributeKey.size] as! UInt64)
        } catch {
            
        }
        text = String(cString: sstr.assumingMemoryBound(to: Int8.self)) + "\t\n" + String(info.resident_size) +
            "\t\n" + memsize
        text += "\t\n" + filesize
        
        return text
    }
    init(parent: HostingController? = nil)
    {
        
        self.parent = parent
        
        
    }
    var body: some View {
        
        let srect:CGRect = WKInterfaceDevice.current().screenBounds
        let swidth = srect.width
        let sheight = srect.height
        
        
        
        if imgupdated {
            do{
                let session = URLSession(configuration: .default)
                let ret = session.dataTask(with: URL(string: "https://yuruyuri.com/10th/img/pre/topic_miniyuri.png")!) { (data, res, err) in
                    let image = UIImage(data: data!)!
                    let wr = swidth / image.size.width, hr = sheight / image.size.height, ratio = wr < hr ? wr:hr
                    
                    UIGraphicsBeginImageContextWithOptions(srect.size, false, 0.0)
                    let context = UIGraphicsGetCurrentContext()!
                    context.interpolationQuality = CGInterpolationQuality.high
                    context.setFillColor(UIColor.white.cgColor)
                    context.fill(srect)
                    image.draw(in: CGRect(x: (swidth - image.size.width * ratio) / 2, y: (sheight - image.size.height * ratio) / 2, width: image.size.width * ratio, height: image.size.height * ratio))
                    self.image = UIGraphicsGetImageFromCurrentImageContext() ?? image
                    
                    UIGraphicsEndImageContext()
                    if err == nil {
                        self.imgupdated = false
                    }
                }
                ret.resume()
            }
        }
        
        let vstack = VStack(alignment:.center){
            Image(uiImage: image)
                .antialiased(true)
                .interpolation(Image.Interpolation.high)
                .fixedSize()
                .frame(width: swidth, height: sheight, alignment: .center)
        }
        
        return vstack.overlay(Text(self.text!)
            .padding()
            .shadow(color: Color.black, radius: 2)
            //.foregroundColor(Color.white)
        ).contextMenu {
            Button(action: {
                self.parent?.pushController(withName: "movie", context: nil)
            }, label: {Text("movie")})
            Button(action:{self.text = self.updatetext()}, label: {Text("stats")})
        }
        .font(.custom("Aiko-PLUS", size: 15))
        .onLongPressGesture {
            if self.text == ""{
                self.text = self.updatetext()
            }
            else if(self.text == "あげましておめでとう"){
                self.text = ""
            }
            else {
                self.text = "あげましておめでとう"
            }
        }
        .onAppear(){
            self.text = self.updatetext()
        }
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
