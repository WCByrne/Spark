//
//  main.swift
//  spark
//
//  Created by Wesley Byrne on 3/30/18.
//  Copyright © 2018 thenounproject. All rights reserved.
//

import Foundation

class Log {
    
    enum Color : String {
        case `default` = ""
        case green = "\u{001B}[0;32m"
        case red = "\u{001B}[0;31m"
    }
    
    func print(_ message: Any) {
        Swift.print("\(message)")
    }
    func info(_ message: Any) {
        write("\(message)", color: .green)
    }
    func error(_ message: Any) {
        write("Error: \(message)", color: .red)
    }
    func write(_ message: String, color: Color = .default) {
        if color == .default {
            Swift.print(message)
        }
        else {
            Swift.print("\(color.rawValue)\(message)\u{001B}[0;0m")
        }
    }
}

struct Err : Error {
    let message : String
}

let log = Log()

let args = parseArgs(CommandLine.arguments)
let current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

func arg<T>(_ keys: [String], default val: T) -> T {
    return args.first { return keys.contains($0.key) }?.value as? T ?? val
}
func arg(_ keys: [String]) -> Any? {
    return args.first { return keys.contains($0.key) }?.value
}

if arg(["h", "help"]) != nil {
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
    print("----------------------------------------")
    
    exit(EXIT_SUCCESS)
}

if args["init"] != nil {
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
    try! output.write(to: path)
    
    log.print("💥 Created spark config file \(path.path). Update then run spark")
    exit(EXIT_SUCCESS)
}





let configPath = arg(["c", "config"], default: "./spark.json")

do {
    let config = try Config.load(at: configPath)
    
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
            print("💥 Responses saved to \(output)")
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
        if let oauth = config.oauth {
            var data: Data?
            if let body = req.body {
                data = try? JSONEncoder().encode(body)
            }
            var token = oauth.token
            if let tID = req.token {
                token = config.oauth?.tokens?[tID]
                if token == nil {
                    log.error("No token found for key \(tID), using default.")
                }
            }
            request.oAuthSign(method: req.method,
                              body: data,
                              consumerCredentials: oauth.consumer.tup,
                              userCredentials: token?.tup)
            
        }
        else {
            if let body = req.body, let data = try? JSONEncoder().encode(body) {
                request.httpBody = data
            }
            request.httpMethod = req.method
        }
        
        
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

