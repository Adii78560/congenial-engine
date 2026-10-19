//
//  HUDViewModel.swift
//  GrooveGames
//
//  Created by Senior iOS Architect.
//  ViewModel for managing HUD screens, song and character catalogs, and UI state transitions.
//

import Foundation
import UIKit

public final class HUDViewModel {
    
    // MARK: - Dependencies
    private let profile: PlayerProfile
    private let gameManager: DanceGameManager
    
    // MARK: - Initializer
    public init(profile: PlayerProfile = .shared, gameManager: DanceGameManager = .shared) {
        self.profile = profile
        self.gameManager = gameManager
    }
    
    // MARK: - Song Catalog Accessors
    public var availableSongs: [SongData] {
        return profile.availableSongs
    }
    
    public var selectedSongIndex: Int {
        return profile.selectedSongIndex
    }
    
    public var currentSong: SongData {
        return profile.currentSong
    }
    
    public func selectSong(at index: Int) {
        guard index >= 0 && index < availableSongs.count else { return }
        profile.selectSong(at: index)
        gameManager.loadSong(audioFileName: currentSong.audioFileName, autoPlay: false)
    }
    
    // MARK: - Character Catalog Accessors
    public var availableCharacters: [CharacterData] {
        return profile.availableCharacters
    }
    
    public var selectedCharacterIndex: Int {
        return profile.selectedCharacterIndex
    }
    
    public var currentCharacter: CharacterData {
        return profile.currentCharacter
    }
    
    public func isCharacterUnlocked(at index: Int) -> Bool {
        return profile.isCharacterUnlocked(at: index)
    }
    
    public func selectCharacter(at index: Int) {
        guard isCharacterUnlocked(at: index) else { return }
        profile.selectCharacter(at: index)
        gameManager.switchCharacter(to: index)
    }
    
    public func unlockCharacter(at index: Int) -> Bool {
        let success = profile.unlockCharacter(at: index)
        if success {
            gameManager.switchCharacter(to: index)
        }
        return success
    }
    
    // MARK: - Difficulty Accessors
    public var selectedDifficulty: GameDifficulty {
        get { return profile.selectedDifficulty }
        set {
            profile.selectedDifficulty = newValue
            gameManager.applyDifficulty(newValue)
        }
    }
}
