//
//  File.swift
//  
//
//  Created by Furkan Cengiz on 30.09.2019.
//

import Foundation

struct Config: Codable {
    let providerName: String
    let baseURL: String
    let headers: [[String: String]]?
    let endpoints: [Endpoint]
}

struct Endpoint: Codable {
    let name: String
    let path: String
    let method: String
    let task: String
//    let additionalHeaders: [[String: String]]?
    let input: [Input]?
}

struct Input: Codable {
    let name: String
    let type: String
}
