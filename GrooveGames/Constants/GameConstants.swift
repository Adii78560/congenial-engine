//
//  GameConstants.swift
//  GrooveGames
//
//  Created by Senior iOS Architect.
//  Centralized game parameters, timing, scoring, layout, and UI constants.
//

import UIKit
import SceneKit

public enum GameConstants {
    
    // MARK: - Gameplay & Spatial Mechanics
    public enum Mechanics {
        public static let scoringPlaneZ: Float = 4.2
        public static let spawnZ: Float = -18.0
        public static let baseNoteSpeed: Float = 2.4
        public static let baseSpawnInterval: TimeInterval = 0.95
        public static let missBoundaryZ: Float = 5.4
        public static let noteDespawnZ: Float = 6.5
        public static let defaultBPM: Int = 124
        public static let beatFrequency: Float = 2.06 // 124 BPM / 60
        public static let laneOscillationFrequency: Float = 1.25
        public static let laneOscillationAmplitude: Float = 2.2
        public static let laneCenterY: Float = 1.45
    }
    
    // MARK: - Scoring & Combos
    public enum Scoring {
        public static let lowScorePoints: Int = 10
        public static let midScorePoints: Int = 25
        public static let highScorePoints: Int = 50
        public static let feverBonusPoints: Int = 500
        
        public static let lowScoreBonusEnergy: Float = 0.025
        public static let midScoreBonusEnergy: Float = 0.050
        public static let highScoreBonusEnergy: Float = 0.075
        public static let energyDepletionRate: Float = 0.03 // per second
        
        public static let betterComboThreshold: Int = 6
        public static let feverComboThreshold: Int = 12
        public static let lameMissCountThreshold: Int = 5
        public static let lameRecoveryDuration: Float = 2.0
        public static let victoryAccuracyThreshold: Float = 0.50
    }
    
    // MARK: - 3D Scene & Stage Layout
    public enum Stage {
        public static let stageRadius: CGFloat = 3.5
        public static let stageHeight: CGFloat = 0.15
        public static let cameraPosition = SCNVector3(0, 2.1, 8.2)
        public static let cameraTargetPosition = SCNVector3(0, 1.25, 0)
        public static let defaultLightIntensity: CGFloat = 1200
        public static let maxLightPulseAdd: CGFloat = 800
        public static let firefighterXOffset: Float = -0.95
    }
    
    // MARK: - Audio & Sound Effects
    public enum Audio {
        public static let defaultSongId = "AloneTonight"
        public static let defaultMusicVolume: Float = 0.8
        public static let defaultSFXVolume: Float = 1.0
        
        public static let sfxGood1 = "GoodNote1"
        public static let sfxGood2 = "GoodNote2"
        public static let sfxGood3 = "GoodNote3"
        public static let sfxGood4 = "GoodNote4"
        public static let sfxBad = "BadNote"
    }
    
    // MARK: - Colors & Visual Design
    public enum Palette {
        public static let lowScoreColor = UIColor(red: 1.0, green: 0.67, blue: 0.0, alpha: 1.0)
        public static let midScoreColor = UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
        public static let highScoreColor = UIColor(red: 1.0, green: 0.0, blue: 0.47, alpha: 1.0)
        public static let missColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        public static let feverBonusColor = UIColor(red: 1.0, green: 0.3, blue: 0.9, alpha: 1.0)
        public static let successGreenColor = UIColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 1.0)
        public static let neonCyan = UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 1.0)
        public static let neonPink = UIColor(red: 1.0, green: 0.15, blue: 0.7, alpha: 1.0)
        public static let goldColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
    }
    
    // MARK: - Authentication & Platform IDs
    public enum Auth {
        public static let bundleId = "com.RaiEnterprise.GrooveGames"
        public static let leaderboardId = "com.RaiEnterprise.GrooveGames.leaderboard"
        public static let defaultPlayerName = "Groove Dancer"
    }
    
    // MARK: - Legal, Terms & Privacy Links
    public enum Legal {
        public static let privacyPolicyURL = "https://groovegames.io/privacy"
        public static let termsOfServiceURL = "https://groovegames.io/terms"
        public static let supportEmail = "support@groovegames.io"
        public static let appVersion = "1.0.0"
        public static let copyrightNotice = "© 2026 GrooveGames. All rights reserved."
    }
}
