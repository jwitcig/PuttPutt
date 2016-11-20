//
//  ScoreView.swift
//  Popper
//
//  Created by Jonah Witcig on 10/25/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import UIKit

import Game

class ScoreView: UIView {
    @IBOutlet weak var yourScoreLabel: UILabel!
    @IBOutlet weak var theirScoreLabel: UILabel!
    
    @IBOutlet weak var winnerLabel: UILabel!
    
    var yourScore: String {
        get { return yourScoreLabel.text ?? "" }
        set { yourScoreLabel.text = "your time: \(newValue)" }
    }
    var theirScore: String? {
        get { return theirScoreLabel.text }
        set { theirScoreLabel.text = newValue != nil ? "their time: \(newValue!)" : nil }
    }
    
    var winner: Team.OneOnOne? {
        didSet {
            
            guard let winner = winner else {
                winnerLabel.text = "Their turn."
                return
            }
            
            switch winner {
            case .you:
                winnerLabel.text = "You won!"
            case .them:
                winnerLabel.text = "They won."
            }
        }
    }
    
    static func create() -> ScoreView {
        var view: ScoreView!
        view = Bundle.main.loadNibNamed("ScoreView", owner: view, options: nil)!.first! as! ScoreView
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}
