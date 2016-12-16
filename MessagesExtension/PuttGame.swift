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

import SVGgh
import SWXMLHash

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
    typealias MessageWriterType = PuttMessageWriter
    typealias MessageLayoutBuilderType = PuttMessageLayoutBuilder
    
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
    
    let shots: [Int]
    let opponentShots: [Int]
    let winner: Team.OneOnOne?
    
    var dictionary: [String: String] {
        let shotsString = shots.reduce("") {$0 + "\($1)."}
        let opponentShotsString = opponentShots.reduce("") {$0 + "\($1)."}
        return [
            "instance-shots": shotsString,
            "instance-opponentShots": opponentShotsString,
            "instance-winner": winner?.rawValue ?? "incomplete",
        ]
    }
    
    init(shots: [Int], opponentShots: [Int]? = nil, winner: Team.OneOnOne?) {
        self.shots = shots
        self.opponentShots = opponentShots ?? []
        self.winner = winner
    }
    
    init?(dictionary: [String: String]) {
        guard let shots = dictionary["instance-shots"] else { return nil }
        guard let opponentShots = dictionary["instance-opponentShots"] else { return nil }
        guard let winner = dictionary["instance-winner"] else { return nil }
        
        let shotsList = shots.characters.split(separator: ".").map{String($0).int!}
        let opponentShotsList = opponentShots.characters.split(separator: ".").map{String($0).int!}
        
        self.init(shots: shotsList, opponentShots: opponentShotsList, winner: Team.OneOnOne(rawValue: winner))
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
        return PuttInitialData(holeNumber: 1)
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

struct PuttMessageWriter: MessageWriter {
    var message: MSMessage
    var data: [String: String]
    
    init() {
        self.message = MSMessage()
        self.data = [:]
    }
    
    func isValid(data: [String : String]) -> Bool {
        guard let _ = data["ended"]?.bool else { return false }
        guard let _ = data["initial-holeNumber"]?.int else { return false }
        guard let _ = data["instance-shots"] else { return false }
        guard let _ = data["instance-opponentShots"] else { return false }
        guard let _ = data["instance-winner"] else { return false }
        return true
    }
}

struct PuttMessageLayoutBuilder: MessageLayoutBuilder {
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
            case .tie:
                layout.caption = "We tied."
            }
        }
        return layout
    }
    
}

struct HoleSetup {
    static func scale(forHole hole: Int) -> CGFloat {
        switch hole {
        case 1:
            return 0.8
        case 2:
            return 0.5
        case 3:
            return 0.5
        case 4:
            return 0.5
        case 5:
            return 0.5
        case 6:
            return 0.5
        case 7:
            return 0.5
        case 8:
            return 0.75
        case 9:
            return 0.75
        default:
            return 1
        }
    }
    
    static func ballLocation(forHole hole: Int) -> CGPoint {
        let url = Bundle(for: Putt.self).url(forResource: "hole\(hole)", withExtension: "svg")!
        
        let xml = SWXMLHash.parse(try! Data(contentsOf: url))
        
        let pointData = xml["svg"]["path"].filter {
            $0.element!.attribute(by: "id")!.text == "hole\(hole)-ballLocation"
        }.first!.element!
            .attribute(by: "d")!.text
            .replacingOccurrences(of: "M ", with: "")
            .components(separatedBy: ",")

        let formatter = NumberFormatter()
        return CGPoint(x: formatter.number(from: pointData.first!)!.intValue,
                       y: -formatter.number(from: pointData.last!)!.intValue)
    }
    
    static func wallSVGs(forHole hole: Int) -> [String] {
        let url = Bundle(for: Putt.self).url(forResource: "hole\(hole)", withExtension: "svg")!
        let data = try! Data(contentsOf: url)
        let xml = SWXMLHash.parse(data)
        
        let wallItems = xml["svg"]["path"].filter {
            
            (try! $0.value(ofAttribute: "id") as! String).contains("green")
        }
        
        return wallItems.map {
            try! $0.value(ofAttribute: "d") as! String
        }
    }
}
