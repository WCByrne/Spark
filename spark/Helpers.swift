//
//  Helpers.swift
//  spark
//
//  Created by Wes Byrne on 3/30/18.
//  Copyright © 2018 thenounproject. All rights reserved.
//

import Foundation

func parseArgs(_ input: [String]) -> [String:Any] {
    var res = [String:Any]()
    guard input.count > 1 else { return res }
    var idx = 1
    while idx < input.count {
        let key = input[idx].trimmingCharacters(in: CharacterSet(charactersIn: " -"))
        var val : Any = true
        let next = idx + 1
        if next < input.count && !input[next].hasPrefix("-") {
            idx += 1
            val = input[next]
        }
        res[key] = val
        idx += 1
    }
    return res
}


extension URL {
    
    func addingQuery(_ params: [String:String]) -> URL {
        
        var comps = URLComponents(url: self, resolvingAgainstBaseURL: false)
        var newItems = [URLQueryItem]()
        
        for p in params {
            newItems.append(URLQueryItem(name: p.key, value: p.value))
        }
        
        if let items = comps?.queryItems {
            for i in items {
                if params[i.name] == nil {
                    newItems.append(i)
                }
            }
        }
        comps?.queryItems = newItems
        return comps?.url ?? self
    }
}
