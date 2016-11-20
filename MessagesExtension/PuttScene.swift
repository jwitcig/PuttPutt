//
//  GameScene.swift
//  Test
//
//  Created by Jonah Witcig on 10/27/16.
//  Copyright © 2016 Jonah Witcig. All rights reserved.
//

import GameplayKit
import Messages
import SpriteKit

import SVGgh

import Game
import iMessageTools
import SwiftTools

infix operator |

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}

enum BodyCategory: UInt32 {
    case none, wall, ball, hole
}

class PuttScene: SKScene, GameScene, SKPhysicsContactDelegate {
    typealias Session = PuttSession
    
    typealias GameType = Putt

    var game: Game!
    var popper: Putt {
        return game as! Putt
    }
    
    var opponentsSession: Session?
    
    let scoreView = ScoreView.create()
    
    var gameCycleDelegate: GameCycleDelegate!
    
    var viewAttacher: ViewAttachable!
    
    var holeNumber: Int!
    
    var hole: SKSpriteNode!
    var ball: SKSpriteNode!
    var holeImage: SKSpriteNode!
    
    static func create(initial providedInitial: Session.InitialData?, previousSession: Session?, delegate gameCycleDelegate: GameCycleDelegate, viewAttacher: ViewAttachable) -> PuttScene {

        let initial = providedInitial ?? previousSession?.initial ?? Session.InitialData.random()
        
        let nodePath = Bundle.main.path(forResource: "Hole\(initial.holeNumber)", ofType: "sks")
        
        let data = try! NSData(contentsOfFile: nodePath!, options: NSData.ReadingOptions.mappedIfSafe) as Data
        
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        unarchiver.setClass(self, forClassName: "SKScene")

        let scene = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! PuttScene
        unarchiver.finishDecoding()
        
        scene.opponentsSession = previousSession
        scene.gameCycleDelegate = gameCycleDelegate
        scene.viewAttacher = viewAttacher
        scene.holeNumber = initial.holeNumber
        
        scene.game = Putt(previousSession: previousSession,
                         initial: initial,
                         cycle: SessionCycle(started: scene.started, finished: scene.finished, generateSession: scene.gatherSessionData))
        scene.setupScene()
        return scene
    }
    
    func setupScene() {
        view?.showsPhysics = true
        
        scaleMode = .aspectFill
        
        backgroundColor = UIColor(red: 126, green: 229, blue: 32, alpha: 1)
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
        setupGameNodes()

        setupCamera(centerOn: ball, within: holeImage)
        
        HoleSetup.wallSVGs(forHole: holeNumber).map {
            let path = SVGPathGenerator.newCGPath(fromSVGPath: $0, whileApplying: CGAffineTransform(scaleX: 1, y: -1))!
            
            let wall = SKNode()
            wall.physicsBody = SKPhysicsBody(edgeLoopFrom: path)
            wall.physicsBody!.categoryBitMask = BodyCategory.wall.rawValue
            wall.physicsBody!.collisionBitMask = BodyCategory.ball.rawValue
            wall.physicsBody!.pinned = true
            wall.physicsBody!.restitution = 1.0
            wall.physicsBody!.linearDamping = 0
            wall.physicsBody!.friction = 0
            return wall
        }.forEach(addChild)
    }
    
    func setupGameNodes() {
        hole = childNode(withName: "Hole")! as! SKSpriteNode
        hole.size = CGSize(width: 30, height: 30)
        hole.zPosition = 1
        hole.physicsBody = SKPhysicsBody(circleOfRadius: (hole.frame.width/2)*(4/5.0))
        hole.physicsBody!.categoryBitMask = BodyCategory.hole.rawValue
        hole.physicsBody!.collisionBitMask = BodyCategory.none.rawValue
        
        ball = childNode(withName: "Ball")! as! SKSpriteNode
        ball.size = CGSize(width: 20, height: 20)
        ball.zPosition = 2
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width/2)
        ball.physicsBody!.categoryBitMask = BodyCategory.ball.rawValue
        ball.physicsBody!.collisionBitMask = BodyCategory.wall.rawValue
        ball.physicsBody!.contactTestBitMask = BodyCategory.hole.rawValue
        ball.physicsBody!.mass = 0.25
        ball.physicsBody!.restitution = 1.0
        ball.physicsBody!.linearDamping = 1.0
        ball.physicsBody!.friction = 1.0
        ball.physicsBody!.allowsRotation = false
        
