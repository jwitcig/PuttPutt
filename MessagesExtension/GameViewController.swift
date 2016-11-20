//
//  GameViewController.swift
//  PuttPutt
//
//  Created by Jonah Witcig on 11/17/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import Messages
import SpriteKit
import UIKit

import FirebaseAnalytics

import Game
import iMessageTools
import SwiftTools

public protocol GameController {
    associatedtype GameType
    associatedtype Session: SessionType
    associatedtype Scene
    
    var scene: Scene? { get }
    
    var sceneView: SKView! { get }
    
    var opponentsSession: Session? { get set }
    
    func initiateGame()
    
    func continueGame(from session: Session)
    func startNewGame()
    
    func createScene(initials existingInitials: Session.InitialData?, session previousSession: Session?) -> Scene
}

public extension GameController {
    public func present(scene: SKScene) {
        sceneView.presentScene(scene)
    }
    
    public func initiateGame() {
        if let previousSession = opponentsSession {
            continueGame(from: previousSession)
        } else {
            startNewGame()
        }
    }
}

class GameViewController: MSMessagesAppViewController, GameController {
    static var storyboardIdentifier: String { return "GameViewController" }
    
    typealias GameType = Putt
    typealias Session = PuttSession
    typealias Scene = PuttScene
    
    var messageSender: MessageSender!
    var orientationManager: OrientationManager!
        
    var opponentsSession: Session?
    
    var messageSession: MSSession?
    
    var sceneView: SKView! {
        return view as! SKView
    }
    
    var scene: Scene?
    
    init(fromMessage parser: MessageReader? = nil, messageSender: MessageSender, orientationManager: OrientationManager) {
        
        if let data = parser?.data, let session = Session.init(dictionary: data), !session.ended {
            self.opponentsSession = session
            
            // only continue the MSSession if you are utilizing an unfinished game session
            self.messageSession = parser?.message.session
        }
        
        self.messageSender = messageSender
        self.orientationManager = orientationManager
        super.init(nibName: GameViewController.storyboardIdentifier, bundle: Bundle(for: GameViewController.self))
        
        setBackgroundColor(color: .black)
    }
    
    private func setBackgroundColor(color: UIColor) {
        let blackScene = SKScene()
        blackScene.backgroundColor = color
        present(scene: blackScene)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func continueGame(from session: Session) {
        scene = createScene(initials: session.initial, session: session)
        
        requestPresentationStyle(.expanded)
        
        sceneView.presentScene(scene!)
        
        let confirmation = createActionView(action: .startGame)
        confirmation.action = scene?.game.start
        view.addSubview(confirmation)
        confirmation.reapplyConstraints()
    }
    
    func startNewGame() {
        let confirmation = createActionView(action: .newGame)
        confirmation.action = {
            self.scene = self.createScene(initials: nil, session: nil)
            self.requestPresentationStyle(.expanded)
            
            self.present(scene: self.scene!)
            
            let confirmation = self.createActionView(action: .startGame)
            confirmation.action = self.scene?.game.start
            self.view.addSubview(confirmation)
            confirmation.reapplyConstraints()
        }
        view.addSubview(confirmation)
        confirmation.reapplyConstraints()
    }
    
    private func createActionView(action: GameAction) -> ActionView {
        let actionView = ActionView.create(action: action)
        actionView.centeringConstraints = [
            actionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            actionView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
        ]
        return actionView
    }
    
    public func createScene(initials existingInitials: Session.InitialData?, session previousSession: Session?) -> Scene {
        return Scene.create(initial: existingInitials,
             previousSession: previousSession,
                    delegate: self,
                viewAttacher: self)
    }
}

extension GameViewController: ViewAttachable {
    var superview: UIView { return view }
}

extension GameViewController: GameCycleDelegate {
    func started(game: Game) {
        FIRAnalytics.logEvent(withName: "GameStart", parameters: [:])
    }
    
    func finished<S>(session: S) where S: SessionType & StringDictionaryRepresentable {
        scene?.removeFromParent()
        sceneView?.presentScene(nil)
        
        orientationManager.requestPresentationStyle(.compact)
        
        var layout = MSMessageTemplateLayout()
        if let existingSession = session as? Session {
            layout = PopperMessageLayoutBuilder(session: existingSession).generateLayout()
        }
        
        if let message = Session.MessageWriterType(data: session.dictionary, session: messageSession)?.message {
            messageSender.send(message: message, layout: layout, completionHandler: nil)
        }
    }
}
