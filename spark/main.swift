//
//  main.swift
//  spark
//
//  Created by Wesley Byrne on 3/30/18.
//  Copyright © 2018 thenounproject. All rights reserved.
//

import Foundation

class Log {
    func print(_ message: Any) {
        Swift.print("\(message)")
    }
    func error(_ message: Any) {
        fputs("Error: \(message)\n", stderr)
    }
}

struct Err : Error {
    let message : String
}

let log = Log()

let args = parseArgs(CommandLine.arguments)

func arg<T>(_ keys: [String], default val: T) -> T {
    return args.first { return keys.contains($0.key) }?.value as? T ?? val
}
func arg(_ keys: [String]) -> Any? {
    return args.first { return keys.contains($0.key) }?.value
}

let current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let _configPath = arg(["c", "config"], default: "./spark.json")
let configURL = URL(fileURLWithPath: _configPath)


do {
    let config = try Config.load(at: configURL)
    
    // Get the output directory
    guard let output = (arg(["o", "output"]) as? String) ?? config.output,
         URL(string: output) != nil else {
        throw Err(message: "Invalid output directory")
    }
    let outputURL = URL(fileURLWithPath: output)
    try? FileManager.default.removeItem(at: outputURL)
    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
    
    log.print("Running \(config.cases.count) cases to \(config.service.absoluteString)")
    
    // TODO: Make the requests
    let session = URLSession.shared
    var idx = 0
    func run() {
        guard idx < config.cases.count else {
            print("Responses saved to \(outputURL.absoluteString) 💥")
            exit(EXIT_SUCCESS)
        }
        let req = config.cases[idx]
        var url = config.service.appendingPathComponent(req.path)
        idx += 1
        if let q = req.params {
            url = url.addingQuery(q)
        }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = req.headers
        if let body = req.body, let data = try? JSONEncoder().encode(body) {
            request.httpBody = data
        }
        
        request.httpMethod = req.method
        session.dataTask(with: url) { (_data, response, error) in
            defer { run() }
            guard let data = _data else {
                print("\(idx) ❌: \(req.path)")
                return
            }
            do {
                let resURL = outputURL.appendingPathComponent(req.name).appendingPathExtension("json")
                try data.write(to: resURL)
                print("\(idx) ✅: \(req.path)")
            }
            catch let err {
                debugPrint(err)
                print("\(idx) ❌ [FAILED WRITE]: \(req.path)")
            }
        }.resume()
    }
    run()
    dispatchMain()
}
catch let err as Err {
    log.error(err.message)
    exit(EXIT_FAILURE)
}
catch let err {
    log.error(err)
    exit(EXIT_FAILURE)
}

