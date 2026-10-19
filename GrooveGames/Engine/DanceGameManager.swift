//
//  DanceGameManager.swift
//  GrooveGames
//
//  Ported from DanceGameController.cs & AudioController.cs
//

import UIKit
import SceneKit
import SpriteKit
import AVFoundation

public class DanceGameManager: NSObject, AVAudioPlayerDelegate, GameHUDSceneDelegate {
    
    // MARK: - Singleton / Shared Access
    public static let shared = DanceGameManager()
    
    // MARK: - Dependencies
    public weak var scnView: SCNView?
    public weak var hudScene: GameHUDScene?
    
    // MARK: - SceneKit References
    public private(set) var scene: SCNScene?
    public private(set) var cameraNode: SCNNode?
    public private(set) var stageNode: SCNNode?
    public private(set) var dancerNode: SCNNode?
    public private(set) var spawner: NoteSpawner?
    public private(set) var targetPlaneNode: SCNNode?
    
    // Lighting
    private var leftSpotlight: SCNNode?
    private var rightSpotlight: SCNNode?
    private var centerFloorLight: SCNNode?
    
    // MARK: - Audio
    private let audioQueue = DispatchQueue(label: "com.groovegames.audio", qos: .userInteractive)
    private var musicPlayer: AVAudioPlayer?
    private var currentLoadedSong: String?
    private var sfxPlayers: [String: [AVAudioPlayer]] = [:]
    
    // MARK: - CADisplayLink Game Loop
    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFTimeInterval = 0.0
    public private(set) var isGameRunning: Bool = false
    
    // MARK: - Gameplay State (Ported from DanceGameController.cs)
    public private(set) var score: Int = 0
    public private(set) var hitNotes: Int = 0
    public private(set) var missNotes: Int = 0
    public private(set) var totalNotes: Int = 0
    public private(set) var currentCombo: Int = 0
    public private(set) var maxCombo: Int = 0
    public private(set) var bonusMeter: Float = 0.0 // 0.0 to 1.0 (m_bonusNoteSlider)
    
    public let lowScoreEarned: Int = GameConstants.Scoring.lowScorePoints
    public let midScoreEarned: Int = GameConstants.Scoring.midScorePoints
    public let highScoreEarned: Int = GameConstants.Scoring.highScorePoints
    public let energyFillBonus: Int = GameConstants.Scoring.feverBonusPoints
    
    // Scoring plane position along Z
    public let scoringPlaneZ: Float = GameConstants.Mechanics.scoringPlaneZ
    
    // Dancer groove state
    public enum DanceLevel {
        case standIdle
        case playLame
        case playGood
        case playBetter
        case playBest
        case playWin
        case playLose
    }
    public private(set) var currentDanceLevel: DanceLevel = .playGood
    private var danceBeatTimer: Float = 0.0
    private var lameDurationTimer: Float = 0.0
    
    // Universal humanoid bone references for procedural rhythm animations
    private var hipsNode: SCNNode?
    private var spineNode: SCNNode?
    private var spine1Node: SCNNode?
    private var neckNode: SCNNode?
    private var headNode: SCNNode?
    private var leftArmNode: SCNNode?
    private var leftForeArmNode: SCNNode?
    private var rightArmNode: SCNNode?
    private var rightForeArmNode: SCNNode?
    private var leftUpLegNode: SCNNode?
    private var rightUpLegNode: SCNNode?
    private var leftLegNode: SCNNode?
    private var rightLegNode: SCNNode?
    
    // Skeletal motion clips & animation player cache
    private var armatureNode: SCNNode?
    public private(set) var danceAnimationPlayers: [DanceLevel: SCNAnimationPlayer] = [:]
    private var cachedAnimations: [DanceLevel: SCNAnimation] = [:]
    private var cachedAnimScenes: [SCNScene] = []
    private var currentDancerScene: SCNScene?
    private var currentNoteScene: SCNScene?
    private var currentPlayingPlayer: SCNAnimationPlayer?
    
    public func setupGame(in view: SCNView, hud: GameHUDScene) {
        self.scnView = view
        self.hudScene = hud
        hud.hudDelegate = self
        
        setupAudioSession()
        preloadDanceAnimations()
        preloadAudio()
        build3DScene()
        setupDisplayLink()
    }
    
