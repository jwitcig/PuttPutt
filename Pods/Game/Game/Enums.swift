//
//  Enums.swift
//  Game
//
//  Created by Jonah Witcig on 11/2/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import SwiftTools

public enum GameAction: String {
    case newGame = "New Game"
    case startGame = "Start"
}

public enum Team {
    public enum OneOnOne: String {
        case you, them
    }
    public enum Multi {
        case you, them(id: String)
    }
}

public enum GameBegin<T: Game, Session: SessionType> {
    case new(gameType: T.Type)
    case continued(session: Session)
}
