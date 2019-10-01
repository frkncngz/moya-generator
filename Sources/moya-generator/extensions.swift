//
//  File.swift
//  
//
//  Created by Furkan Cengiz on 30.09.2019.
//

import Foundation

extension String {
    static var tab = "\t"    
    static var newline = "\n"
    
    static func tab(count: Int) -> String {
        return String(repeating: "\t", count: count)
    }
    func tabbed(count: Int) -> String {
        if count == 0 {
            return self
        } else {
            return "\(String.tab)\(self)".tabbed(count: count - 1)
        }
    }
    func newlined() -> String {
        return "\(String.newline)\(self)"
    }
    
    func substring(with nsRange: NSRange) -> Substring? {
        guard let range = Range(nsRange, in: self) else { return nil }
        return self[range]
    }
}
