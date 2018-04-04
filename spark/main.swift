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
        write("\(message)", color: .red)
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
    printHelp()
    exit(EXIT_SUCCESS)
}

if args["init"] != nil {
    createConfig(args: args)
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
            log.print("💥 Responses saved to \(output)")
            exit(EXIT_SUCCESS)
        }
        let reqCase = config.cases[idx]
        let request = config.request(for: reqCase)
        idx += 1
        let _idx = idx
        
        session.dataTask(with: request) { (_data, response, error) in
            defer { run() }
            guard let data = _data else {
                log.print("\(_idx) ❌: \(reqCase.path)")
                return
            }
            do {
                let resURL = outputURL.appendingPathComponent(reqCase.name).appendingPathExtension("json")
                try data.write(to: resURL)
                log.print("\(_idx) ✅: \(reqCase.path)")
            }
            catch let err {
                log.error("\(idx) ❌ [FAILED WRITE]: \(reqCase.path)")
            }
        }.resume()
    }
    run()
    dispatchMain()
}
catch let err as Err {
    log.error("Error: " + err.message)
    exit(EXIT_FAILURE)
}
catch let err {
    log.error("Error: \(err)")
    exit(EXIT_FAILURE)
}

