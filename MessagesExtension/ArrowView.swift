//
//  ArrowView.swift
//  PuttPutt
//
//  Created by Developer on 11/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import UIKit

class ArrowView: UIView {
    
    var angle: CGFloat = 0
    var scale: CGFloat = 1

    override func draw(_ rect: CGRect) {
        PuttStyleKit.drawArrow(frame: rect, resizing: .center, angle: angle, scale: scale)
    }
}
