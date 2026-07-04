//
//  UIWindowScene+Extensions.swift
//  The Clock School
//
//  Created by Sebastian Strus on 3/1/26.
//

import UIKit

extension UIWindowScene {

    var screenSizePointsString: String {
        let bounds = screen.bounds
        return "\(Int(bounds.width))×\(Int(bounds.height)) pt"
    }

    var screenSizePixelsString: String {
        let bounds = screen.nativeBounds
        return "\(Int(bounds.width))×\(Int(bounds.height)) px"
    }
}
