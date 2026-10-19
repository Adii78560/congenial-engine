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
        public static let gameCenterCyan = UIColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 1.0)
        public static let warningRed = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
    }
    
    // MARK: - Gameplay Judgments & Toast Notifications
    public enum Judgments {
        public static let feverBonus = "FEVER BONUS!"
        public static let perfect = "PERFECT"
        public static let great = "GREAT"
        public static let good = "GOOD"
        public static let miss = "MISS"
        public static let loggedOut = "LOGGED OUT"
        
        public static func unlockedCharacter(_ name: String) -> String {
            return "UNLOCKED \(name.uppercased())!"
        }
        
        public static func needMoreCoins(_ count: Int) -> String {
            return "NEED \(count) MORE COINS!"
        }
        
        public static func welcomePlayer(_ name: String) -> String {
            return "WELCOME, \(name.uppercased())!"
        }
        
        public static func gameCenterPlayer(_ name: String) -> String {
            return "GAME CENTER: \(name.uppercased())"
        }
    }
    
    // MARK: - UI Text & Navigation Labels
    public enum UIStrings {
        // App Identity
        public static let appTitle = "GROOVE GAMES"
        public static let appSubtitle = "3D DANCE RHYTHM ARCADE"
        public static let studioName = "Boogie Down Games"
        public static let studioSubTitle = "Apple Lossless Studio Beatmaps"
        
        // Splash & Authentication
        public static let signInToPlay = "🔒 SIGN IN BELOW TO PLAY"
        public static let signInPrompt = "⚠️  PLEASE SIGN IN WITH APPLE OR GAME CENTER TO PLAY"
        public static func tapToEnter(_ name: String) -> String {
            return "✓ \(name.uppercased()) • TAP ANYWHERE TO ENTER ▶"
        }
        
        // Main Menu
        public static let nowPlaying = "NOW PLAYING"
        public static let chooseTrack = "CHOOSE YOUR TRACK"
        public static let selectDancer = "SELECT YOUR DANCER"
        public static let dancerSubTitle = "Choose your avatar & preview live groove on stage"
        public static let howToPlay = "HOW TO PLAY"
        public static let howToPlaySubTitle = "Follow the beat, tap on time, and build high combo scores"
        public static let playerProfile = "PLAYER PROFILE"
        public static let settings = "SETTINGS & PREFERENCES"
        
        // Profile & Settings Headers
        public static let identitySession = "IDENTITY & SESSION"
        public static let careerPerformance = "CAREER PERFORMANCE"
        public static let audioHaptics = "AUDIO & HAPTICS"
        public static let legalAbout = "LEGAL & ACCOUNT"
        public static let termsOfServiceTitle = "TERMS OF SERVICE"
        public static let privacyPolicyTitle = "PRIVACY POLICY"
        
        // Interactive Buttons & Tags
        public static let playNowButton = "▶  PLAY GAME"
        public static let selectTrackButton = "🎵  SONG SELECT"
        public static func selectDancerButton(_ dancerName: String) -> String {
            return "💃  SELECT DANCER (\(dancerName))"
        }
        public static let profileButton = "👤  PROFILE"
        public static let settingsButton = "⚙️  SETTINGS"
        public static let howToPlayButton = "❓  HOW TO PLAY"
        public static let backButton = "◀  BACK"
        public static let menuButton = "◀  MENU"
        public static let startDancingButton = "▶  START DANCING"
        public static let confirmDancerButton = "✓  CONFIRM DANCER"
        public static let letsGrooveButton = "▶  LET'S GROOVE"
        public static let logoutButton = "🚪  SIGN OUT / SWITCH USER"
        public static let resetSessionButton = "🚪  SIGN OUT / RESET SESSION"
        public static let termsButton = "📄  TERMS OF SERVICE"
        public static let privacyButton = "🔒  PRIVACY POLICY"
        public static let agreeAndReturnButton = "✓  I AGREE & RETURN"
        public static let understoodAndReturnButton = "✓  UNDERSTOOD & RETURN"
        public static let closeButton = "✕"
        
        public static let selectedTag = "✓ SELECTED"
        public static let selectTrackTag = "SELECT TRACK"
        public static let activeDancerTag = "✓ ACTIVE"
        public static let chooseDancerTag = "CHOOSE"
        public static func lockedCostTag(_ cost: Int) -> String {
            return "🔒 \(cost) COINS"
        }
        public static func coinsDisplay(_ count: Int) -> String {
            return "💰 \(count) COINS"
        }
        
        // In-Game HUD & Pause
        public static let scoreTitle = "SCORE"
        public static let combo = "COMBO"
        public static let feverCombo = "🔥 FEVER COMBO"
        public static let starCombo = "★ COMBO"
        public static let grooveGauge = "⚡️ GROOVE GAUGE"
        public static let gamePaused = "GAME PAUSED"
        public static let resumeButton = "▶  RESUME"
        public static let restartButton = "🔁  RESTART"
        public static let mainMenuButton = "🏠  MAIN MENU"
        public static let playAgainButton = "🔁  PLAY AGAIN"
        public static let grooveCompleted = "🎉  GROOVE COMPLETED! GREAT PERFORMANCE!"
        public static let niceTry = "NICE TRY! BETTER LUCK NEXT TIME"
        public static let finalScore = "FINAL SCORE"
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
