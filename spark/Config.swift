//
//  app.swift
//  spark
//
//  Created by Wesley Byrne on 3/30/18.
//  Copyright © 2018 thenounproject. All rights reserved.
//

import Foundation


struct Config: Decodable {
    let service : URL
    let cases : [Case]
    let headers : [String:String]
    let output : String?
    
    
    static func load(at path: String) throws -> Config {
        
        let configURL = URL(fileURLWithPath: path)
        
        let data = try { () throws -> Data in
            do { return try Data(contentsOf: configURL) }
            catch { throw Err(message: "Unable to load config file from \(path)") }
        }()
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Config.self, from: data)
        }
        catch let err as DecodingError {
            switch err {
            case let .keyNotFound(key, _):
                throw Err(message: "Config missing key `\(key.stringValue)`")
                
            case let .valueNotFound(type, context):
                throw Err(message: "Config missing value for key '\(context.codingPath.last!.stringValue)'. Expected \(type)")
                
            case let .typeMismatch(type, context):
                throw Err(message: "Config has invalid type for key '\(context.codingPath.last!.stringValue)', expected \(type)")
                
            case .dataCorrupted(_):
                throw Err(message: "Config file json is corrupted")
            }
        }
        catch {
            throw Err(message: "Invalid config at path")
        }
    }
}


struct Case : Decodable {
    let name : String
    let method: String
    let path : String
    let headers : [String:String]?
    let params : [String:String]?
    let body : JSON?
}

public enum JSON {
    case string(String)
    case number(Float)
    case object([String:JSON])
    case array([JSON])
    case bool(Bool)
    case null
}

extension JSON: Decodable {
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        
        if let object = try? container.decode([String: JSON].self) {
            self = .object(object)
        } else if let array = try? container.decode([JSON].self) {
            self = .array(array)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Float.self) {
            self = .number(number)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
            )
        }
    }
}
extension JSON: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        switch self {
        case let .array(array):
            try container.encode(array)
        case let .object(object):
            try container.encode(object)
        case let .string(string):
            try container.encode(string)
        case let .number(number):
            try container.encode(number)
        case let .bool(bool):
            try container.encode(bool)
        case .null:
            try container.encodeNil()
        }
    }
}
