//
//  PuttGame.swift
//  PuttPutt
//
//  Created by Developer on 11/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import GameplayKit
import Messages
import UIKit

import Game
import iMessageTools
import SwiftTools

infix operator |

final class Putt: Game, TypeConstraint {
    typealias Session = PuttSession
    typealias Scene = PuttScene
    
    static let GameName = "PuttPutt"
    
    let initial: PuttInitialData
    
    let padding: Padding? = nil
    
    let lifeCycle: LifeCycle
    
    let previousSession: Session?
    
    init(previousSession: Session?,
                 initial: PuttInitialData?,
                   cycle: LifeCycle) {
        
        self.initial = initial ?? PuttInitialData.random()
                
        self.lifeCycle = cycle
        
        self.previousSession = previousSession
    }
    
    func start() {
        lifeCycle.start()
    }
    
    func finish() {
        lifeCycle.finish()
    }
    
    enum MessageKey: String {
        enum Game: String {
            case score, seed, desiredShapesQuantity
        }
        case gameName = "Popper"
    }
}

extension SessionType {
    typealias Key = String
    typealias Value = String
}

struct PuttSession: SessionType, StringDictionaryRepresentable, Messageable {
    typealias Constraint = Putt
    typealias InitialData = PuttInitialData
    typealias InstanceData = PuttInstanceData
    typealias MessageWriterType = PopperMessageWriter
    typealias MessageLayoutBuilderType = PopperMessageLayoutBuilder
    
    typealias Scene = PuttScene
    
    let initial: InitialData
    let instance: InstanceData
    
    let ended: Bool
    
    let messageSession: MSSession?
    
    var dictionary: [String : String] {
        return instance.dictionary.merged(initial.dictionary).merged(["ended" : ended.string!])
    }
    
    public init(instance: InstanceData, initial: InitialData, ended: Bool = false, messageSession: MSSession?) {
        self.instance = instance
        self.initial = initial
        
        self.ended = ended
        
        self.messageSession = messageSession
    }
    
    public init?(dictionary: [String: String]) {
        guard let instance = InstanceData(dictionary: dictionary) else { return nil }
        guard let initial = InitialData(dictionary: dictionary) else { return nil }
        guard let ended = dictionary["ended"]?.bool else { return nil }
        
        self.instance = instance
        self.initial = initial
        
        self.ended = ended
        
        self.messageSession = nil
    }
}

extension PuttSession {
    var gameData: PuttInstanceData {
        return instance
    }
}

struct PuttInstanceData: InstanceDataType, StringDictionaryRepresentable {
    typealias Constraint = Putt
    
    let score: Double
    let winner: Team.OneOnOne?
    
    var dictionary: [String: String] {
        return [
            "instance-score": score.string!,
            "instance-winner": winner?.rawValue ?? "incomplete",
        ]
    }
    
    init(score: Double, winner: Team.OneOnOne?) {
        self.score = score
        self.winner = winner
    }
    
    init?(dictionary: [String: String]) {
        guard let score = dictionary["instance-score"]?.double else { return nil }
        guard let winner = dictionary["instance-winner"] else { return nil }
        self.init(score: score, winner: Team.OneOnOne(rawValue: winner))
    }
}

struct PuttInitialData: InitialDataType, StringDictionaryRepresentable {
    typealias Constraint = Putt
    
    let holeNumber: Int
    
    var dictionary: [String: String] {
        return [
            "initial-holeNumber": holeNumber.string!,
        ]
    }
    
    init(holeNumber: Int) {
        self.holeNumber = holeNumber
    }
    
    init?(dictionary: [String: String]) {
        guard let holeNumber = dictionary["initial-holeNumber"]?.int else { return nil }
        self.init(holeNumber: holeNumber)
    }
    
    static func random() -> PuttInitialData {
        let holeNumber = GKRandomDistribution(lowestValue: 1, highestValue: 4).nextInt()
        return PuttInitialData(holeNumber: holeNumber)
    }
}

