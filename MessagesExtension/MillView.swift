//
//  MillView.swift
//  PuttPutt
//
//  Created by Developer on 11/21/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import UIKit

class MillView: UIView {
    
    var number: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }
    var right = true
    
    override func draw(_ rect: CGRect) {
        translatesAutoresizingMaskIntoConstraints = false
        PuttStyleKit.drawCanvasBlock(frame: rect, resizing: .aspectFit, number: number)
    }
    
    var timer: Timer?
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1/50.0, repeats: true, block: { _ in
            
            self.number += self.right ? 1 : -1
            print(self.number)
            if self.number > 124 {
                self.right = false
                self.number -= 5
            }
            if self.number < 0 {
                self.right = true
            }
        })
    }
}
