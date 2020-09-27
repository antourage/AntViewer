//
//  ButtonWithTouchSize.swift
//  Antourage
//
//  Created by Mykola Vaniurskyi on 27.09.2020.
//

import UIKit

class ButtonWithTouchSize: UIButton {

    var touchAreaPadding: UIEdgeInsets? = nil

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let inset = touchAreaPadding {
            let origin = CGPoint(x: 0 - inset.left, y: 0 - inset.top)
            let size = CGSize(width: inset.left + bounds.width + inset.right,
                              height: inset.top + bounds.height + inset.bottom)
            let rect = CGRect(origin: origin, size: size)
            return rect.contains(point)
        } else {
            return super.point(inside: point, with: event)
        }
    }
}