    // MARK: - Audio Session & Preloading
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[DanceGameManager] Audio session setup error: \(error)")
        }
    }
    
    public func preloadDanceAnimations() {
        guard cachedAnimations.isEmpty else { return }
        let animMap: [(DanceLevel, String)] = [
            (.standIdle, "Anim_Idle"),
            (.playLame, "Anim_Lame"),
            (.playGood, "Anim_Basic"),
            (.playBetter, "Anim_Good"),
            (.playBest, "Anim_Awesome"),
            (.playWin, "Anim_Awesome"),
            (.playLose, "Anim_Lame")
        ]
        
        for (level, fileName) in animMap {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "usdz"),
                  let animScene = try? SCNScene(url: url) else { continue }
            
            self.cachedAnimScenes.append(animScene)
            
            animScene.rootNode.enumerateChildNodes { (node, stop) in
                for key in node.animationKeys {
                    if let player = node.animationPlayer(forKey: key) {
                        let anim = player.animation
                        anim.repeatCount = 100_000
                        anim.blendInDuration = 0.25
                        anim.blendOutDuration = 0.25
                        self.cachedAnimations[level] = anim
                        stop.pointee = true
                        break
                    }
                }
            }
        }
        print("[DanceGameManager] Preloaded \(cachedAnimations.count) dance animations into memory cache.")
    }
    
    public func loadSong(audioFileName: String, autoPlay: Bool = false) {
        if currentLoadedSong == audioFileName, let player = musicPlayer {
            DispatchQueue.main.async {
                if abs(player.volume - PlayerProfile.shared.musicVolume) > 0.01 {
                    player.volume = PlayerProfile.shared.musicVolume
                }
                if autoPlay {
                    player.currentTime = 0
                    player.play()
                } else if player.isPlaying {
                    player.stop()
                    player.currentTime = 0
                }
            }
            return
        }
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard let songURL = Bundle.main.url(forResource: audioFileName, withExtension: "mp3") else {
                print("[DanceGameManager] Could not find \(audioFileName).mp3 in bundle")
                return
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: songURL)
                player.prepareToPlay()
                
                DispatchQueue.main.async {
                    if let old = self.musicPlayer {
                        old.stop()
                        old.delegate = nil
                    }
                    player.volume = PlayerProfile.shared.musicVolume
                    player.delegate = self
                    self.musicPlayer = player
                    self.currentLoadedSong = audioFileName
                    print("[DanceGameManager] Loaded song: \(audioFileName).mp3")
                    
                    if autoPlay {
                        player.currentTime = 0
                        player.play()
                    }
                }
            } catch {
                print("[DanceGameManager] Error loading \(audioFileName).mp3: \(error)")
            }
        }
    }
    
    private func preloadAudio() {
        let currentTrack = PlayerProfile.shared.currentSong.audioFileName
        loadSong(audioFileName: currentTrack, autoPlay: false)
        
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            let sfxFiles = ["GoodNote1", "GoodNote2", "GoodNote3", "GoodNote4", "BadNote"]
            var poolMap: [String: [AVAudioPlayer]] = [:]
            let defaultSFXVol = PlayerProfile.shared.sfxVolume
            for name in sfxFiles {
                if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
                    var pool: [AVAudioPlayer] = []
                    for _ in 0..<2 { // 2 voices per SFX is lightweight and eliminates audio queue exhaustion
                        if let player = try? AVAudioPlayer(contentsOf: url) {
                            player.volume = defaultSFXVol
                            player.prepareToPlay()
                            pool.append(player)
                        }
                    }
                    poolMap[name] = pool
                } else {
                    print("[DanceGameManager] Could not find \(name).wav in bundle")
                }
            }
            
            DispatchQueue.main.async {
                self.sfxPlayers = poolMap
            }
        }
    }
    
    public func playSFX(_ name: String) {
        let vol = PlayerProfile.shared.sfxVolume
        guard vol > 0.01 else { return }
        guard let pool = sfxPlayers[name] else { return }
        for player in pool {
            if !player.isPlaying {
                if abs(player.volume - vol) > 0.01 { player.volume = vol }
                player.currentTime = 0
                player.play()
                return
            }
        }
        // If all busy, use first
        if let first = pool.first {
            if abs(first.volume - vol) > 0.01 { first.volume = vol }
            first.currentTime = 0
            first.play()
        }
    }
    
    public func applyAudioSettings() {
        musicPlayer?.volume = PlayerProfile.shared.musicVolume
        let sfxVol = PlayerProfile.shared.sfxVolume
        for (_, pool) in sfxPlayers {
            for p in pool {
                p.volume = sfxVol
            }
        }
    }
    
    // MARK: - 3D Scene Architecture & Dancer Setup
    
    private func build3DScene() {
        let gameScene = SCNScene()
        self.scene = gameScene
        scnView?.scene = gameScene
        
        // Dark club atmospheric background
        gameScene.background.contents = UIColor(red: 0.05, green: 0.04, blue: 0.08, alpha: 1.0)
        
        setupCamera(in: gameScene)
        buildDanceStage(in: gameScene)
        loadAndPlaceDancer(in: gameScene)
        buildTargetScoringZone(in: gameScene)
        setupSpawner(in: gameScene)
        setupEnvironmentLighting(in: gameScene)
    }
    
    private func setupCamera(in scene: SCNScene) {
        let camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 100.0
        camera.fieldOfView = 50.0 // Framed for widescreen landscape display
        
        let camNode = SCNNode()
        camNode.camera = camera
        camNode.name = "MainCamera"
        // In landscape: Position camera at Z=5.3, Y=1.35, looking at (0, 0.95, 0)
        // This ensures the entire dancer (0m to 1.8m) plus dance stage floor is fully visible!
        camNode.position = SCNVector3(0, 1.35, 5.3)
        camNode.look(at: SCNVector3(0, 0.95, 0))
        
        scene.rootNode.addChildNode(camNode)
        scnView?.pointOfView = camNode
        self.cameraNode = camNode
    }
    
    private func buildDanceStage(in scene: SCNScene) {
        let stage = SCNNode()
        stage.name = "DanceStage"
        
        // Main circular elevated dance floor
        let cylinder = SCNCylinder(radius: 2.8, height: 0.25)
        let floorMat = SCNMaterial()
        floorMat.diffuse.contents = UIColor(red: 0.12, green: 0.1, blue: 0.18, alpha: 1.0)
        floorMat.roughness.contents = 0.2
        floorMat.metalness.contents = 0.8
        cylinder.materials = [floorMat]
        
        let floorNode = SCNNode(geometry: cylinder)
        floorNode.position = SCNVector3(0, -0.125, 0)
        stage.addChildNode(floorNode)
        
        // Outer glowing neon rim
        let rimTorus = SCNTorus(ringRadius: 2.82, pipeRadius: 0.05)
        let rimMat = SCNMaterial()
        rimMat.diffuse.contents = UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
        rimMat.emission.contents = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        rimMat.lightingModel = .constant
        rimTorus.materials = [rimMat]
        
        let rimNode = SCNNode(geometry: rimTorus)
        rimNode.position = SCNVector3(0, 0, 0)
        stage.addChildNode(rimNode)
        
        // Inner concentric dance grid rings
        let innerRingTorus = SCNTorus(ringRadius: 1.5, pipeRadius: 0.02)
        let innerMat = SCNMaterial()
        innerMat.diffuse.contents = UIColor(red: 1.0, green: 0.2, blue: 0.8, alpha: 0.8)
        innerMat.emission.contents = UIColor(red: 1.0, green: 0.2, blue: 0.8, alpha: 0.8)
        innerMat.lightingModel = .constant
        innerRingTorus.materials = [innerMat]
        
        let innerRingNode = SCNNode(geometry: innerRingTorus)
        innerRingNode.position = SCNVector3(0, 0.005, 0)
        stage.addChildNode(innerRingNode)
        
        scene.rootNode.addChildNode(stage)
        self.stageNode = stage
    }
    
    private func cacheHumanoidBones(in root: SCNNode) {
        func findBone(named name: String) -> SCNNode? {
            let candidates = [
                name,
                "mixamorig_\(name)",
                "Character1_\(name)",
                "Hispanic_\(name)"
            ]
            for c in candidates {
                if let found = root.childNode(withName: c, recursively: true) {
                    return found
                }
            }
            return nil
        }
        
        self.hipsNode = findBone(named: "Hips")
        self.spineNode = findBone(named: "Spine")
        self.spine1Node = findBone(named: "Spine1")
        self.neckNode = findBone(named: "Neck")
        self.headNode = findBone(named: "Head")
        self.leftArmNode = findBone(named: "LeftArm")
        self.leftForeArmNode = findBone(named: "LeftForeArm")
        self.rightArmNode = findBone(named: "RightArm")
        self.rightForeArmNode = findBone(named: "RightForeArm")
        self.leftUpLegNode = findBone(named: "LeftUpLeg")
        self.rightUpLegNode = findBone(named: "RightUpLeg")
        self.leftLegNode = findBone(named: "LeftLeg")
        self.rightLegNode = findBone(named: "RightLeg")
    }
    
    public enum RigBoneAlignment {
        case mixamoY  // Dancer, Firefighter, SilverFace: bones extend along +Y, animated via Anim_*.usdz
        case blenderX // Alexis, Mia, ChickenMan: bones extend along +X, animated via procedural choreography
    }
    public private(set) var currentRigAlignment: RigBoneAlignment = .mixamoY
    
    public func normalizeCharacterMaterials(in node: SCNNode) {
        node.enumerateHierarchy { (child, _) in
            guard let geometry = child.geometry else { return }
            for material in geometry.materials {
                // 1. Clear blown-out self-illumination (fixes milky white Alexis & Mia)
                material.emission.contents = UIColor.black
                
                // 2. Remove flat constant color normal maps (fixes surface distortion on Alexis & Mia)
                if material.normal.contents is UIColor {
                    material.normal.contents = nil
                }
                
                // 3. Fix transparent slot incorrectly using diffuse texture (prevents holes & see-through clothes)
                material.transparent.contents = 1.0
                material.transparency = 1.0
                material.transparencyMode = .default
                
                // 4. Ensure double-sided geometry rendering
                material.isDoubleSided = true
                material.cullMode = .back
                
                // 5. Enhance lighting & specular highlights for vibrant clothes & fabric
                material.lightingModel = .phong
                material.specular.contents = UIColor(white: 0.18, alpha: 1.0)
                material.shininess = 0.25
            }
        }
    }
    
    public func loadAndPlaceDancer(character: CharacterData? = nil, in targetScene: SCNScene? = nil) {
        let charData = character ?? PlayerProfile.shared.currentCharacter
        let activeScene = targetScene ?? self.scene
        dancerNode?.removeFromParentNode()
        
        guard let url = Bundle.main.url(forResource: charData.modelFileName, withExtension: "usdz") else {
            print("[DanceGameManager] Model \(charData.modelFileName).usdz not found in bundle!")
            return
        }
        
        do {
            let dancerScene = try SCNScene(url: url, options: nil)
            self.currentDancerScene = dancerScene
            let wrapper = SCNNode()
            wrapper.name = "DancerWrapper_\(charData.id)"
            for child in dancerScene.rootNode.childNodes {
                wrapper.addChildNode(child)
            }
            wrapper.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            
            // Center model origin if needed
            if charData.id == "firefighter" {
                wrapper.position = SCNVector3(-0.95, 0, 0)
            } else {
                wrapper.position = SCNVector3(0, 0, 0)
            }
            
            activeScene?.rootNode.addChildNode(wrapper)
            self.dancerNode = wrapper
            
            // Normalize all materials to display rich clothes, textures, and shading
            normalizeCharacterMaterials(in: wrapper)
            
            // Determine rig bone alignment based on model character id
            if ["alexis", "mia", "chickenman"].contains(charData.id.lowercased()) {
                self.currentRigAlignment = .blenderX
            } else {
                self.currentRigAlignment = .mixamoY
            }
            
            // Universal bone discovery across Mixamo, Character1, and Hispanic rigs
            cacheHumanoidBones(in: wrapper)
            
            if currentRigAlignment == .mixamoY {
                setupSkeletalDanceAnimations(in: wrapper)
            } else {
                danceAnimationPlayers.removeAll()
                currentPlayingPlayer = nil
            }
            
            print("[DanceGameManager] Character '\(charData.name)' (\(charData.modelFileName).usdz, rig: \(currentRigAlignment)) loaded and placed on stage!")
        } catch {
            print("[DanceGameManager] Error loading \(charData.modelFileName).usdz: \(error)")
        }
    }
    
    private func findAnimationTargetArmature(in wrapper: SCNNode) -> SCNNode {
        // 1. Target the immediate parent of mixamorig_Hips (the true skeleton root)
        if let hips = wrapper.childNode(withName: "mixamorig_Hips", recursively: true),
           let parent = hips.parent {
            return parent
        }
        // 2. If nested Armatures exist, target the inner one
        if let outer = wrapper.childNode(withName: "Armature", recursively: true) {
            if let inner = outer.childNode(withName: "Armature", recursively: false) {
                return inner
            }
            return outer
        }
        // 3. Fallbacks for other rig conventions
        if let ref = wrapper.childNode(withName: "Character1_Reference", recursively: true) {
            if let inner = ref.childNode(withName: "Character1_Reference", recursively: false) {
                return inner
            }
            return ref
        }
        return wrapper
    }
    
    private func setupSkeletalDanceAnimations(in wrapper: SCNNode) {
        danceAnimationPlayers.removeAll()
        currentPlayingPlayer = nil
        
        let targetArmature = findAnimationTargetArmature(in: wrapper)
        self.armatureNode = targetArmature
        
        if cachedAnimations.isEmpty {
            preloadDanceAnimations()
        }
        
        for (level, anim) in cachedAnimations {
            let animCopy = (anim.copy() as? SCNAnimation) ?? anim
            animCopy.repeatCount = 100_000
            animCopy.blendInDuration = 0.25
            animCopy.blendOutDuration = 0.25
            let player = SCNAnimationPlayer(animation: animCopy)
            targetArmature.addAnimationPlayer(player, forKey: "danceMove_\(level)")
            self.danceAnimationPlayers[level] = player
        }
        
        playDanceAnimation(level: currentDanceLevel)
    }
    
    public func playDanceAnimation(level: DanceLevel) {
        if currentRigAlignment == .mixamoY {
            if let player = danceAnimationPlayers[level] {
                if currentPlayingPlayer !== player {
                    currentPlayingPlayer?.stop(withBlendOutDuration: 0.2)
                    currentPlayingPlayer = player
                    player.play()
                }
            }
        }
    }
    
    public func switchCharacter(to index: Int) {
        PlayerProfile.shared.selectCharacter(at: index)
        loadAndPlaceDancer(character: PlayerProfile.shared.currentCharacter)
    }
    
    private func buildTargetScoringZone(in scene: SCNScene) {
        // Reference target scoring zone where player should tap notes
        let targetZone = SCNNode()
        targetZone.name = "TargetScoringZone"
        targetZone.position = SCNVector3(0, 1.25, scoringPlaneZ)
        
        scene.rootNode.addChildNode(targetZone)
        self.targetPlaneNode = targetZone
    }
    
    private func setupSpawner(in scene: SCNScene) {
        guard let noteURL = Bundle.main.url(forResource: "Note", withExtension: "usdz") else {
            print("[DanceGameManager] Note.usdz not found in bundle!")
            return
        }
        
        do {
            let noteScene = try SCNScene(url: noteURL, options: nil)
            self.currentNoteScene = noteScene
            
            // Build note template (baked static upright mesh)
            let templateWrapper = SCNNode()
            for child in noteScene.rootNode.childNodes {
                templateWrapper.addChildNode(child)
            }
            
            let spawnerInstance = NoteSpawner(
                noteTemplate: templateWrapper,
                scoringPlaneZ: scoringPlaneZ,
                noteSpeed: 2.4
            )
            spawnerInstance.isHidden = true
            spawnerInstance.isSpawningEnabled = false
            scene.rootNode.addChildNode(spawnerInstance)
            self.spawner = spawnerInstance
            print("[DanceGameManager] NoteSpawner successfully initialized!")
        } catch {
            print("[DanceGameManager] Error loading Note.usdz: \(error)")
        }
    }
    
    private func setupEnvironmentLighting(in scene: SCNScene) {
        // Ambient fill
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(red: 0.22, green: 0.18, blue: 0.32, alpha: 1.0)
        ambientLight.intensity = 800
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // Directional key light with shadows
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.color = UIColor(white: 1.0, alpha: 1.0)
        keyLight.intensity = 1000
        keyLight.castsShadow = true
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(2.0, 5.0, 4.0)
        keyNode.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 6, 0)
        scene.rootNode.addChildNode(keyNode)
        
        // Club spotlights for dynamic party lighting
        let leftLight = SCNLight()
        leftLight.type = .spot
        leftLight.color = UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0) // Neon Cyan
        leftLight.intensity = 1500
        leftLight.spotInnerAngle = 35
        leftLight.spotOuterAngle = 60
        let leftLightNode = SCNNode()
        leftLightNode.light = leftLight
        leftLightNode.position = SCNVector3(-3.5, 4.0, 1.5)
        leftLightNode.look(at: SCNVector3(0, 1.0, 0))
        scene.rootNode.addChildNode(leftLightNode)
        self.leftSpotlight = leftLightNode
        
        let rightLight = SCNLight()
        rightLight.type = .spot
        rightLight.color = UIColor(red: 1.0, green: 0.15, blue: 0.85, alpha: 1.0) // Hot Magenta
        rightLight.intensity = 1500
        rightLight.spotInnerAngle = 35
        rightLight.spotOuterAngle = 60
        let rightLightNode = SCNNode()
        rightLightNode.light = rightLight
        rightLightNode.position = SCNVector3(3.5, 4.0, 1.5)
        rightLightNode.look(at: SCNVector3(0, 1.0, 0))
        scene.rootNode.addChildNode(rightLightNode)
        self.rightSpotlight = rightLightNode
    }
    
    // MARK: - Game Loop & CADisplayLink
    
    private func setupDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(gameLoopTick(_:)))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 60)
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func gameLoopTick(_ link: CADisplayLink) {
        let currentTime = link.timestamp
        if lastFrameTime == 0.0 {
            lastFrameTime = currentTime
            return
        }
        let deltaTime = min(currentTime - lastFrameTime, 0.1) // Clamp to avoid huge delta jumps
        lastFrameTime = currentTime
        
        // 1. Always animate dancer procedural groove and club lights (keeps stage dynamic in menus!)
        updateDancerGroove(deltaTime: deltaTime)
        updateLightingPulse(deltaTime: deltaTime)
        
        // 2. Gameplay active checks
        guard isGameRunning else { return }
        
        // 3. Update Spawner and active notes
        spawner?.update(deltaTime: deltaTime) { [weak self] missedNote in
            self?.noteWasMissed(missedNote)
        }
        
        // 4. Update song progress in HUD
        if let player = musicPlayer, player.duration > 0 {
            let progress = CGFloat(player.currentTime / player.duration)
            hudScene?.updateSongProgress(percentage: progress)
        }
    }
    
    // MARK: - Dancer Multi-Tier Motion Choreography Engine
    
    public func updateDancerGroove(deltaTime: TimeInterval) {
        guard dancerNode != nil else { return }
        let dt = Float(deltaTime)
        
        // 124 BPM rhythm (~0.484 seconds per beat)
        let beatFrequency: Float = 2.06 // beats per second
        danceBeatTimer += dt * beatFrequency * Float.pi * 2.0
        
        // Handle recover timer for lame miss reaction
        if currentDanceLevel == .playLame {
            lameDurationTimer -= dt
            if lameDurationTimer <= 0 {
                updateDanceMove()
            }
        }
        
        if currentRigAlignment == .mixamoY {
            // MARK: Mixamo Y-Rig (Dancer, Firefighter, SilverFace)
            // Driven by SCNAnimationPlayer from Anim_*.usdz.
            // Only apply root stage dynamics so we never clobber skeletal bone curves.
            switch currentDanceLevel {
            case .standIdle:
                let breathing = sin(danceBeatTimer * 0.5) * 0.015
                dancerNode?.position.y = max(0, breathing)
                dancerNode?.position.z = 0.0
                dancerNode?.eulerAngles.y = 0.0
                
            case .playLame:
                let stumbleZ = -abs(sin(danceBeatTimer)) * 0.06
                dancerNode?.position.z = stumbleZ
                dancerNode?.position.y = 0.0
                
            case .playGood:
                dancerNode?.position.z = 0.0
                dancerNode?.eulerAngles.y = 0.0
                
            case .playBetter:
                dancerNode?.position.z = 0.0
                dancerNode?.eulerAngles.y = 0.0
                
            case .playBest:
                dancerNode?.position.z = 0.0
                let spinPhase = fmod(danceBeatTimer / (Float.pi * 2.0), 8.0)
                if spinPhase > 7.0 {
                    let spinProgress = (spinPhase - 7.0)
                    dancerNode?.eulerAngles.y = spinProgress * Float.pi * 2.0
                } else {
                    dancerNode?.eulerAngles.y = 0.0
                }
                
            case .playWin:
                let winBounce = abs(sin(danceBeatTimer * 2.0)) * 0.05
                dancerNode?.position.y = winBounce
                dancerNode?.position.z = 0.0
                dancerNode?.eulerAngles.y = 0.0
                
            case .playLose:
                dancerNode?.position.y = 0.0
                dancerNode?.position.z = 0.0
                dancerNode?.eulerAngles.y = 0.0
            }
        } else {
            // MARK: Blender X-Rig (Alexis, Mia, ChickenMan)
            // Driven by procedural multi-tier choreography engine calibrated to X-aligned bones.
            switch currentDanceLevel {
            case .standIdle:
                // 1. STAND IDLE: Natural breathing, subtle hip sway, arms relaxed at sides
                let breathing = sin(danceBeatTimer * 0.5) * 0.02
                let hipSway = sin(danceBeatTimer * 0.25) * 0.025
                dancerNode?.position.x = hipSway
                dancerNode?.position.y = max(0, breathing)
                dancerNode?.position.z = 0.0
                dancerNode?.eulerAngles.y = sin(danceBeatTimer * 0.25) * 0.04
                
                spineNode?.eulerAngles.z = -hipSway * 0.6
                headNode?.eulerAngles.x = abs(sin(danceBeatTimer * 0.5)) * 0.06
                headNode?.eulerAngles.y = sin(danceBeatTimer * 0.25) * 0.05
                
                // Natural relaxed arms at sides (~72° down from T-pose in X-coordinates)
                leftArmNode?.eulerAngles = SCNVector3(0.08, 0.2, -1.25)
                rightArmNode?.eulerAngles = SCNVector3(0.08, -0.2, 1.25)
                leftForeArmNode?.eulerAngles = SCNVector3Zero
                rightForeArmNode?.eulerAngles = SCNVector3Zero
                
            case .playLame:
                // 2. PLAY LAME: Stumble backward on miss, embarrassed head shake and flails
                let stumbleZ = -abs(sin(danceBeatTimer)) * 0.07
                dancerNode?.position.z = stumbleZ
                dancerNode?.position.y = 0.0
                dancerNode?.position.x = sin(danceBeatTimer * 2.0) * 0.03
                
                spineNode?.eulerAngles.x = -0.12
                spineNode?.eulerAngles.z = sin(danceBeatTimer) * 0.12
                headNode?.eulerAngles.x = 0.25 // head hangs down
                headNode?.eulerAngles.y = sin(danceBeatTimer * 3.5) * 0.28 // vigorous shake
                
                // Asymmetric awkward arm flails
                leftArmNode?.eulerAngles = SCNVector3(-0.45, 0.3, -0.65)
                rightArmNode?.eulerAngles = SCNVector3(0.55, -0.3, 0.55)
                
            case .playGood:
                // 3. PLAY GOOD (Basic): Upbeat 2-step side-to-side groove with alternating arm sways
                let hipSway = sin(danceBeatTimer * 0.5) * 0.06
                let bounce = abs(sin(danceBeatTimer)) * 0.038
                dancerNode?.position.x = hipSway
                dancerNode?.position.y = bounce
                dancerNode?.position.z = 0.0
                dancerNode?.eulerAngles.y = sin(danceBeatTimer * 0.5) * 0.1
                
                spineNode?.eulerAngles.z = -hipSway * 0.8
                spineNode?.eulerAngles.x = abs(sin(danceBeatTimer)) * 0.05
                headNode?.eulerAngles.x = abs(sin(danceBeatTimer)) * 0.12
                headNode?.eulerAngles.y = 0.0
                
                // Alternating rhythmic arm swings across chest
                leftArmNode?.eulerAngles.z = -1.25 + sin(danceBeatTimer) * 0.35
                rightArmNode?.eulerAngles.z = 1.25 - sin(danceBeatTimer) * 0.35
                leftArmNode?.eulerAngles.y = 0.2 + cos(danceBeatTimer) * 0.25
                rightArmNode?.eulerAngles.y = -0.2 - cos(danceBeatTimer) * 0.25
                leftForeArmNode?.eulerAngles.z = max(0, -sin(danceBeatTimer)) * 0.3
                rightForeArmNode?.eulerAngles.z = max(0, sin(danceBeatTimer)) * 0.3
                
            case .playBetter:
                // 4. PLAY BETTER (Combo 6+): High-energy pop & lock, alternating high arm pumps
                let hipSway = sin(danceBeatTimer) * 0.075
                let bounce = abs(sin(danceBeatTimer * 2.0)) * 0.055
                dancerNode?.position.x = hipSway
                dancerNode?.position.y = bounce
                dancerNode?.position.z = 0.0
                dancerNode?.eulerAngles.y = sin(danceBeatTimer * 0.5) * 0.15
                
                // Body rolls and waves
                spineNode?.eulerAngles.x = sin(danceBeatTimer) * 0.09
                spineNode?.eulerAngles.z = -sin(danceBeatTimer) * 0.14
                headNode?.eulerAngles.x = sin(danceBeatTimer * 2.0) * 0.16
                headNode?.eulerAngles.y = sin(danceBeatTimer) * 0.1
                
                // Alternating high arm pumps into the air
                leftArmNode?.eulerAngles.z = -0.9 + max(-0.25, sin(danceBeatTimer) * 0.75)
                rightArmNode?.eulerAngles.z = 0.9 - max(-0.25, -sin(danceBeatTimer) * 0.75)
                leftArmNode?.eulerAngles.y = 0.3 + sin(danceBeatTimer) * 0.3
                rightArmNode?.eulerAngles.y = -0.3 - sin(danceBeatTimer) * 0.3
                leftForeArmNode?.eulerAngles.z = 0.45
                rightForeArmNode?.eulerAngles.z = 0.45
                
                // Knee groove dips
                leftUpLegNode?.eulerAngles.x = max(0, sin(danceBeatTimer)) * 0.12
                rightUpLegNode?.eulerAngles.x = max(0, -sin(danceBeatTimer)) * 0.12
                
            case .playBest:
                // 5. PLAY BEST (Combo 12+ / Fever): Hyper-fever breakdance with dynamic spins
                let bounce = abs(sin(danceBeatTimer * 2.0)) * 0.075
                dancerNode?.position.y = bounce
                dancerNode?.position.x = sin(danceBeatTimer * 2.0) * 0.06
                dancerNode?.position.z = 0.0
                
                // Dynamic spin rotation every 8 beats
                let spinPhase = fmod(danceBeatTimer / (Float.pi * 2.0), 8.0)
                if spinPhase > 7.0 {
                    let spinProgress = (spinPhase - 7.0)
                    dancerNode?.eulerAngles.y = spinProgress * Float.pi * 2.0
                } else {
                    dancerNode?.eulerAngles.y = sin(danceBeatTimer) * 0.22
                }
                
                // Chest popping and syncopated spine flexing
                spineNode?.eulerAngles.x = abs(sin(danceBeatTimer * 2.0)) * 0.14
                spineNode?.eulerAngles.z = sin(danceBeatTimer * 2.0) * 0.12
                headNode?.eulerAngles.x = sin(danceBeatTimer * 2.0) * 0.22
                
                // Rapid double-arm power gestures
                leftArmNode?.eulerAngles.z = -1.0 + abs(sin(danceBeatTimer)) * 0.5
                rightArmNode?.eulerAngles.z = 1.0 - abs(sin(danceBeatTimer)) * 0.5
                leftArmNode?.eulerAngles.y = sin(danceBeatTimer * 2.0) * 0.4
                rightArmNode?.eulerAngles.y = -sin(danceBeatTimer * 2.0) * 0.4
                leftForeArmNode?.eulerAngles.z = 0.6
                rightForeArmNode?.eulerAngles.z = 0.6
                
            case .playWin:
                // 6. PLAY WIN: Victory celebration! Joyful jumping, arms raised high waving!
                let winBounce = abs(sin(danceBeatTimer * 2.0)) * 0.08
                dancerNode?.position.y = winBounce
                dancerNode?.position.x = sin(danceBeatTimer * 0.5) * 0.03
                dancerNode?.eulerAngles.y = sin(danceBeatTimer * 0.5) * 0.1
                
                spineNode?.eulerAngles.x = -0.08
                headNode?.eulerAngles.x = -0.15
                headNode?.eulerAngles.y = sin(danceBeatTimer) * 0.1
                
                // Victory waving arms
                leftArmNode?.eulerAngles.z = -0.3 + sin(danceBeatTimer * 2.0) * 0.2
                rightArmNode?.eulerAngles.z = 0.3 - sin(danceBeatTimer * 2.0) * 0.2
                leftArmNode?.eulerAngles.y = 0.5
                rightArmNode?.eulerAngles.y = -0.5
                
            case .playLose:
                // 7. PLAY LOSE: Slumped forward defeat, slow sad head shake
                dancerNode?.position.y = 0.0
                dancerNode?.position.x = 0.0
                dancerNode?.position.z = 0.0
                dancerNode?.eulerAngles.y = 0.0
                
                spineNode?.eulerAngles.x = 0.22
                headNode?.eulerAngles.x = 0.35
                headNode?.eulerAngles.y = sin(danceBeatTimer * 0.5) * 0.15
                
                leftArmNode?.eulerAngles = SCNVector3(0.12, 0.1, -1.35)
                rightArmNode?.eulerAngles = SCNVector3(0.12, -0.1, 1.35)
                leftForeArmNode?.eulerAngles = SCNVector3Zero
                rightForeArmNode?.eulerAngles = SCNVector3Zero
            }
        }
    }
    
    private func updateLightingPulse(deltaTime: TimeInterval) {
        let pulse = (sin(danceBeatTimer * 2.0) + 1.0) * 0.5
        let baseIntensity: CGFloat = 1200
        let maxAdd: CGFloat = 800
        let current = baseIntensity + maxAdd * CGFloat(pulse)
        leftSpotlight?.light?.intensity = current
        rightSpotlight?.light?.intensity = current
    }
    
    // MARK: - Game Lifecycle
    
    public func startGame() {
        resetStats()
        isGameRunning = true
        lastFrameTime = 0.0
        
        self.musicPlayer?.currentTime = 0
        self.musicPlayer?.play()
        
        hudScene?.hideGameOver()
        hudScene?.updateScore(0)
        hudScene?.updateCombo(0)
        hudScene?.updateCounters(hits: 0, misses: 0)
        hudScene?.updateEnergyMeter(percentage: 0.0)
        
        spawner?.reset()
        spawner?.isHidden = false
        spawner?.isSpawningEnabled = true
        
        currentDanceLevel = .playGood
        playDanceAnimation(level: .playGood)
    }
    
    public func pauseGame() {
        isGameRunning = false
        self.musicPlayer?.pause()
        spawner?.isSpawningEnabled = false
    }
    
    public func resumeGame() {
        isGameRunning = true
        lastFrameTime = 0.0
        self.musicPlayer?.play()
        spawner?.isSpawningEnabled = true
    }
    
    public func restartGame() {
        spawner?.destroyAllNotes()
        startGame()
    }
    
    public func endGame(isWon: Bool) {
        isGameRunning = false
        self.musicPlayer?.stop()
        spawner?.destroyAllNotes()
        spawner?.isSpawningEnabled = false
        spawner?.isHidden = true
        
        currentDanceLevel = isWon ? .playWin : .playLose
        playDanceAnimation(level: currentDanceLevel)
        hudScene?.showGameOver(
            score: score,
            hits: hitNotes,
            misses: missNotes,
            maxCombo: maxCombo,
            isWon: isWon
        )
    }
    
    private func resetStats() {
        score = 0
        hitNotes = 0
        missNotes = 0
        totalNotes = 0
        currentCombo = 0
        maxCombo = 0
        bonusMeter = 0.0
    }
    
    // MARK: - Scoring Logic (Ported from DanceGameController.cs)
    
    /// Called when player taps a NoteNode.
    public func onNoteTapped(_ note: NoteNode, tapLocation: CGPoint? = nil) {
        guard isGameRunning && !note.isHit && !note.isMissed else { return }
        
        let state = note.currentState
        
        // If note is still unready (too far away), penalize as early tap / miss
        if state == .unReady {
            noteWasMissed(note, tapLocation: tapLocation)
            return
        }
        
        hitNotes += 1
        totalNotes += 1
        currentCombo += 1
        if currentCombo > maxCombo {
            maxCombo = currentCombo
        }
        
        var scoreEarned: Int = 0
        var bonusEarned: Float = 0.0
        var sfxName: String = GameConstants.Audio.sfxGood1
        var judgmentText: String = GameConstants.Judgments.good
        var judgmentColor: UIColor = GameConstants.Palette.lowScoreColor
        
        switch state {
        case .lowScore:
            scoreEarned = lowScoreEarned // 10
            bonusEarned = GameConstants.Scoring.lowScoreBonusEnergy
            sfxName = GameConstants.Audio.sfxGood1
            judgmentText = GameConstants.Judgments.good
            judgmentColor = GameConstants.Palette.lowScoreColor
            
        case .midScore:
            scoreEarned = midScoreEarned // 25
            bonusEarned = GameConstants.Scoring.midScoreBonusEnergy
            sfxName = GameConstants.Audio.sfxGood2
            judgmentText = GameConstants.Judgments.great
            judgmentColor = GameConstants.Palette.midScoreColor
            
        case .highScore:
            scoreEarned = highScoreEarned // 50
            bonusEarned = GameConstants.Scoring.highScoreBonusEnergy
            // If in high fever/combo, play GoodNote4 for extra sonic punch
            sfxName = (currentCombo >= 15) ? GameConstants.Audio.sfxGood4 : GameConstants.Audio.sfxGood3
            judgmentText = GameConstants.Judgments.perfect
            judgmentColor = GameConstants.Palette.highScoreColor
            
        case .unReady, .missed:
            break
        }
        
        // Audio SFX & Haptics
        playSFX(sfxName)
        if PlayerProfile.shared.isHapticsEnabled {
            DispatchQueue.main.async {
                let generator = UIImpactFeedbackGenerator(style: (state == .highScore) ? .heavy : .medium)
                generator.impactOccurred()
            }
        }
        
        // Update score & energy
        updatePlayerScore(amount: scoreEarned)
        updateBonusMeter(amount: bonusEarned)
        updateDanceMove()
        
        // HUD Visual updates
        hudScene?.updateScore(score)
        hudScene?.updateCombo(currentCombo)
        hudScene?.updateCounters(hits: hitNotes, misses: missNotes)
        hudScene?.showJudgment(text: judgmentText, scoreEarned: scoreEarned, color: judgmentColor, at: tapLocation)
        
        // Play note burst animation and remove from spawner list
        spawner?.removeNote(note)
        note.playHitAnimation {
            // Note removed itself
        }
    }
    
    /// Called when player taps the screen without hitting a note directly.
    /// Checks if any note is currently in the hit window for forgiving rhythmic tapping!
    public func onScreenTapped(at location: CGPoint) {
        guard isGameRunning else { return }
        
        // Find closest active note within scoring bounds
        var bestNote: NoteNode?
        var minDistance: Float = Float.greatestFiniteMagnitude
        
        if let active = spawner?.activeNotes {
            for note in active {
                guard !note.isHit && !note.isMissed else { continue }
                let dist = abs(scoringPlaneZ - note.position.z)
                if dist <= note.firstBounds && dist < minDistance {
                    minDistance = dist
                    bestNote = note
                }
            }
        }
        
        if let targetNote = bestNote {
            onNoteTapped(targetNote, tapLocation: location)
        }
    }
    
    /// Called when a note passes beyond the scoring plane unhit.
    public func noteWasMissed(_ note: NoteNode, tapLocation: CGPoint? = nil) {
        guard isGameRunning else { return }
        
        missNotes += 1
        totalNotes += 1
        currentCombo = 0
        
        playSFX("BadNote")
        if PlayerProfile.shared.isHapticsEnabled {
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
        }
        
        // Decrease bonus meter
        updateBonusMeter(amount: -0.05)
        
        // Set dancer to lame reaction
        currentDanceLevel = .playLame
        lameDurationTimer = 0.8
        playDanceAnimation(level: .playLame)
        
        // HUD updates
        hudScene?.updateCombo(0)
        hudScene?.updateCounters(hits: hitNotes, misses: missNotes)
        hudScene?.showJudgment(text: GameConstants.Judgments.miss, scoreEarned: 0, color: GameConstants.Palette.missColor, at: tapLocation)
    }
    
    private func updatePlayerScore(amount: Int) {
        score = max(0, score + amount)
    }
    
    private func updateBonusMeter(amount: Float) {
        bonusMeter = min(max(0.0, bonusMeter + amount), 1.0)
        hudScene?.updateEnergyMeter(percentage: CGFloat(bonusMeter))
        
        // Energy Meter Filled Bonus (Ported from DanceGameController.EnergyMeterFilled)
        if bonusMeter >= 1.0 {
            energyMeterFilled()
        }
    }
    
    public func activateFeverBonus() {
        energyMeterFilled()
    }
    
    private func energyMeterFilled() {
        score += energyFillBonus // +500 points
        bonusMeter = 0.0
        playSFX(GameConstants.Audio.sfxGood4)
        
        hudScene?.updateScore(score)
        hudScene?.updateEnergyMeter(percentage: 0.0)
        hudScene?.showJudgment(text: GameConstants.Judgments.feverBonus, scoreEarned: energyFillBonus, color: GameConstants.Palette.feverBonusColor)
        
        currentDanceLevel = .playBest
    }
    
    private func updateDanceMove() {
        let newLevel: DanceLevel
        if bonusMeter < 0.15 {
            newLevel = (missNotes > 5) ? .playLame : .playGood
        } else if bonusMeter > 0.55 || currentCombo >= 12 {
            newLevel = .playBest
        } else if bonusMeter > 0.3 || currentCombo >= 6 {
            newLevel = .playBetter
        } else {
            newLevel = .playGood
        }
        
        if newLevel != currentDanceLevel {
            currentDanceLevel = newLevel
            playDanceAnimation(level: newLevel)
        }
    }
    
    public func setDanceLevel(_ level: DanceLevel) {
        self.currentDanceLevel = level
        playDanceAnimation(level: level)
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Song completed! Check score percentage to determine victory
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let total = self.hitNotes + self.missNotes
            let hitPercentage = total > 0 ? Float(self.hitNotes) / Float(total) : 0.0
            let isWon = hitPercentage >= 0.5
            self.endGame(isWon: isWon)
        }
    }
    
    public func stopGameToMenu() {
        isGameRunning = false
        self.musicPlayer?.stop()
        spawner?.destroyAllNotes()
        spawner?.isSpawningEnabled = false
        spawner?.isHidden = true
        currentDanceLevel = .standIdle
        playDanceAnimation(level: .standIdle)
        hudScene?.setScreenState(.mainMenu)
    }
    
    public func applyDifficulty(_ difficulty: GameDifficulty) {
        let baseSpeed: Float = 2.4
        let baseInterval: TimeInterval = 0.95
        
        spawner?.noteSpeed = baseSpeed * difficulty.speedMultiplier
        spawner?.spawnInterval = baseInterval * difficulty.spawnIntervalMultiplier
    }
    
    // MARK: - GameHUDSceneDelegate
    
    public func hudDidRequestStartGame() {
        let profile = PlayerProfile.shared
        applyDifficulty(profile.selectedDifficulty)
        hudScene?.setScreenState(.playing)
        startGame()
        loadSong(audioFileName: profile.currentSong.audioFileName, autoPlay: true)
    }
    
    public func hudDidRequestPause() {
        pauseGame()
    }
    
    public func hudDidRequestResume() {
        resumeGame()
    }
    
    public func hudDidRequestRestart() {
        let profile = PlayerProfile.shared
        applyDifficulty(profile.selectedDifficulty)
        hudScene?.setScreenState(.playing)
        restartGame()
    }
    
    public func hudDidRequestMainMenu() {
        stopGameToMenu()
    }
    
    public func hudDidSelectSong(index: Int) {
        let profile = PlayerProfile.shared
        guard index >= 0 && index < profile.availableSongs.count else { return }
        let song = profile.availableSongs[index]
        loadSong(audioFileName: song.audioFileName, autoPlay: false)
    }
    
    public func hudDidSelectCharacter(index: Int) {
        switchCharacter(to: index)
    }
    
    public func hudDidChangeDifficulty(_ difficulty: GameDifficulty) {
        applyDifficulty(difficulty)
    }
    
    // Backwards-compatibility stubs
    public func hudDidTapRestart() {
        restartGame()
    }
    
    public func hudDidTapPause() {
        if isGameRunning {
            pauseGame()
        } else {
            resumeGame()
        }
    }
    
    public func hudDidTapPlayfield(at point: CGPoint) {
        guard isGameRunning, let scnView = scnView else { return }
        
        // 1. Raycast hit-test on SCNView to detect direct taps on 3D NoteNode or hitBox
        let hitResults = scnView.hitTest(point, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .ignoreHiddenNodes: false
        ])
        
        var tappedNote: NoteNode?
        for hit in hitResults {
            var currentNode: SCNNode? = hit.node
            while let node = currentNode {
                if let note = node as? NoteNode {
                    tappedNote = note
                    break
                }
                currentNode = node.parent
            }
            if tappedNote != nil { break }
        }
        
        if let note = tappedNote {
            onNoteTapped(note, tapLocation: point)
        } else {
            // Generous mobile tap-to-rhythm: checks for notes in hit window
            onScreenTapped(at: point)
        }
    }
}
