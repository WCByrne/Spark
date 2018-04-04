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

func createConfig(args: [String:Any]) {
    var path : URL
    if let p = args["init"] as? String {
        path = URL(fileURLWithPath: p)
    }
    else {
        path = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }
    if path.hasDirectoryPath == true {
        path = path.appendingPathComponent("spark.json")
    }
    if FileManager.default.fileExists(atPath: path.path) && args["f"] as? Bool != true {
        log.error("Config file already exists at path. Use -f to replace")
        exit(EXIT_FAILURE)
    }
    
    try? FileManager.default.removeItem(at: path)
    let auth = OAuth(
        consumer: OAuth.Credential(key: "consumer-key", secret: "consumer-secret"),
        token: OAuth.Credential(key: "token-key", secret: "token-secret"),
        tokens: nil)
    let cases = [
        Case(name: "test-case-one", method: "GET", path: "/v1/endpoint", headers: nil, params: nil, body: nil, token: nil)
    ]
    let headers = [
        "x-service-header":"header-value"
    ]
    
    let config = Config(service: URL(string: "http://api.myservice.com")!,
                        cases: cases,
                        headers: headers,
                        output: "./SparkResponses",
                        oauth: auth)
    
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let output =  try! encoder.encode(config)
    
    let str = String(data: output, encoding: .utf8)!
        .replacingOccurrences(of: "\\/", with: "/")
    let data = str.data(using: .utf8)!
    try! data.write(to: path)
    
    log.print("💥 Created spark config file \(path.path). Update then run spark")
}

func printHelp() {
    log.print("\n----------------------------------------")
    log.print("Welcome to Spark\n")
    log.print("🛠  Create a config template file")
    log.info("   spark init [path] [-f]")
    log.print("""
       path: defaults to ./spark.json
       -f  : overwrite an existing config with the template

    """)
    
    log.print("🏃‍♂️ Run spark using a config file")
    log.info("   spark [-o --output] [-c --config]")
    log.print("""
       -o --output: the directory to save responses to. Can be specified in your config file.
       -c --config: the path to your config file. defaults to ./spark.json

    """)
    log.print("----------------------------------------")
}
