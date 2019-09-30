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
        return {_baseURL_}
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
    class func generate(from: Config) {
        let withProviderName = providerTemplate.replacingOccurrences(of: Constants.Keys.providerName, with: from.providerName)
        print("withProviderName \(withProviderName)")
    }
}
