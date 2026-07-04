//
//  String+Extensions.swift
//  The Clock School
//
//  Created by Sebastian Strus on 2/21/26.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}
