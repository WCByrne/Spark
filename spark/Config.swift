//
//  app.swift
//  spark
//
//  Created by Wesley Byrne on 3/30/18.
//  Copyright © 2018 thenounproject. All rights reserved.
//

import Foundation


struct Config {
    
    let service : URL
    let cases : []
    let headers : [String:String]
    
}


struct Case {
    let name : String
    let method: String
    let path : String
    let params : [String:String]
    let body : String
    
    
    
    
}
