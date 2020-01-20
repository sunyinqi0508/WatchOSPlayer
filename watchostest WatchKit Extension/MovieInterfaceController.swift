//
//  MovieInterfaceController.swift
//  watchostest WatchKit Extension
//
//  Created by BillSun on 1/11/20.
//  Copyright © 2020 BillSun. All rights reserved.
//

import WatchKit
import Foundation


class MovieInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var movie: WKInterfaceMovie!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        movie.setHidden(true)
        let setmovie = { () -> Void in
            self.movie.setMovieURL(URL(fileURLWithPath:NSHomeDirectory() + "/Documents/railgun.mp4"))
            self.movie.setLoops(true)
            self.movie.setHidden(false)
        }
        let session = URLSession(configuration: .default);
        if (FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/railgun.mp4")){
            setmovie()
        }
        else {
            session.downloadTask(with: URL(string:"https://billsun.dev/root/papers/03.mp4")!){
                fileurl,_,_ in
                do{
                    try FileManager.default.moveItem(at: fileurl!, to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/railgun.mp4"))
                    
                    setmovie()
                }
                catch{}
            }.resume()
        }
        // Configure interface objects here.
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}
