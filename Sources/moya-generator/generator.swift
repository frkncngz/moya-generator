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

let modelTemplate = """
struct \(Constants.Keys.ModelName): Codable\(Constants.Keys.ModelEquatable) {
    \(Constants.Keys.ModelParameters)\(Constants.Keys.ModelCodingKeysPlace)
}
"""

let codingKeysTemplate = """
    private enum CodingKeys: String, CodingKey {
        \(Constants.Keys.ModelCodingKeys)
    }
"""

class Generator {
    class func generateProvider(from: Config) -> String {
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
            if let param = endpoint.parameters {
                if param.count > 0 {
                    paramString = "("
                    let paramStrings = param.map { (i) -> String in
                        return "\(i.name): \(i.type)"
                    }
                    paramString += paramStrings.joined(separator: ", ")
                    paramString += ")"
                }
            }
            return "case \(endpoint.name)\(paramString)".tabbed(count: 1)
        }
        return enumStrings.joined(separator: String.newline)
    }
    class func path(from: Config) -> String {
        let pathStrings = from.endpoints.map { (endpoint) -> String in
            var input = ""
            var path = endpoint.path
            
            // check if there are any inputs to add
            // first regex (inside) looks for the variable name and generates the input
            // second regex (whole) looks for the range in path to change
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
                    
                    // since we are changing the string on place, this loop makes sure we always get the correct range after a change in the string
                    while regexWhole.matches(in: path, options: [], range: NSRange(location: 0, length: path.count)).count > 0 {
                        
                        let match = regexWhole.matches(in: path, options: [], range: NSRange(location: 0, length: path.count)).first!
                                                                        
                        // Range vs NSRange mambo jambo
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
        return pathStrings.joined(separator: String.newline + String.tab(count: 2))
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
        return methodStrings.joined(separator: String.newline + String.tab(count: 2))
    }
    class func task(config: Config) -> String {
        var tasks: [String: [String]] = [:]
        
        // we group the endpoints by their task type (plain, data, params)
        for endpoint in config.endpoints {
            if var taskArray = tasks[endpoint.task] {
                taskArray.append(endpoint.name)
                tasks[endpoint.task] = taskArray
            } else {
                tasks[endpoint.task] = [endpoint.name]
            }
        }
        
        // we generate input for plain and data since they are static
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
            
            // if the task is params, we need to dynamically generate the input and parameters
            if key == "parameters" {
                
                // iterate everything again for parameters
                var paramsOutput = ""
                if let endpointsWithParams = tasks[key] {
                    let endpointsWithParamsStrings = endpointsWithParams.map { (endpointWithParams) -> String in
                        
                        // storing this separately to use it in parameter mappings
                        var paramsDictionaryStringValues = ""
                        var paramsDictionaryString = ""
                        
                        // find the corresponding endpoint and generate both inputs and parameters
                        let endpoint = config.endpoints.first { $0.name == endpointWithParams}!
                        if let params = endpoint.parameters {                            
                            let paramsArray = params.filter{ $0.defaultValue == nil}.map { (param) -> String in
                                "let \(param.name)"
                            }
                            let paramsDictionaryArray = params.map { (param) -> String in
                                "\"\(param.outputName ?? param.name)\": \(param.defaultValue ?? param.name)".tabbed(count: 4).newlined()
                            }
                            paramsDictionaryStringValues = paramsDictionaryArray.joined(separator: ",")
                            if paramsArray.count > 0 {
                                input = "(" + paramsArray.joined(separator: ", ") + ")"
                            } else {
                                input = ""
                            }
                            paramsDictionaryString += "parameters = [".tabbed(count: 3).newlined()
                            if paramsDictionaryStringValues == "" {
                                paramsDictionaryString += ":]"
                            } else {
                                paramsDictionaryString += paramsDictionaryStringValues
                                paramsDictionaryString += "]".tabbed(count: 3).newlined()
                            }
                        }
                        
                        var returnValue = "let parameters: [String: Any]".tabbed(count: 3).newlined()
                        returnValue += paramsDictionaryString
                        
                        if let parameterMapping = endpoint.parameterMapping {
                            let mappingKeys = Array(parameterMapping.keys)
                            let mappingArray = mappingKeys.map { (key) -> String in
                                if let mappingValue = parameterMapping[key] {
                                    // special cases:
                                    // $parameters
                                    if mappingValue.contains("$parameters") {
                                        return "\"\(key)\": \(mappingValue.replacingOccurrences(of: "$parameters", with: "parameters"))"
                                    }
                                    
                                    // $altName
                                    if mappingValue.contains("$altName") {
                                        if let altName = endpoint.altName {
                                            return "\"\(key)\": \"\(altName)\""
                                        }
                                    }
                                    
                                    return "\"\(key)\": \"\(mappingValue)\""
                                }
                                return ""
                            }
                            
                            let parametersString = mappingArray.joined(separator: "," + String.newline + String.tab(count: 4)).tabbed(count: 4).newlined()
                            
                            returnValue += "return .requestParameters(parameters: [\(parametersString)\("]".tabbed(count: 3).newlined()), encoding: JSONEncoding())".tabbed(count: 3).newlined()
                        } else {
                            returnValue += "return .requestParameters(parameters: parameters, encoding: JSONEncoding())".tabbed(count: 3).newlined()
                        }
                        return "case .\(endpointWithParams)\(input):\(returnValue)"
                    }
                    paramsOutput = endpointsWithParamsStrings.joined(separator: String.newline + String.tab(count: 2))
                }
                return paramsOutput
            } else {
                var taskNames = tasks[key]!
                taskNames = taskNames.map { (taskName) -> String in
                    "." + taskName + input
                }
                let taskNamesString = taskNames.joined(separator: ", ")
                
                let returnValue = "return \(returnTask)".tabbed(count: 3).newlined()
                return "case \(taskNamesString):\(returnValue)"
            }
        }
        return taskStrings.joined(separator: String.newline + String.tab(count: 2))
    }
    
    // this can be done with (from.headers as AnyObject) as well but it is not pretty formatted.
    class func headers(config: Config) -> String {
        var output = ""
        if let headers = config.headers {
            let headerArray = Array(headers.keys).map { (key) -> String in
                "\"\(key)\": \"\(String(describing: headers[key]))\""
            }
            output = headerArray.joined(separator: "," + String.newline + String.tab(count: 3))
        }
        return output
    }
    
    class func generateModels(from: Config) -> String {
        if let models = from.models {
            let modelStringArray = models.map { (model) -> String in
                var modelString = modelTemplate.replacingOccurrences(of: Constants.Keys.ModelName, with: model.name)
                
                let equatableString = (model.equatable ?? false) ? ", Equatable" : ""
                modelString = modelString.replacingOccurrences(of: Constants.Keys.ModelEquatable, with: equatableString)
                
                let parametersStringArray = model.parameters.map { (parameter) -> String in
                    "let \(parameter.name): \(parameter.type)"
                }
                
                modelString = modelString.replacingOccurrences(of: Constants.Keys.ModelParameters, with: parametersStringArray.joined(separator: String.newline + String.tab))
                
                
                let specificOutputs = model.parameters.filter {
                    $0.outputName != nil
                }
                if specificOutputs.count > 0 {
                    let specificOutputsArray = specificOutputs.map { (parameter) -> String in
                        return "case \(parameter.name) = \"\(parameter.outputName ?? parameter.name)\""
                    }
                    let specificOutputsString = specificOutputsArray.joined(separator: String.newline + String.tab(count: 2))
                    let codingKeysString = codingKeysTemplate.replacingOccurrences(of: Constants.Keys.ModelCodingKeys, with: specificOutputsString)
                    modelString = modelString.replacingOccurrences(of: Constants.Keys.ModelCodingKeysPlace, with: codingKeysString.newlined().newlined())
                } else {
                    modelString = modelString.replacingOccurrences(of: Constants.Keys.ModelCodingKeysPlace, with: "")
                }
                
                return modelString
            }
            return modelStringArray.joined(separator: String.newline)
        }
        return ""
    }
}
