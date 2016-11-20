//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Developer on 11/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import UIKit
import Messages

import Firebase

import Game
import iMessageTools

infix operator |

public protocol FirebaseConfigurable: class {
    var servicesFileName: String { get }
    
    func configureFirebase()
}

public extension FirebaseConfigurable {
    internal var bundle: Bundle {
        return Bundle(for: type(of: self) as AnyClass)
    }
    
    internal var servicesFileName: String {
        return bundle.infoDictionary!["Google Services File"] as! String
    }
    
    public func configureFirebase() {
        guard FIRApp.defaultApp() == nil else { return }
        
        let options = FIROptions(contentsOfFile: bundle.path(forResource: servicesFileName, ofType: "plist"))!
        FIRApp.configure(with: options)
    }
}



class MessagesViewController: MSMessagesAppViewController {
    fileprivate var gameController: UIViewController?
    
    var isAwaitingResponse = false
    
    var messageCancelled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureFirebase()
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        if let message = conversation.selectedMessage {
            handleStarterEvent(message: message, conversation: conversation)
        } else {
            let controller = createGameController()
            present(controller)
            controller.initiateGame()
            gameController = controller
        }
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        isAwaitingResponse = true
        
        FIRAnalytics.logEvent(withName: "GameSent", parameters: [:])
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        FIRAnalytics.logEvent(withName: "SendCancelled", parameters: [:])
        
        isAwaitingResponse = false
        messageCancelled = true
        if let controller = gameController {
            throwAway(controller: controller)
        }
    }
}

extension MessagesViewController: iMessageCycle {
    func handleStarterEvent(message: MSMessage, conversation: MSConversation) {
        if let controller = gameController {
            throwAway(controller: controller)
        }
        
        guard !MSMessage.isFromCurrentDevice(message: message, conversation: conversation) else {
            showWaitingForOpponent()
            return
        }
        
        isAwaitingResponse = false
        
        let controller = createGameController(fromMessage: GeneralMessageReader(message: message))
        present(controller)
        controller.initiateGame()
        gameController = controller
    }
}

extension MessagesViewController: MessageSender { }
extension MessagesViewController: FirebaseConfigurable { }

extension MessagesViewController {
    func createActionView(action: GameAction? = nil) -> ActionView {
        let actionView = ActionView.create(action: action)
        actionView.centeringConstraints = [
            actionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            actionView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
        ]
        return actionView
    }
    
    fileprivate func showWaitingForOpponent() {
        let actionView = createActionView()
        actionView.buttonText = "Waiting For Opponent"
        if let font = actionView.button.titleLabel?.font {
            actionView.button.titleLabel?.font = UIFont(name: font.fontName, size: 30)
        }
        actionView.isUserInteractionEnabled = false
        view.addSubview(actionView)
        actionView.reapplyConstraints()
    }
    
    fileprivate func createGameController(fromMessage parser: MessageReader? = nil) -> GameViewController {
        return GameViewController(fromMessage: parser, messageSender: self, orientationManager: self)
    }
}
