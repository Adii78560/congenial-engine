//
//  ProfileViewModel.swift
//  GrooveGames
//
//  Created by Senior iOS Architect.
//  ViewModel for player authentication, stats, settings, audio volumes, and legal documentation.
//

import Foundation
import UIKit

public final class ProfileViewModel {
    
    // MARK: - Dependencies
    private let profile: PlayerProfile
    
    // MARK: - Initializer
    public init(profile: PlayerProfile = .shared) {
        self.profile = profile
    }
    
    // MARK: - Player Identity & Auth
    public var playerName: String {
        return profile.playerName
    }
    
    public var isAppleLoggedIn: Bool {
        return profile.isAppleLoggedIn
    }
    
    public var isGameCenterLoggedIn: Bool {
        return profile.isGameCenterLoggedIn
    }
    
    public var appleDisplayName: String? {
        return profile.appleDisplayName
    }
    
    public var gameCenterPlayerName: String? {
        return profile.gameCenterPlayerName
    }
    
    // MARK: - Player Stats
    public var bestScore: Int {
        return profile.bestScore
    }
    
    public var coinsTotal: Int {
        return profile.coinsTotal
    }
    
    public var totalSongsPlayed: Int {
        return profile.totalSongsPlayed
    }
    
    public var accuracyPercentage: Double {
        return profile.accuracyPercentage
    }
    
    // MARK: - Settings Preferences
    public var musicVolume: Float {
        return profile.musicVolume
    }
    
    public var sfxVolume: Float {
        return profile.sfxVolume
    }
    
    public var isHapticsEnabled: Bool {
        return profile.isHapticsEnabled
    }
    
    public func setMusicVolume(_ volume: Float) {
        profile.setMusicVolume(volume)
    }
    
    public func setSFXVolume(_ volume: Float) {
        profile.setSFXVolume(volume)
    }
    
    public func setHapticsEnabled(_ enabled: Bool) {
        profile.setHapticsEnabled(enabled)
    }
    
    public func setCustomPlayerName(_ name: String) {
        profile.setPlayerName(name)
    }
    
    public func logout() {
        profile.logout()
    }
    
    // MARK: - Legal Documentation URLs
    public var privacyPolicyURL: URL? {
        return URL(string: GameConstants.Legal.privacyPolicyURL)
    }
    
    public var termsOfServiceURL: URL? {
        return URL(string: GameConstants.Legal.termsOfServiceURL)
    }
}
