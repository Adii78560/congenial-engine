//
//  NoteNode.swift
//  GrooveGames
//
//  Ported from NotesControl.cs
//

import UIKit
import SceneKit

/// Represents the timing accuracy states of a 3D rhythm note.
public enum NoteState: String {
    case unReady
    case lowScore
    case midScore
    case highScore
    case missed
}

/// 3D rhythm note that moves along the Z axis toward the scoring plane and camera.
public class NoteNode: SCNNode {
    
    // MARK: - Properties
    
    public private(set) var currentState: NoteState = .unReady
    public private(set) var isHit: Bool = false
    public private(set) var isMissed: Bool = false
    
    public var speed: Float = 2.4 // units per second along +Z
    public var scoringPlaneZ: Float = 4.2
    
    // Bounds thresholds measured as distance to scoring plane (scoringPlaneZ - position.z)
    public var firstBounds: Float = 2.0   // Enter LowScore zone
    public var secondBounds: Float = 1.1  // Enter MidScore zone
    public var thirdBounds: Float = 0.45  // Enter HighScore (Sweet spot) zone
    public var dieBounds: Float = -0.35   // Passed scoring plane -> Missed
    
    // State colors
    public static let unReadyColor = UIColor(red: 0.75, green: 0.8, blue: 0.95, alpha: 0.65)
    public static let lowScoreColor = UIColor(red: 1.0, green: 0.78, blue: 0.15, alpha: 1.0)     // Warm Amber
    public static let midScoreColor = UIColor(red: 0.18, green: 0.75, blue: 1.0, alpha: 1.0)     // Electric Cyan
    public static let highScoreColor = UIColor(red: 0.15, green: 1.0, blue: 0.45, alpha: 1.0)    // Neon Emerald
    public static let missedColor = UIColor(red: 1.0, green: 0.22, blue: 0.28, alpha: 0.8)       // Crimson Red
    
    private var meshNode: SCNNode?
    private var noteMaterial: SCNMaterial?
    private var glowRingNode: SCNNode?
    private var hitBoxNode: SCNNode?
    private var wobbleTime: Float = 0.0
    
    // MARK: - Initialization
    
