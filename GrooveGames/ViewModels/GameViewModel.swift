//
//  GameViewModel.swift
//  GrooveGames
//
//  Created by Senior iOS Architect.
//  ViewModel for core rhythm gameplay, scoring, combo tracking, and energy levels.
//

import Foundation
import UIKit
import SceneKit
import SpriteKit

public final class GameViewModel {
    
    // MARK: - Dependencies
    private let manager: DanceGameManager
    private let profile: PlayerProfile
    
    // MARK: - Initializer
    public init(manager: DanceGameManager = .shared, profile: PlayerProfile = .shared) {
        self.manager = manager
        self.profile = profile
    }
    
    // MARK: - Game State Accessors
    public var isGameRunning: Bool {
        return manager.isGameRunning
    }
    
    public var score: Int {
        return manager.score
    }
    
    public var currentCombo: Int {
        return manager.currentCombo
    }
    
    public var hitNotes: Int {
        return manager.hitNotes
    }
    
    public var missNotes: Int {
        return manager.missNotes
    }
    
    public var bonusMeter: Float {
        return manager.bonusMeter
    }
    
    public var currentDanceLevel: DanceGameManager.DanceLevel {
        return manager.currentDanceLevel
    }
    
    // MARK: - Game Lifecycle Commands
    public func startGame() {
        manager.startGame()
    }
    
    public func pauseGame() {
        manager.pauseGame()
    }
    
    public func resumeGame() {
        manager.resumeGame()
    }
    
    public func restartGame() {
        manager.restartGame()
    }
    
    public func stopGameToMenu() {
        manager.stopGameToMenu()
    }
    
    public func applyDifficulty(_ difficulty: GameDifficulty) {
        manager.applyDifficulty(difficulty)
    }
    
    public func loadSong(audioFileName: String, autoPlay: Bool) {
        manager.loadSong(audioFileName: audioFileName, autoPlay: autoPlay)
    }
    
    public func onNoteTapped(_ note: NoteNode) {
        manager.onNoteTapped(note)
    }
    
    public func noteWasMissed(_ note: NoteNode) {
        manager.noteWasMissed(note)
    }
    
    public func activateFeverBonus() {
        manager.activateFeverBonus()
    }
}
