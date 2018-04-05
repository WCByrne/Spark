//
//  app.swift
//  spark
//
//  Created by Wesley Byrne on 3/30/18.
//  Copyright © 2018 thenounproject. All rights reserved.
//

import Foundation


struct Config: Codable {
    let service : URL
    let headers : [String:String]?
    let output : String?
    let oauth: OAuth?
    let properties: [String:String]?
    let cases : [Case]
    
    static func load(at path: String) throws -> Config {
        
        let configURL = URL(fileURLWithPath: path)
        
        let data = try { () throws -> Data in
            do { return try Data(contentsOf: configURL) }
            catch { throw Err(message: "Unable to load config file from \(path)\nTry spark --help") }
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

extension String {
    
    func range(with range: NSRange) -> Range<String.Index> {
        let start = self.index(self.startIndex, offsetBy: range.location)
        let end = self.index(start, offsetBy: range.length)
        return Range<String.Index>(uncheckedBounds: (start, end))
    }
    
}

extension Config {
    
    func injectProperties(_ input: String) -> String {
        
        let regex = try! NSRegularExpression(pattern: "<(.+?)>", options: [])
        var fullRange = NSRange(location: 0, length: input.count)
        var source = input
        
        while let match = regex.firstMatch(in: source, options: [], range: fullRange) {
            let oldLength = source.count
            
            let keyRange = match.range(at: 1)
            let key = String(source[source.range(with: keyRange)])
            guard let replace = self.properties?[key] else {
                return ""
            }
            source.replaceSubrange(source.range(with: match.range(at: 0)), with: replace)
            let newLength = source.count
            
            let loc = match.range.location + match.range.length + (newLength - oldLength)
            fullRange = NSRange(location: loc,
                                length: newLength - loc)
        }
        return source
    }
    
    func injectProperties(_ input: JSON) -> JSON {
        switch input {
        case let .array(value):
            return .array(value.map{ return injectProperties($0) })
        case let .object(value):
            return .object(value.mapValues { return injectProperties($0) })
        case let .string(str):
            return .string(injectProperties(str))
        default:
            return input
        }
    }
    
    func request(for requestCase: Case) -> URLRequest {
        
        var url = self.service.appendingPathComponent(self.injectProperties(requestCase.path))
        if let q = requestCase.params {
            let params = q.mapValues { return self.injectProperties($0) }
            url = url.addingQuery(params)
        }
        
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = requestCase.headers?.mapValues {
            return self.injectProperties($0)
        }
        
        let bodyData : Data? = {
            if let b = requestCase.body {
                let injected = self.injectProperties(b)
                return try? JSONEncoder().encode(injected)
            }
            return nil
        }()
        
        if let oauth = self.oauth {
            var token = oauth.token
            if let tID = requestCase.token {
                token = self.oauth?.tokens?[tID]
                if token == nil {
                    log.error("No token found for key \(tID), using default.")
                }
            }
            request.oAuthSign(method: requestCase.method,
                              body: bodyData,
                              consumerCredentials: oauth.consumer.tup,
                              userCredentials: token?.tup)
            
        }
        else {
            request.httpBody = bodyData
            request.httpMethod = requestCase.method
        }
        return request
    }
    
}


struct OAuth: Codable {
    let consumer: Credential
    let token: Credential?
    let tokens: [String:Credential]?
    
    struct Credential : Codable {
        let key: String
        let secret: String
        
        var tup : (String, String) {
            return (key, secret)
        }
    }
}

struct Case : Codable {
    let name : String
    let method: String
    let path : String
    let headers : [String:String]?
    let params : [String:String]?
    let body : JSON?
    let token: String?
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