    public init(template: SCNNode, speed: Float = 2.4, scoringPlaneZ: Float = 4.2) {
        super.init()
        self.name = "NoteNode"
        self.speed = speed
        self.scoringPlaneZ = scoringPlaneZ
        
        setupFromTemplate(template)
        setupHitBox()
        setupGlowRing()
        applyColor(NoteNode.unReadyColor, emission: UIColor.black)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupFromTemplate(_ template: SCNNode) {
        // Clone child nodes from template so each note is an independent instance
        for child in template.childNodes {
            self.addChildNode(child.clone())
        }
        
        // Find the mesh node and clone its geometry & materials so it can be independently colored
        if let foundMesh = self.childNode(withName: "Mesh", recursively: true) {
            self.meshNode = foundMesh
            if let originalGeometry = foundMesh.geometry {
                let uniqueGeometry = originalGeometry.copy() as! SCNGeometry
                if let origMat = uniqueGeometry.firstMaterial {
                    let uniqueMaterial = origMat.copy() as! SCNMaterial
                    uniqueMaterial.isDoubleSided = true
                    uniqueGeometry.materials = [uniqueMaterial]
                    self.noteMaterial = uniqueMaterial
                }
                foundMesh.geometry = uniqueGeometry
            }
        }
    }
    
    private func setupHitBox() {
        // Generous invisible hit volume for effortless, accurate touch detection centered on note
        let sphere = SCNSphere(radius: 0.50)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.clear
        sphere.materials = [mat]
        
        let hitBox = SCNNode(geometry: sphere)
        hitBox.name = "NoteHitBox"
        hitBox.position = SCNVector3(0, 0, 0)
        self.addChildNode(hitBox)
        self.hitBoxNode = hitBox
    }
    
    private func setupGlowRing() {
        // Concentric neon target ring framing the 3D note
        let torus = SCNTorus(ringRadius: 0.35, pipeRadius: 0.02)
        let mat = SCNMaterial()
        mat.diffuse.contents = NoteNode.unReadyColor
        mat.emission.contents = NoteNode.unReadyColor
        mat.lightingModel = .constant
        torus.materials = [mat]
        
        let ring = SCNNode(geometry: torus)
        ring.name = "GlowRing"
        ring.position = SCNVector3(0, 0, 0)
        ring.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        self.addChildNode(ring)
        self.glowRingNode = ring
    }
    
    // MARK: - Update & State Management
    
    /// Updates note position along +Z and refreshes timing state.
    /// Returns the updated state.
    @discardableResult
    public func update(deltaTime: TimeInterval) -> NoteState {
        guard !isHit && !isMissed else { return currentState }
        
        // Advance note forward toward camera along Z
        position.z += speed * Float(deltaTime)
        
        // Gentle rhythmic sway to keep note dynamic while always facing the camera
        wobbleTime += Float(deltaTime)
        eulerAngles.y = sin(wobbleTime * 3.0) * 0.18
        eulerAngles.z = cos(wobbleTime * 2.5) * 0.08
        
        // Calculate distance to scoring plane along Z
        let zDistanceFromPlane = scoringPlaneZ - position.z
        
        let previousState = currentState
        
        if zDistanceFromPlane > firstBounds {
            currentState = .unReady
        } else if zDistanceFromPlane <= firstBounds && zDistanceFromPlane > secondBounds {
            currentState = .lowScore
        } else if zDistanceFromPlane <= secondBounds && zDistanceFromPlane > thirdBounds {
            currentState = .midScore
        } else if zDistanceFromPlane <= thirdBounds && zDistanceFromPlane > dieBounds {
            currentState = .highScore
        } else {
            currentState = .missed
            isMissed = true
        }
        
        if currentState != previousState {
            updateVisualState(state: currentState)
        }
        
        return currentState
    }
    
    private func updateVisualState(state: NoteState) {
        switch state {
        case .unReady:
            applyColor(NoteNode.unReadyColor, emission: UIColor.black)
            glowRingNode?.scale = SCNVector3(1.0, 1.0, 1.0)
            
        case .lowScore:
            applyColor(NoteNode.lowScoreColor, emission: NoteNode.lowScoreColor.withAlphaComponent(0.4))
            pulseGlowRing(color: NoteNode.lowScoreColor, scale: 1.1)
            
        case .midScore:
            applyColor(NoteNode.midScoreColor, emission: NoteNode.midScoreColor.withAlphaComponent(0.6))
            pulseGlowRing(color: NoteNode.midScoreColor, scale: 1.25)
            
        case .highScore:
            applyColor(NoteNode.highScoreColor, emission: NoteNode.highScoreColor)
            pulseGlowRing(color: NoteNode.highScoreColor, scale: 1.45)
            
        case .missed:
            applyColor(NoteNode.missedColor, emission: NoteNode.missedColor)
        }
    }
    
    private func applyColor(_ color: UIColor, emission: UIColor) {
        noteMaterial?.diffuse.contents = color
        noteMaterial?.emission.contents = emission
        if let ringMat = glowRingNode?.geometry?.firstMaterial {
            ringMat.diffuse.contents = color
            ringMat.emission.contents = emission
        }
    }
    
    private func pulseGlowRing(color: UIColor, scale: Float) {
        glowRingNode?.removeAllActions()
        let scaleUp = SCNAction.scale(to: CGFloat(scale), duration: 0.12)
        scaleUp.timingMode = .easeOut
        let scaleBack = SCNAction.scale(to: CGFloat(scale * 0.95), duration: 0.15)
        glowRingNode?.runAction(SCNAction.sequence([scaleUp, scaleBack]))
    }
    
    // MARK: - Hit & Miss Feedback Animations
    
    /// Plays celebratory burst animation when note is tapped successfully.
    public func playHitAnimation(completion: @escaping () -> Void) {
        guard !isHit else { return }
        isHit = true
        
        // Remove hitbox to prevent double hit
        hitBoxNode?.removeFromParentNode()
        
        // Particle flash / burst
        let burstColor: UIColor = (currentState == .highScore) ? NoteNode.highScoreColor :
                                  (currentState == .midScore) ? NoteNode.midScoreColor : NoteNode.lowScoreColor
        applyColor(UIColor.white, emission: burstColor)
        
        let scaleAction = SCNAction.scale(by: 1.45, duration: 0.18)
        scaleAction.timingMode = .easeOut
        let fadeAction = SCNAction.fadeOut(duration: 0.18)
        let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi, z: 0, duration: 0.18)
        let group = SCNAction.group([scaleAction, fadeAction, rotateAction])
        
        self.runAction(group) { [weak self] in
            self?.removeFromParentNode()
            completion()
        }
    }
    
    /// Plays fade-and-sink miss animation when note passes beyond scoring plane.
    public func playMissAnimation(completion: @escaping () -> Void) {
        isMissed = true
        hitBoxNode?.removeFromParentNode()
        
        applyColor(NoteNode.missedColor, emission: NoteNode.missedColor)
        
        let sinkAction = SCNAction.moveBy(x: 0, y: -0.4, z: 0.2, duration: 0.2)
        let fadeAction = SCNAction.fadeOut(duration: 0.2)
        let group = SCNAction.group([sinkAction, fadeAction])
        
        self.runAction(group) { [weak self] in
            self?.removeFromParentNode()
            completion()
        }
    }
}
