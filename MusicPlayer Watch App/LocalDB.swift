//
//  LocalDB.swift
//  MusicPlayer Watch App
//
//  Created by billsun on 4/22/23.
//

import Foundation


class LocalDB {
    var datasource : String
    var mode : Int32
    
    
    init(datasource: String, mode: Int32) {
        self.datasource = datasource
        self.mode = mode
    }
}