        holeImage = childNode(withName: "HoleImage")! as! SKSpriteNode
    }
    
    public required init(initial: PuttInitialData?, previousSession: PuttSession?, delegate: GameCycleDelegate, viewAttacher: ViewAttachable) {
        fatalError()
    }
    
    func started() {
        gameCycleDelegate.started(game: game)
    }
    
    func setupCamera(centerOn center: SKNode, within limiter: SKNode) {
        let camera = SKCameraNode()
        addChild(camera)
        self.camera = camera
        
        let scaledSize = CGSize(width: size.width * camera.xScale, height: size.height * camera.yScale)
        
        let limiterContentRect = limiter.calculateAccumulatedFrame()
        
        let xInset = min((scaledSize.width / 2) - 100.0, limiterContentRect.width / 2)
        let yInset = min((scaledSize.height / 2) - 100.0, limiterContentRect.height / 2)
        
        let insetContentRect = limiterContentRect.insetBy(dx: xInset, dy: yInset)
        
        let xRange = SKRange(lowerLimit: insetContentRect.minX, upperLimit: insetContentRect.maxX)
        let yRange = SKRange(lowerLimit: insetContentRect.minY, upperLimit: insetContentRect.maxY)
        
        let zeroRange = SKRange(constantValue: 0)
        
        camera.constraints = [
            SKConstraint.distance(zeroRange, to: center),
            SKConstraint.positionX(xRange, y: yRange)
        ]
    }
    
    func finished(currentSession: Session) {
        showScore(game: popper, yourScore: currentSession.instance.score,
                               theirScore: opponentsSession?.instance.score)
        gameCycleDelegate.finished(session: currentSession)
    }
    
    private func showScore(game: GameType, yourScore: Double, theirScore: Double? = nil) {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 3
        
        guard let yourFormattedScore = numberFormatter.string(from: NSNumber(value: yourScore)) else { return }
        let theirFormattedScore = theirScore == nil ? nil : numberFormatter.string(from: NSNumber(value: theirScore!))
        
        scoreView.backgroundColor = .black
        
        viewAttacher.display(view: scoreView)
        
        scoreView.yourScore = yourFormattedScore
        scoreView.theirScore = theirFormattedScore
        scoreView.winner = nil
        if let theirScore = theirScore {
            scoreView.winner = yourScore < theirScore ? .you : .them
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func didMove(to view: SKView) {
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA, bodyB = contact.bodyB
        let bodies = [bodyA, bodyB]
        
        func body(ofCategory category: BodyCategory) -> SKPhysicsBody? {
            return bodies.filter {$0.categoryBitMask==category.rawValue}.first
        }
        
        if let _ = body(ofCategory: .ball), let _ = body(ofCategory: .hole) {
            print("game over")
            let dropInHole = SKAction.move(to: self.hole.position, duration: 0.2)
            self.ball.run(dropInHole)
            self.ball.physicsBody = nil
        }
    }
    
    let arrow = ArrowView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
    var arrowAnchor: CGPoint {
        return ball.position
    }
    func touchDown(atPoint position: CGPoint) {
        arrow.backgroundColor = .clear
        if arrow.superview == nil {
            view?.addSubview(arrow)
        }
    }
    
    func touchMoved(toPoint position: CGPoint) {
        let anchor = view!.convert(arrowAnchor, from: self)
        let location = view!.convert(position, from: self)
        
        let origin = CGPoint(x: anchor.x - location.x, y: anchor.y - location.y)
        var angle = -atan2(origin.y, origin.x) + (.pi / 2)
        angle = angle * (180.0 / .pi)
        angle = angle < 0 ? angle + 360 : angle
            
        arrow.angle = angle
        arrow.scale = anchor.distance(to: location) / 150
        arrow.scale = arrow.scale > 1 ? 1 : arrow.scale
        
        arrow.frame = CGRect(origin: CGPoint(x: anchor.x - 150, y: anchor.y - 150),
                               size: arrow.frame.size)
        arrow.setNeedsDisplay()
    }
    
    func touchUp(atPoint position: CGPoint) {
        let angle = arrow.angle * (.pi / 180.0) + (.pi / 2)
        let power = 200 * arrow.scale
        ball.physicsBody?.applyImpulse(CGVector(dx: cos(angle)*power, dy: sin(angle)*power))
        arrow.removeFromSuperview()
    }
    
    func gatherSessionData() -> Session {
        let yourScore: Double = popper.lifeCycle.elapsedTime
        
        var winner: Team.OneOnOne?
        if let theirScore = opponentsSession?.instance.score {
            winner = yourScore < theirScore ? .you : .them
        }
        
        let instance = Session.InstanceData(score: yourScore, winner: winner)
        let initial = Session.InitialData(holeNumber: popper.initial.holeNumber)
        return Session(instance: instance, initial: initial, ended: winner != nil, messageSession: nil)
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
}
