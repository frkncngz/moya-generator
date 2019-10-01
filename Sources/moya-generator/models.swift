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
    let headers: [String: String]?
    let endpoints: [Endpoint]
    let models: [Model]?
}

struct Endpoint: Codable {
    let name: String
    let altName: String?
    let path: String
    let method: String
    let task: String
    let parameters: [Parameter]?
    let parameterMapping: [String: String]?
}

struct Parameter: Codable {
    let name: String
    let outputName: String?
    let type: String
    let defaultValue: String?
}

struct Model: Codable {
    let name: String
    let parameters: [ModelParameter]
}

struct ModelParameter: Codable {
    let name: String
    let type: String
}
