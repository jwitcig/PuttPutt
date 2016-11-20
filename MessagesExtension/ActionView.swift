//
//  NewGameView.swift
//  Popper
//
//  Created by Jonah Witcig on 10/26/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import UIKit

import Game

class ActionView: UIView {
    var action: (()->Void)?
    
    @IBOutlet weak var button: UIButton!
    
    var buttonText: String? {
        get { return button.currentTitle }
        set { button.setTitle(newValue, for: .normal) }
    }
    
    var centeringConstraints = [NSLayoutConstraint]()
    
    static func create(action: GameAction? = nil, buttonText: String? = nil) -> ActionView {
        var view: ActionView!
        
        view = Bundle.main.loadNibNamed("ActionView", owner: view, options: nil)!.first! as! ActionView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.buttonText = action?.rawValue
        view.buttonText = buttonText ?? action?.rawValue
        return view
    }
    
    func reapplyConstraints() {
        centeringConstraints.forEach {
            $0.isActive = true
        }
    }
    
    @IBAction func buttonPressed(sender: Any) {
        removeFromSuperview()
        action?()
        action = nil
    }
}
