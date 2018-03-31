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
let path = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let configPath = path.appendingPathComponent("config.json")

log.print(configPath)

func getConfig() throws -> [String:Any] {
    do {
        let data = try Data(contentsOf: configPath)
        let decoder = JSONDecoder()
        return try decoder.decode(Dictionary<String, String>.self, from: data)
    }
    catch let err {
        throw Err(message: "Invalid config at path \(configPath): \(err)")
    }
}

do {
    let config = try getConfig()
    print("Config: \(config)")
}
catch let err as Err {
    log.error(err.message)
    exit(EXIT_FAILURE)
}
catch let err {
    log.error(err)
    exit(EXIT_FAILURE)
}

