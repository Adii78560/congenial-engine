//
//  NoteSpawner.swift
//  GrooveGames
//
//  Ported from Spawner.cs
//

import UIKit
import SceneKit

/// Manages oscillating spawner trajectory and note distribution across the 3D scene.
public class NoteSpawner: SCNNode {
    
    // MARK: - Properties
    
    // Spatial path bounds (derived from Spawner.cs parameters)
    public var theX: Float = 1.6
    public var theY: Float = 1.15
    public var theZ: Float = 0.6
    public var theHeight: Float = 0.55
    public var turnDuration: Float = 4.5
    
    public var spawnInterval: TimeInterval = 0.95
    public var isSpawningEnabled: Bool = false {
        didSet {
            self.isHidden = !isSpawningEnabled
        }
    }
    
    public private(set) var activeNotes: [NoteNode] = []
    
    private let noteTemplate: SCNNode
    private let scoringPlaneZ: Float
    public var noteSpeed: Float
    
    private var lerpTime: Float = 0.0
    private var turnTime: Float = 4.5
    private var movingRight: Bool = true
    private var spawnTimer: TimeInterval = 0.0
    
    private var theLeft: SCNVector3 {
        return SCNVector3(-theX, theY, theZ)
    }
    
    private var theRight: SCNVector3 {
        return SCNVector3(theX, theY, theZ)
    }
    
    // Visual emitter node
    private var emitterOrbNode: SCNNode?
    
    // MARK: - Initialization
    
    public init(noteTemplate: SCNNode, scoringPlaneZ: Float = 4.2, noteSpeed: Float = 2.4) {
        self.noteTemplate = noteTemplate
        self.scoringPlaneZ = scoringPlaneZ
        self.noteSpeed = noteSpeed
        super.init()
        self.name = "NoteSpawner"
        
        setupVisualEmitter()
        self.position = theLeft
        self.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisualEmitter() {
        // Futuristic floating portal / spark ring that indicates spawn location
        let sphere = SCNSphere(radius: 0.12)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.8)
        mat.emission.contents = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        mat.lightingModel = .constant
        sphere.materials = [mat]
        
        let orb = SCNNode(geometry: sphere)
        orb.name = "SpawnerOrb"
        self.addChildNode(orb)
        self.emitterOrbNode = orb
        
        // Gentle pulse action on the emitter orb
        let pulseUp = SCNAction.scale(to: 1.25, duration: 0.4)
        let pulseDown = SCNAction.scale(to: 0.85, duration: 0.4)
        orb.runAction(SCNAction.repeatForever(SCNAction.sequence([pulseUp, pulseDown])))
    }
    
    // MARK: - Update
    
    /// Updates spawner sinusoidal trajectory, note movements, and spawns new notes at interval.
    public func update(deltaTime: TimeInterval, onNoteMissed: (NoteNode) -> Void) {
        let dt = Float(deltaTime)
        
        // 1. Oscillate position left and right along sine-wave arch (from Spawner.cs)
        if movingRight {
            lerpTime += dt * (1.0 / turnDuration)
            let clamped = min(max(lerpTime, 0.0), 1.0)
            var curPos = lerp(from: theLeft, to: theRight, t: clamped)
            curPos.y += theHeight * sin(clamped * Float.pi)
            self.position = curPos
            
            if turnTime <= 0 {
                movingRight = false
                lerpTime = 0
                turnTime = turnDuration
            }
        } else {
            lerpTime += dt * (1.0 / turnDuration)
            let clamped = min(max(lerpTime, 0.0), 1.0)
            var curPos = lerp(from: theRight, to: theLeft, t: clamped)
            curPos.y += theHeight * sin(clamped * Float.pi)
            self.position = curPos
            
            if turnTime <= 0 {
                movingRight = true
                lerpTime = 0
                turnTime = turnDuration
            }
        }
        
        if turnTime > 0 {
            turnTime -= dt
        }
        
        // 2. Spawn notes at interval
        if isSpawningEnabled {
            spawnTimer += deltaTime
            if spawnTimer >= spawnInterval {
                spawnTimer = 0
                _ = spawnNote()
            }
        }
        
        // 3. Update all active notes and handle missed ones
        var notesToRemove: [NoteNode] = []
        for note in activeNotes {
            let state = note.update(deltaTime: deltaTime)
            if state == .missed && !notesToRemove.contains(note) {
                notesToRemove.append(note)
                onNoteMissed(note)
                note.playMissAnimation {
                    // Node removes itself from scene on finish
                }
            }
        }
        
        for note in notesToRemove {
            activeNotes.removeAll { $0 === note }
        }
    }
    
    // MARK: - Spawning & Pooling
    
    /// Spawns a NoteNode at the current spawner position and attaches it to the parent scene.
    @discardableResult
    public func spawnNote() -> NoteNode? {
        guard let sceneRoot = self.parent else { return nil }
        
        let note = NoteNode(template: noteTemplate, speed: noteSpeed, scoringPlaneZ: scoringPlaneZ)
        // Position at current spawner position with slight randomized lateral variation for dynamic feel
        let lateralOffset = Float.random(in: -0.15...0.15)
        let heightOffset = Float.random(in: -0.1...0.1)
        note.position = SCNVector3(
            self.position.x + lateralOffset,
            self.position.y + heightOffset,
            self.position.z
        )
        
        sceneRoot.addChildNode(note)
        activeNotes.append(note)
        
        // Spawn pop effect on emitter orb
        emitterOrbNode?.runAction(SCNAction.sequence([
            SCNAction.scale(to: 1.5, duration: 0.08),
            SCNAction.scale(to: 1.0, duration: 0.12)
        ]))
        
        return note
    }
    
    /// Removes a note after hit.
    public func removeNote(_ note: NoteNode) {
        activeNotes.removeAll { $0 === note }
    }
    
    /// Despawns all active notes (ported from destroyAllPrefab).
    public func destroyAllNotes() {
        for note in activeNotes {
            note.removeFromParentNode()
        }
        activeNotes.removeAll()
    }
    
    /// Resets spawner state and timers.
    public func reset() {
        destroyAllNotes()
        lerpTime = 0
        turnTime = turnDuration
        movingRight = true
        spawnTimer = 0
        position = theLeft
    }
    
    // MARK: - Helpers
    
    private func lerp(from: SCNVector3, to: SCNVector3, t: Float) -> SCNVector3 {
        return SCNVector3(
            from.x + (to.x - from.x) * t,
            from.y + (to.y - from.y) * t,
            from.z + (to.z - from.z) * t
        )
    }
}