struct PuttMessageReader: MessageReader, SessionSpecific {
    typealias SessionConstraint = PuttSession
    
    var message: MSMessage
    var data: [String: String]
    
    var session: SessionConstraint!
    
    init() {
        self.message = MSMessage()
        self.data = [:]
    }
    
    mutating func isValid(data: [String : String]) -> Bool {
        guard let ended = data["ended"]?.bool else { return false }
        guard let instance = SessionConstraint.InstanceData(dictionary: data) else { return false }
        guard let initial = SessionConstraint.InitialData(dictionary: data) else { return false }
        self.session = PuttSession(instance: instance, initial: initial, ended: ended, messageSession: message.session)
        return true
    }
}

struct PopperMessageWriter: MessageWriter {
    var message: MSMessage
    var data: [String: String]
    
    init() {
        self.message = MSMessage()
        self.data = [:]
    }
    
    func isValid(data: [String : String]) -> Bool {
        guard let _ = data["ended"]?.bool else { return false }
        guard let _ = data["initial-seed"]?.int else { return false }
        guard let _ = data["initial-desiredShapeQuantity"]?.int else { return false }
        guard let _ = data["instance-score"]?.double else { return false }
        guard let _ = data["instance-winner"] else { return false }
        return true
    }
}

struct PopperMessageLayoutBuilder: MessageLayoutBuilder {
    let session: PuttSession
    
    init(session: PuttSession) {
        self.session = session
    }
    
    func generateLayout() -> MSMessageTemplateLayout {
        let layout = MSMessageTemplateLayout()
        layout.image = UIImage(named: "MessageImage")
        layout.caption = "Your turn."
        
        let winners = ["😀", "😘", "😏", "😎", "🤑", "😛", "😝", "😋"]
        let losers  = ["😬", "🙃", "😑", "😐", "😶", "😒", "🙄", "😳", "😞", "😠", "☹️"]
        
        if let winner = session.instance.winner {
            
            switch winner {
            case .you:
                let randomIndex = GKRandomDistribution(lowestValue: 0, highestValue: winners.count-1).nextInt()
                layout.caption = "I won! " + winners[randomIndex]
            case .them:
                let randomIndex = GKRandomDistribution(lowestValue: 0, highestValue: losers.count-1).nextInt()
                layout.caption = "You won. " + losers[randomIndex]
            }
        }
        return layout
    }
    
}

struct HoleSetup {
    static func wallSVGs(forHole hole: Int) -> [String] {
        switch hole {
        case 1:
            return [
                "M -159,-360 L -159,359 159.49,359 160,-359.5 -159,-360 Z M -159,-360"
            ]
        case 2:
            return [
                "M -244,359 L 47.01,359 47,68 244,-227 244,-359 -244,-359 -244,359 Z M -244,359"
            ]
        case 3:
            return [
                "M -244,358 L 97,358 -44,-152.7 56,-152.7 125,122.37 245,122.37 245,-359 -244,-359 -244,358 Z M -244,358"
            ]
        case 4:
            return [
                "M 101.07,-359 C 101.07,-359 244,-240.78 244,-240.78 L 244,-73.6 C 244,-73.6 209.16,-44.79 173.88,-15.61 144.39,8.78 114.6,33.42 104.59,41.7 110.7,62.55 197.61,359 197.61,359 L -198.72,359 C -198.72,359 -112.23,75.78 -102.38,43.53 -116.74,31.65 -244,-73.6 -244,-73.6 L -244,-240.78 -101.07,-359 101.07,-359 101.07,-359 Z M 101.07,-359",
                   "M -126.75,-116.5 L 126.75,-116.5 126.75,-98.75 -126.75,-98.75 -126.75,-116.5 Z M -126.75,-116.5"
            ]
        default:
            fatalError()
        }
    }
}
