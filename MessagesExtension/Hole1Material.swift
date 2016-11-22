//
//  Hole1Material.swift
//  PuttPutt
//
//  Created by Developer on 11/21/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import SceneKit

class Hole1Material: SCNMaterial {
    
    override init() {
        super.init()
        
        self.diffuse.contents = UIImage(named: "Hole1")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
