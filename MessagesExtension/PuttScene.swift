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

import Cartography
import SVGgh
import SWXMLHash

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
    
    var shotsTaken = 0
    
    var holeLabel: UILabel!
    
    static func create(initial providedInitial: Session.InitialData?, previousSession: Session?, delegate gameCycleDelegate: GameCycleDelegate, viewAttacher: ViewAttachable) -> PuttScene {

        let initial = providedInitial ?? previousSession?.initial ?? Session.InitialData.random()
                
        let nodePath = Bundle.main.path(forResource: "Hole \(initial.holeNumber)", ofType: "sks")
        
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
        
//        scaleMode = .aspectFill
        
        backgroundColor = UIColor(red: 126, green: 229, blue: 32, alpha: 1)
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
        setupGameNodes()

        setupCamera(centerOn: ball, within: holeImage)
        
        setBackground()
        
        HoleSetup.wallSVGs(forHole: holeNumber).map {
            let path = SVGPathGenerator.newCGPath(fromSVGPath: $0, whileApplying: CGAffineTransform(scaleX: 1, y: -1))!
            
            let wall = SKNode()
            wall.physicsBody = SKPhysicsBody(edgeLoopFrom: path)
            wall.physicsBody!.categoryBitMask = BodyCategory.wall.rawValue
            wall.physicsBody!.collisionBitMask = BodyCategory.ball.rawValue
            wall.physicsBody!.pinned = true
            wall.physicsBody!.restitution = 0
            wall.physicsBody!.linearDamping = 0
            wall.physicsBody!.angularDamping = 0
            wall.physicsBody!.friction = 0
            return wall
        }.forEach(addChild)
        
        scaleScene(by: HoleSetup.scale(forHole: holeNumber))
        
//        ball.position = HoleSetup.ballLocation(forHole: holeNumber)
//                            .applying(CGAffineTransform(scaleX: scale, y: scale))
    }
    
    func pinched(gesture: UIPinchGestureRecognizer) {
        scaleScene(by: gesture.scale)
        gesture.scale = 1
    }
    
    func scaleScene(by scale: CGFloat) {
        let scale = SKAction.scale(by: 1/scale, duration: 0)
        camera?.run(scale)
        childNode(withName: "background")?.run(scale)
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
        ball.physicsBody = SKPhysicsBody(circleOfRadius: (ball.size.width/2)*(4/5.0))
        ball.physicsBody!.categoryBitMask = BodyCategory.ball.rawValue
        ball.physicsBody!.collisionBitMask = BodyCategory.wall.rawValue
        ball.physicsBody!.contactTestBitMask = BodyCategory.hole.rawValue
        ball.physicsBody!.mass = 25
        ball.physicsBody!.restitution = 1.0
        ball.physicsBody!.linearDamping = 1.0
        ball.physicsBody!.angularDamping = 0
        ball.physicsBody!.friction = 1.0
        ball.physicsBody!.allowsRotation = false
        
//        let url = Bundle(for: Putt.self).url(forResource: "hole\(holeNumber!)", withExtension: "svg")!
//        let xml = SWXMLHash.parse(try! Data(contentsOf: url))
//        var elements: [XMLIndexer] = []
//        func enumerate(indexer: XMLIndexer) {
//            for child in indexer.children {
//                elements.append(child)
//                enumerate(indexer: child)
//            }
//        }
//        enumerate(indexer: xml)
//        
//        let baller = elements.filter {
//            print($0.element!.name)
//            return $0.element!.name == "circle"
//        }.first!

//        let shape = SKShapeNode(circleOfRadius: CGFloat(baller.element!.attribute(by: "r")!.text.int!))
//        
//        let fillString =  baller.element!.attribute(by: "fill")!.text
//            .replacingOccurrences(of: "rgb(", with: "")
//            .replacingOccurrences(of: ")", with: "")
//        shape.fillColor = UIColor(ciColor: CIColor(string: fillString))
//        
//        let strokeString =  baller.element!.attribute(by: "stroke")!.text
//            .replacingOccurrences(of: "rgb(", with: "")
//            .replacingOccurrences(of: ")", with: "")
//        
//        shape.strokeColor = UIColor(ciColor: CIColor(string: strokeString))
//        shape.lineWidth = CGFloat(baller.element!.attribute(by: "stroke-width")!.text.int!)
//
//        let trans = "translate(-184,214)".range(of: "translate(")

//        shape.position = "translate(-184,214)"
        
//        addChild(shape)
        
//        return wallItems.map {
//            try! $0.value(ofAttribute: "d") as! String
//        }
        
        holeImage = childNode(withName: "HoleImage")! as! SKSpriteNode
    }

    
    public required init(initial: PuttInitialData?, previousSession: PuttSession?, delegate: GameCycleDelegate, viewAttacher: ViewAttachable) {
        fatalError()
    }
        
    func started() {
        updateHoleLabel()
        
        gameCycleDelegate.started(game: game)
        
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(PuttScene.pinched(gesture:)))
        view!.addGestureRecognizer(gesture)
    }
    
    func updateHoleLabel() {
        if holeLabel == nil {
            holeLabel = UILabel()
            view!.addSubview(holeLabel)
            constrain(holeLabel, view!) {
                $0.top == $1.topMargin + 5
                $0.centerX == $1.centerX
            }
        }
        
        holeLabel.text = "Hole \(holeNumber!)   -   Shot \(shotsTaken)"
        holeLabel.sizeToFit()
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
    
    func setBackground() {
        let background = SKSpriteNode(imageNamed: "Background")
        background.name = "background"
        background.size = size
        background.zPosition = -1
        addChild(background)
    }
    
    var blurView: UIVisualEffectView?

    func finished(currentSession: Session) {
        
        if currentSession.ended {
            let currentData = currentSession.gameData
            if currentData.winner == .you {
                ["ConfettiRed", "ConfettiBlue", "ConfettiGreen"].map {
                    let emitter = SKEmitterNode(fileNamed: $0)!
                    emitter.position = CGPoint(x: 0, y: frame.height/2)
                    emitter.particlePositionRange = CGVector(dx: -600, dy: 0)
                    emitter.particleBirthRate = 500
                    return emitter
                }.forEach(addChild)
            }
            
            let scoreView = ScoreView.create()
            
            let blur = UIBlurEffect(style: .dark)
            blurView = UIVisualEffectView(effect: blur)
            blurView!.translatesAutoresizingMaskIntoConstraints = false
            scoreView.addSubview(blurView!)
            scoreView.sendSubview(toBack: blurView!)

            scoreView.yourScore = currentData.shots.reduce(0, +).string!
            scoreView.theirScore = currentData.opponentShots.reduce(0, +).string!
            scoreView.winner = currentData.winner
            viewAttacher.display(view: scoreView)
            constrain(scoreView, viewAttacher.superview) {
                $0.width == $1.width * (5/6.0)
                $0.height == $1.height / 3
            }
            constrain(blurView!, scoreView) {
                $0.leading == $1.leading
                $0.trailing == $1.trailing
                $0.top == $1.top
                $0.bottom == $1.bottom
            }
            DispatchQueue.main.async {
                sleep(2)
                self.gameCycleDelegate.finished(session: currentSession)
            }
        } else {
            DispatchQueue.main.async {
                sleep(1)
                self.gameCycleDelegate.finished(session: currentSession)
            }
        }
        
        
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
            if yourScore < theirScore {
                scoreView.winner = .you
            } else if theirScore < yourScore {
                scoreView.winner = .them
            } else {
                scoreView.winner = nil
            }
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
            ballShotInHole()
        }
    }
    
    func ballShotInHole() {
        let dropInHole = SKAction.move(to: hole.position, duration: 0.2)
        self.ball.run(dropInHole) {
            self.game.finish()
        }
        self.ball.physicsBody = nil
    }
    
    func takeShot() {
        let angle = arrow.angle * (.pi / 180.0) + (.pi / 2)
        let power = 20000 * arrow.scale
        ball.physicsBody?.applyImpulse(CGVector(dx: cos(angle)*power, dy: sin(angle)*power))
        arrow.removeFromSuperview()
        
        shotTaken()
    }
    
    func shotTaken() {
        shotsTaken += 1
        updateHoleLabel()
    }
    
    let arrow = ArrowView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
    var arrowAnchor: CGPoint {
        return ball.position
    }
    var shooting = false
    func touchDown(atPoint position: CGPoint) {
        guard position.distance(to: ball.position) < 50 else { return }
        shooting = true
        
        arrow.backgroundColor = .clear
        if arrow.superview == nil {
            view?.addSubview(arrow)
        }
    }
    
    func touchMoved(toPoint position: CGPoint) {
        guard shooting else { return }
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
        guard shooting else { return }
        takeShot()
        shooting = false
    }
    
    func gatherSessionData() -> Session {
        // localPlayerShots = my opponent's opponent (me)
        var localPlayerShots: [Int] = []
        if let existingShots = opponentsSession?.instance.opponentShots, existingShots.count > 0 {
            localPlayerShots = existingShots
        }
        localPlayerShots += [shotsTaken]
        
        var winner: Team.OneOnOne?
        
        let opponentShots = opponentsSession?.instance.shots
        
        if let opponentShots = opponentsSession?.instance.shots,
                opponentShots.count == 9, localPlayerShots.count == 9 {

            let yourScore = localPlayerShots.reduce(0, +)
            let theirScore = opponentShots.reduce(0, +)
            if yourScore < theirScore {
                winner = .you
            } else if theirScore < yourScore {
                winner = .them
            } else {
                winner = .tie
            }
        }
        
        let instance = Session.InstanceData(shots: localPlayerShots,
                                    opponentShots: opponentsSession?.instance.shots,
                                           winner: winner)

        let localPlayLastHole = localPlayerShots.count
        let opponentLastHole = opponentShots == nil ? nil : opponentShots!.count
        
        let holeNumber = localPlayLastHole == opponentLastHole ? localPlayLastHole + 1 : localPlayLastHole
        
        return Session(instance: instance,
                        initial: Session.InitialData(holeNumber: holeNumber),
                          ended: winner != nil,
                 messageSession: nil)
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
