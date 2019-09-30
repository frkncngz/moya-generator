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

enum \(Constants.Keys.ProviderName) {
{providerEnums}
}

extension \(Constants.Keys.ProviderName): TargetType {
    var baseURL: URL {
        return URL(string: "\(Constants.Keys.BaseUrl)")!
    }

    var path: String {
        switch self {
        \(Constants.Keys.PathSwitchCases)
        }
    }

    var method: Moya.Method {
        switch self {
        \(Constants.Keys.MethodSwitchCases)
        }
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        switch self {
        \(Constants.Keys.TaskSwitchCases)
        }
    }

    var headers: [String: String]? {
        return [
            \(Constants.Keys.Headers)
        ]
    }
}
"""

class Generator {
    class func generate(from: Config) -> String {
        var output = providerTemplate.replacingOccurrences(of: Constants.Keys.ProviderName, with: from.providerName)
        output = output.replacingOccurrences(of: Constants.Keys.Headers, with: headers(config: from))
        output = output.replacingOccurrences(of: Constants.Keys.BaseUrl, with: from.baseURL)
        output = output.replacingOccurrences(of: Constants.Keys.ProviderEnums, with: enums(from: from))
        output = output.replacingOccurrences(of: Constants.Keys.PathSwitchCases, with: path(from: from))
        output = output.replacingOccurrences(of: Constants.Keys.MethodSwitchCases, with: method(config: from))
        output = output.replacingOccurrences(of: Constants.Keys.TaskSwitchCases, with: task(config: from))
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
            if let regexInside = try? NSRegularExpression(pattern: Constants.RegEx.Inside, options: .caseInsensitive) {
                let matches = regexInside.matches(in: path, options: [], range: NSRange(location: 0, length: path.count))
                if matches.count > 0 {
                    input += "("
                    let inputArray = matches.map { (match) -> String in
                        return "let " + String(path.substring(with: match.range)!)
                    }
                    input += inputArray.joined(separator: ", ")
                    input += ")"
                }
                
                if let regexWhole = try? NSRegularExpression(pattern: Constants.RegEx.Whole, options: .caseInsensitive) {
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
