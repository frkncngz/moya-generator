//
//  File.swift
//  
//
//  Created by Furkan Cengiz on 30.09.2019.
//

import Foundation



let providerTemplate = """
import Foundation
import Moya

enum \(Constants.Keys.providerName) {
{_providerEnums_}
}

extension \(Constants.Keys.providerName): TargetType {
    var baseURL: URL {
        return URL(string: "{_baseURL_}")!
    }

    var path: String {
        switch self {
        {_pathSwitchCases_}
        }
    }

    var method: Moya.Method {
        switch self {
        {_methodSwitchCases_}
        }
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        switch self {
        {_taskSwitchCases_}
        }
    }

    var headers: [String: String]? {
        return {_headers_}
    }
}
"""

class Generator {
    class func generate(from: Config) -> String {
        var output = providerTemplate.replacingOccurrences(of: Constants.Keys.providerName, with: from.providerName)
        output = output.replacingOccurrences(of: Constants.Keys.baseUrl, with: from.baseURL)
        output = output.replacingOccurrences(of: Constants.Keys.providerEnums, with: enums(from: from))
        output = output.replacingOccurrences(of: Constants.Keys.pathSwitchCases, with: path(from: from))
//        print("output \(output)")
        return output
    }
    class func enums(from: Config) -> String {
        let enumStrings = from.endpoints.map { (endpoint) -> String in
            var inputString = ""
            if let input = endpoint.input {
                inputString = "("
                let inputStrings = input.map { (i) -> String in
                    return "\(i.name): \(i.type)"
                }
                inputString += inputStrings.joined(separator: ", ")
                inputString += ")"
            }
            return "case \(endpoint.name)\(inputString)".tabbed(count: 1)
        }
        return enumStrings.joined(separator: String.newline)
    }
    class func path(from: Config) -> String {
//        case .nodeInfo:
//        return "/node/status"
        
//        case .balance(let address):
//        return "/addresses/balance/\(address)/0"
//        var output = ""
        
        let pathStrings = from.endpoints.map { (endpoint) -> String in
            var input = ""
            var path = endpoint.path
            
            //check if there are arguments to add
            if let regexInside = try? NSRegularExpression(pattern: #"(?<=\{\_)(.*?)(?=\_\})"#, options: .caseInsensitive) {
                let matches = regexInside.matches(in: path, options: [], range: NSRange(location: 0, length: path.count))
                if matches.count > 0 {
                    input += "("
                    let inputArray = matches.map { (match) -> String in
                        return "let " + String(path.substring(with: match.range)!)
                    }
                    input += inputArray.joined(separator: ", ")
                    input += ")"
                }
                
                if let regexWhole = try? NSRegularExpression(pattern: #"\{\_.*?\_\}"#, options: .caseInsensitive) {
                    while regexWhole.matches(in: path, options: [], range: NSRange(location: 0, length: path.count)).count > 0 {
                        
                        let match = regexWhole.matches(in: path, options: [], range: NSRange(location: 0, length: path.count)).first!
                                                                        
                        let matchedString = String(path.substring(with: match.range)!)
                        print("matchedString \(matchedString)")
                        
                        if let match = regexInside.matches(in: matchedString, options: [], range: NSRange(location: 0, length: matchedString.count)).first {
                            let variableName = matchedString.substring(with: match.range)
                            path = path.replacingOccurrences(of: matchedString, with: "\\(\(String(describing: variableName)))")
                        }
                    }
                }
                
            }
            let returnString = "return \"\(path)\""
            return "case .\(endpoint.name)\(input):\(returnString.tabbed(count: 3).newlined())"
        }
        return pathStrings.joined(separator: String.newline + String.tab + String.tab)
    }
}
