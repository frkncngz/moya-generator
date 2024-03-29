//
//  File.swift
//  
//
//  Created by Furkan Cengiz on 30.09.2019.
//

import Foundation
struct Constants {
    struct Keys {
        static var ProviderName = "{providerName}"
        static var BaseUrl = "{baseURL}"
        static var ProviderEnums = "{providerEnums}"
        static var PathSwitchCases = "{pathSwitchCases}"
        static var MethodSwitchCases = "{methodSwitchCases}"
        static var TaskSwitchCases = "{taskSwitchCases}"
        static var Headers = "{headers}"
        static var ModelName = "{modelName}"
        static var ModelParameters = "{modelParameters}"
        static var ModelCodingKeysPlace = "{modelCodingKeysPlace}"
        static var ModelCodingKeys = "{modelCodingKeys}"
        static var ModelEquatable = "{modelEquatable}"
    }
    struct RegEx {
        static var Inside = #"(?<=\{)(.*?)(?=\})"#
        static var Whole = #"\{.*?\}"#
    }
}
