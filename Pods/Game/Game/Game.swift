//
//  Game.swift
//  Game
//
//  Created by Jonah Witcig on 11/2/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import SpriteKit
import JWSwiftTools

public protocol Game: class {    
    static var GameName: String { get }
    
    var padding: Padding? { get }
    
    var lifeCycle: LifeCycle { get }
        
    func start()
    
    func finish()
}
