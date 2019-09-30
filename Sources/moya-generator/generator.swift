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
        return {
            {_headers_}
        }
    }
}
"""

class Generator {
    class func generate(from: Config) -> String {
        var output = providerTemplate.replacingOccurrences(of: Constants.Keys.providerName, with: from.providerName)
        output = output.replacingOccurrences(of: Constants.Keys.headers, with: headers(config: from))
        output = output.replacingOccurrences(of: Constants.Keys.baseUrl, with: from.baseURL)
        output = output.replacingOccurrences(of: Constants.Keys.providerEnums, with: enums(from: from))
        output = output.replacingOccurrences(of: Constants.Keys.pathSwitchCases, with: path(from: from))
        output = output.replacingOccurrences(of: Constants.Keys.methodSwitchCases, with: method(config: from))
        output = output.replacingOccurrences(of: Constants.Keys.taskSwitchCases, with: task(config: from))
        return output
    }
    class func enums(from: Config) -> String {
        let enumStrings = from.endpoints.map { (endpoint) -> String in
            var paramString = ""
            if let param = endpoint.params {
                paramString = "("
                let paramStrings = param.map { (i) -> String in
                    return "\(i.name): \(i.type)"
                }
                paramString += paramStrings.joined(separator: ", ")
                paramString += ")"
            }
            return "case \(endpoint.name)\(paramString)".tabbed(count: 1)
        }
        return enumStrings.joined(separator: String.newline)
    }
    class func path(from: Config) -> String {
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
    class func method(config: Config) -> String {
        var methods: [String: [String]] = [:]
        
        for endpoint in config.endpoints {
            if var methodArray = methods[endpoint.method] {
                methodArray.append(endpoint.name)
                methods[endpoint.method] = methodArray
            } else {
                methods[endpoint.method] = [endpoint.name]
            }
        }
        
        let methodStrings = Array(methods.keys).map { (key) -> String in
            var methodNames = methods[key]!
            methodNames = methodNames.map { (methodName) -> String in
                "." + methodName
            }
            let methodNamesString = methodNames.joined(separator: ", ")
            let returnValue = "return .\(key)".tabbed(count: 3).newlined()
            return "case \(methodNamesString):\(returnValue)"
        }
        return methodStrings.joined(separator: String.newline + String.tab + String.tab)
    }
    class func task(config: Config) -> String {
        var tasks: [String: [String]] = [:]
        
        for endpoint in config.endpoints {
            if var taskArray = tasks[endpoint.task] {
                taskArray.append(endpoint.name)
                tasks[endpoint.task] = taskArray
            } else {
                tasks[endpoint.task] = [endpoint.name]
            }
        }
        
        let taskStrings = Array(tasks.keys).map { (key) -> String in
            var returnTask = ""
            var input = ""
            switch key {
            case "plain":
                returnTask = ".requestPlain"
            case "data":
                input = "(let data)"
                returnTask = "Task.requestData(data)"
            default: break
            }
            
            var taskNames = tasks[key]!
            taskNames = taskNames.map { (taskName) -> String in
                "." + taskName + input
            }
            let taskNamesString = taskNames.joined(separator: ", ")
            
            let returnValue = "return \(returnTask)".tabbed(count: 3).newlined()
            return "case \(taskNamesString):\(returnValue)"
        }
        return taskStrings.joined(separator: String.newline + String.tab + String.tab)
    }
    
    // this can be done with (from.headers as AnyObject) as well but it is not pretty formatted.
    class func headers(config: Config) -> String {
        var output = ""
        if let headers = config.headers {
            let headerArray = Array(headers.keys).map { (key) -> String in
                "\"\(key)\": \"\(String(describing: headers[key]))\""
            }
            output = headerArray.joined(separator: String.newline + String.tab + String.tab + String.tab)
        }
        return output
    }
}
