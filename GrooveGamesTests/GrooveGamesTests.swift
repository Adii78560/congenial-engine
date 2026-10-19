//
//  GrooveGamesTests.swift
//  GrooveGamesTests
//
//  Comprehensive verification suite for GrooveGames rhythm gameplay systems.
//

import Testing
import Foundation
import SceneKit
import SpriteKit
import AVFoundation
@testable import GrooveGames

@MainActor
@Suite(.serialized)
struct GrooveGamesTests {

    // MARK: - 1. Asset Verification Tests

    @Test func testAssetsExistInBundle() throws {
        let bundle = Bundle(for: GameViewController.self)
        
        let requiredAssets = [
            ("Dancer", "usdz"),
            ("Note", "usdz"),
            ("AloneTonight", "mp3"),
            ("GoodNote1", "wav"),
            ("GoodNote2", "wav"),
            ("GoodNote3", "wav"),
            ("GoodNote4", "wav"),
            ("BadNote", "wav"),
            ("Anim_Idle", "usdz"),
            ("Anim_Lame", "usdz"),
            ("Anim_Basic", "usdz"),
            ("Anim_Good", "usdz"),
            ("Anim_Awesome", "usdz"),
            ("gameplay_verified", "png")
        ]
        
        for (name, ext) in requiredAssets {
            let url = bundle.url(forResource: name, withExtension: ext)
            #expect(url != nil, "Asset \(name).\(ext) must be present in the bundle")
        }
    }
    
    @Test func testUSDZScenesLoadable() throws {
        let bundle = Bundle(for: GameViewController.self)
        
        let dancerURL = try #require(bundle.url(forResource: "Dancer", withExtension: "usdz"))
        let dancerScene = try SCNScene(url: dancerURL, options: nil)
        #expect(dancerScene.rootNode.childNodes.count > 0, "Dancer scene must contain child nodes")
        
        let noteURL = try #require(bundle.url(forResource: "Note", withExtension: "usdz"))
        let noteScene = try SCNScene(url: noteURL, options: nil)
        #expect(noteScene.rootNode.childNodes.count > 0, "Note scene must contain child nodes")
    }
    
    @Test func testAudioFilesLoadable() throws {
        let bundle = Bundle(for: GameViewController.self)
        
        let musicURL = try #require(bundle.url(forResource: "AloneTonight", withExtension: "mp3"))
        let musicPlayer = try AVAudioPlayer(contentsOf: musicURL)
        #expect(musicPlayer.duration > 50.0, "AloneTonight.mp3 should have expected duration (~60s)")
        
        let sfxNames = ["GoodNote1", "GoodNote2", "GoodNote3", "GoodNote4", "BadNote"]
        for sfx in sfxNames {
            let url = try #require(bundle.url(forResource: sfx, withExtension: "wav"))
            let player = try AVAudioPlayer(contentsOf: url)
            #expect(player.duration > 0, "\(sfx).wav should have valid non-zero duration")
        }
    }

    // MARK: - 2. NoteNode Timing States Tests

    @Test func testNoteNodeStateTransitions() throws {
        let template = SCNNode()
        let scoringZ: Float = 4.2
        let speed: Float = 2.4
        
        let note = NoteNode(template: template, speed: speed, scoringPlaneZ: scoringZ)
        
        // Start far away at z = 0.5 (distance to 4.2 = 3.7 > firstBounds 2.0)
        note.position = SCNVector3(0, 1.2, 0.5)
        note.update(deltaTime: 0.001)
        #expect(note.currentState == .unReady, "Initial distant state should be unReady")
        
        // Move into LowScore zone (z distance between 1.1 and 2.0 => z between 2.2 and 3.1)
        note.position.z = 2.7 // distance = 1.5
        note.update(deltaTime: 0.001)
        #expect(note.currentState == .lowScore, "Note at distance 1.5 should be lowScore")
        
        // Move into MidScore zone (z distance between 0.45 and 1.1 => z between 3.1 and 3.75)
        note.position.z = 3.4 // distance = 0.8
        note.update(deltaTime: 0.001)
        #expect(note.currentState == .midScore, "Note at distance 0.8 should be midScore")
        
        // Move into HighScore sweet spot (z distance between -0.35 and 0.45 => z between 3.75 and 4.55)
        note.position.z = 4.2 // distance = 0.0 (right at scoring plane)
        note.update(deltaTime: 0.001)
        #expect(note.currentState == .highScore, "Note at distance 0.0 should be highScore")
        
        // Pass beyond die bounds (z distance <= -0.35 => z >= 4.56)
        note.position.z = 4.65
        note.update(deltaTime: 0.001)
        #expect(note.currentState == .missed, "Note passing beyond dieBounds should be missed")
        #expect(note.isMissed == true, "isMissed flag should be true")
    }

    // MARK: - 3. NoteSpawner Oscillating Trajectory Tests

    @Test func testNoteSpawnerMovementAndSpawning() throws {
        let template = SCNNode()
        let spawner = NoteSpawner(noteTemplate: template, scoringPlaneZ: 4.2, noteSpeed: 2.4)
        
        let initialX = spawner.position.x
        
        // Simulate frame updates
        spawner.update(deltaTime: 0.5) { _ in }
        let newX = spawner.position.x
        #expect(newX != initialX, "Spawner should oscillate and change position over time")
        
        // Test parenting and note spawning
        let parentScene = SCNNode()
        parentScene.addChildNode(spawner)
        
        let spawnedNote = spawner.spawnNote()
        #expect(spawnedNote != nil, "Spawned note should not be nil")
        #expect(spawner.activeNotes.count == 1, "Active notes count should be 1")
        
        // Destroy all notes
        spawner.destroyAllNotes()
        #expect(spawner.activeNotes.isEmpty, "Active notes should be empty after destroyAllNotes")
    }

    // MARK: - 4. DanceGameManager Scoring Arithmetic Tests

    @Test func testScoringAndComboLogic() throws {
        let manager = DanceGameManager.shared
        
        // Setup in dummy view
        let dummyView = SCNView()
        let dummyHUD = GameHUDScene(size: CGSize(width: 400, height: 800))
        manager.setupGame(in: dummyView, hud: dummyHUD)
        manager.startGame()
        
        #expect(manager.score == 0)
        #expect(manager.hitNotes == 0)
        #expect(manager.missNotes == 0)
        #expect(manager.currentCombo == 0)
        
        let template = SCNNode()
        
        // 1. Hit a LowScore note (+10)
        let note1 = NoteNode(template: template, speed: 2.4, scoringPlaneZ: 4.2)
        note1.position.z = 2.7 // low score zone
        note1.update(deltaTime: 0.001)
        manager.onNoteTapped(note1)
        
        #expect(manager.score == 10)
        #expect(manager.hitNotes == 1)
        #expect(manager.currentCombo == 1)
        
        // 2. Hit a MidScore note (+25)
        let note2 = NoteNode(template: template, speed: 2.4, scoringPlaneZ: 4.2)
        note2.position.z = 3.4 // mid score zone
        note2.update(deltaTime: 0.001)
        manager.onNoteTapped(note2)
        
        #expect(manager.score == 35)
        #expect(manager.hitNotes == 2)
        #expect(manager.currentCombo == 2)
        
        // 3. Hit a HighScore note (+50)
        let note3 = NoteNode(template: template, speed: 2.4, scoringPlaneZ: 4.2)
        note3.position.z = 4.2 // high score zone
        note3.update(deltaTime: 0.001)
        manager.onNoteTapped(note3)
        
        #expect(manager.score == 85)
        #expect(manager.hitNotes == 3)
        #expect(manager.currentCombo == 3)
        
        // 4. Miss a note -> resets combo, missNotes += 1
        let note4 = NoteNode(template: template, speed: 2.4, scoringPlaneZ: 4.2)
        manager.noteWasMissed(note4)
        
        #expect(manager.missNotes == 1)
        #expect(manager.currentCombo == 0, "Combo should reset to 0 on miss")
        #expect(manager.maxCombo == 3, "Max combo should remain at 3")
    }

    // MARK: - 5. Screen Transitions & HUD Tests

    @Test func testScreenStateTransitions() throws {
        let hud = GameHUDScene(size: CGSize(width: 800, height: 400))
        #expect(hud.currentScreenState == .splash)

        hud.setScreenState(.mainMenu)
        #expect(hud.currentScreenState == .mainMenu)

        hud.setScreenState(.songSelect)
        #expect(hud.currentScreenState == .songSelect)

        hud.setScreenState(.characterSelect)
        #expect(hud.currentScreenState == .characterSelect)

        hud.setScreenState(.tutorial)
        #expect(hud.currentScreenState == .tutorial)

        hud.setScreenState(.playing)
        #expect(hud.currentScreenState == .playing)

        hud.setScreenState(.paused)
        #expect(hud.currentScreenState == .paused)

        hud.showGameOver(score: 500, hits: 10, misses: 2, maxCombo: 8, isWon: true)
        #expect(hud.currentScreenState == .results)

        hud.hideGameOver()
        #expect(hud.currentScreenState == .playing)
    }

    // MARK: - 6. Song Catalog & Player Profile Tests

    @Test func testSongCatalogAndProfile() throws {
        let profile = PlayerProfile.shared
        #expect(profile.availableSongs.count >= 3)
        #expect(profile.availableSongs[0].title == "Alone Tonight")
        #expect(profile.availableSongs[1].title == "Japan, Japan")
        #expect(profile.availableSongs[2].title == "She Said")

        profile.selectSong(at: 1)
        #expect(profile.selectedSongIndex == 1)
        #expect(profile.currentSong.title == "Japan, Japan")

        profile.selectSong(at: 0)
        #expect(profile.currentSong.title == "Alone Tonight")

        profile.selectedDifficulty = .hard
        #expect(profile.selectedDifficulty.speedMultiplier == 1.3)
        #expect(profile.selectedDifficulty.spawnIntervalMultiplier == 0.75)
    }

    // MARK: - 7. Dancer Model Integrity & Ground Alignment Tests

    @Test func testDancerModelPositioningNotSinking() throws {
        let manager = DanceGameManager.shared
        let dummyView = SCNView()
        let dummyHUD = GameHUDScene(size: CGSize(width: 800, height: 400))
        manager.setupGame(in: dummyView, hud: dummyHUD)

        guard let dancer = manager.dancerNode else {
            Issue.record("dancerNode should not be nil")
            return
        }

        // Verify dancer wrapper is at or above floor level (y >= 0.0)
        #expect(dancer.position.y >= 0.0, "Dancer wrapper Y must never sink below the stage floor (y=0)")

        // Verify hips world height is around torso level (~1.0m above ground), not sunken to 0!
        if let hips = dancer.childNode(withName: "mixamorig_Hips", recursively: true) {
            let worldY = hips.worldPosition.y
            #expect(worldY > 0.8, "Hips must be at adult waist height (~1.0m), not collapsed to floor: worldY=\(worldY)")
        } else {
            Issue.record("mixamorig_Hips node must exist")
        }

        // Verify head world height is near full height (~1.5m to 1.8m)
        if let head = dancer.childNode(withName: "mixamorig_Head", recursively: true) {
            let headWorldY = head.worldPosition.y
            #expect(headWorldY > 1.4, "Head must be at adult height (>1.4m), not cut off: headWorldY=\(headWorldY)")
        }
    }

    // MARK: - 8. Multi-Character Catalog & Loading Tests
    
    @Test func testAllCharactersExistAndLoadable() throws {
        let bundle = Bundle(for: GameViewController.self)
        let profile = PlayerProfile.shared
        
        #expect(profile.availableCharacters.count == 6, "Expected 6 playable characters")
        
        for char in profile.availableCharacters {
            let url = try #require(bundle.url(forResource: char.modelFileName, withExtension: "usdz"), "Character model \(char.modelFileName).usdz must exist in app bundle")
            let scene = try SCNScene(url: url, options: nil)
            #expect(!scene.rootNode.childNodes.isEmpty, "Character model \(char.modelFileName).usdz must contain child nodes")
        }
    }
    
    @Test func testCharacterCatalogAndUnlocking() throws {
        let profile = PlayerProfile.shared
        
        // 3 starter characters should be unlocked by default
        #expect(profile.isCharacterUnlocked(at: 0) == true, "Blue should be unlocked")
        #expect(profile.isCharacterUnlocked(at: 1) == true, "Alexis should be unlocked")
        #expect(profile.isCharacterUnlocked(at: 2) == true, "Mia should be unlocked")
        
        // Test switching between unlocked characters
        profile.selectCharacter(at: 1)
        #expect(profile.selectedCharacterIndex == 1)
        #expect(profile.currentCharacter.id == "alexis")
        
        profile.selectCharacter(at: 0)
        #expect(profile.selectedCharacterIndex == 0)
        #expect(profile.currentCharacter.id == "blue")
        
        // Add coins to test unlocking Silver Face (cost 100)
        profile.addCoins(250)
        let silverFaceIndex = 3
        let unlocked = profile.unlockCharacter(at: silverFaceIndex)
        #expect(unlocked == true, "Silver Face should be successfully unlocked with enough coins")
        #expect(profile.isCharacterUnlocked(at: silverFaceIndex) == true)
        #expect(profile.selectedCharacterIndex == silverFaceIndex)
        
        // Reset selection back to Blue for consistency
        profile.selectCharacter(at: 0)
    }
    
    @Test func testCharacterSwappingOnStage() throws {
        let manager = DanceGameManager.shared
        let dummyView = SCNView()
        let dummyHUD = GameHUDScene(size: CGSize(width: 800, height: 400))
        manager.setupGame(in: dummyView, hud: dummyHUD)
        
        let profile = PlayerProfile.shared
        
        // Test swapping each character onto the stage
        for i in 0..<profile.availableCharacters.count {
            manager.switchCharacter(to: i)
            let charData = profile.availableCharacters[i]
            
            guard let dancer = manager.dancerNode else {
                Issue.record("dancerNode should not be nil after switching to \(charData.name)")
                continue
            }
            
            #expect(dancer.name == "DancerWrapper_\(charData.id)")
            #expect(dancer.position.y >= 0.0, "\(charData.name) must not sink below floor")
            
            // Verify rig convention is correctly identified
            if ["alexis", "mia", "chickenman"].contains(charData.id.lowercased()) {
                #expect(manager.currentRigAlignment == .blenderX, "\(charData.name) should use .blenderX rig alignment")
            } else {
                #expect(manager.currentRigAlignment == .mixamoY, "\(charData.name) should use .mixamoY rig alignment")
            }
            
            // Verify material normalization (no blown-out emission, valid double-sided geometry)
            dancer.enumerateHierarchy { node, _ in
                if let geo = node.geometry {
                    for mat in geo.materials {
                        #expect(mat.isDoubleSided == true, "Material on \(charData.name) must be double-sided")
                        #expect(mat.transparencyMode == .default, "Material transparencyMode must be default")
                    }
                }
            }
        }
        
        // Reset to initial character
        manager.switchCharacter(to: 0)
    }

    // MARK: - 9. Dance Motion Choreography Tests
    
    @Test func testAllDanceMotionTiersRunWithoutErrors() throws {
        let manager = DanceGameManager.shared
        let dummyView = SCNView()
        let dummyHUD = GameHUDScene(size: CGSize(width: 800, height: 400))
        manager.setupGame(in: dummyView, hud: dummyHUD)
        
        let danceLevels: [DanceGameManager.DanceLevel] = [
            .standIdle,
            .playLame,
            .playGood,
            .playBetter,
            .playBest,
            .playWin,
            .playLose
        ]
        
        // Test choreography for both Mixamo Y-rig (Blue index 0) and Blender X-rig (Alexis index 1)
        for charIdx in [0, 1] {
            manager.switchCharacter(to: charIdx)
            let charName = PlayerProfile.shared.currentCharacter.name
            
            for level in danceLevels {
                manager.setDanceLevel(level)
                #expect(manager.currentDanceLevel == level)
                
                for _ in 1...10 {
                    manager.updateDancerGroove(deltaTime: 0.05)
                }
                
                guard let dancer = manager.dancerNode else {
                    Issue.record("dancerNode must be present during dance animation for \(charName)")
                    continue
                }
                
                // Check that dancer position has valid numbers (no NaN or Infinity)
                #expect(!dancer.position.x.isNaN && !dancer.position.y.isNaN && !dancer.position.z.isNaN)
                #expect(!dancer.eulerAngles.x.isNaN && !dancer.eulerAngles.y.isNaN && !dancer.eulerAngles.z.isNaN)
            }
        }
        
        // Return to Blue and playGood
        manager.switchCharacter(to: 0)
        manager.setDanceLevel(.playGood)
    }

    // MARK: - 10. Apple Auth & Game Center Tests

    @Test func testAppleAuthAndGameCenterProfilePersistence() throws {
        let profile = PlayerProfile.shared
        
        // Test initial or updated state
        profile.setAppleAuthenticated(userId: "test.apple.user.123", name: "Groove Dancer")
        #expect(profile.isAppleAuthenticated == true)
        #expect(profile.appleUserId == "test.apple.user.123")
        #expect(profile.appleDisplayName == "Groove Dancer")

        profile.setGameCenterAuthenticated(name: "ProGamer_Groove")
        #expect(profile.isGameCenterAuthenticated == true)
        #expect(profile.gameCenterPlayerName == "ProGamer_Groove")
    }

    @Test func testHUDAppleLoginAndGameCenterInteractions() throws {
        let hud = GameHUDScene(size: CGSize(width: 800, height: 400))
        #expect(hud.currentScreenState == .splash)

        var appleLoginCalled = false
        var gameCenterCalled = false

        hud.onAppleLoginRequested = {
            appleLoginCalled = true
        }
        hud.onGameCenterRequested = {
            gameCenterCalled = true
        }

        // Verify splash buttons exist in the scene hierarchy
        let appleBtn = hud.childNode(withName: "//splashAppleLoginBtn")
        let gameCenterBtn = hud.childNode(withName: "//splashGameCenterBtn")
        let splashBg = hud.childNode(withName: "//splashBackground")

        #expect(appleBtn != nil, "Splash screen must contain splashAppleLoginBtn")
        #expect(gameCenterBtn != nil, "Splash screen must contain splashGameCenterBtn")
        #expect(splashBg != nil, "Splash screen must contain splashBackground (gameplay_verified)")

        // Trigger action callbacks
        hud.onAppleLoginRequested?()
        #expect(appleLoginCalled == true)

        hud.onGameCenterRequested?()
        #expect(gameCenterCalled == true)
    }

    // MARK: - 11. Settings & Audio Preferences Tests

    @Test func testPlayerSettingsAndProfilePreferences() throws {
        let profile = PlayerProfile.shared
        
        // Test music volume mutation & cycling
        profile.setMusicVolume(0.5)
        #expect(abs(profile.musicVolume - 0.5) < 0.01)
        
        let cycledMusic = profile.cycleMusicVolume()
        #expect(cycledMusic > 0.5)
        
        // Test SFX volume mutation & cycling
        profile.setSFXVolume(0.8)
        #expect(abs(profile.sfxVolume - 0.8) < 0.01)
        
        let cycledSFX = profile.cycleSFXVolume()
        #expect(cycledSFX >= 0.0 && cycledSFX <= 1.0)
        
        // Test haptics toggle
        let initialHaptics = profile.isHapticsEnabled
        let toggled = profile.toggleHaptics()
        #expect(toggled == !initialHaptics)
        #expect(profile.isHapticsEnabled == toggled)
        profile.setHapticsEnabled(true)
        #expect(profile.isHapticsEnabled == true)
        
        // Test custom player name
        profile.setPlayerName("BeatMaster")
        #expect(profile.playerName == "BeatMaster")
        profile.setPlayerName("")
        #expect(profile.playerName != "") // Falls back to default or apple/gc
        
        // Test accuracy calculation
        #expect(profile.accuracyPercentage >= 0.0 && profile.accuracyPercentage <= 100.0)
    }

    // MARK: - 12. Logout & Session Reset Tests

    @Test func testPlayerLogoutAndSessionReset() throws {
        let profile = PlayerProfile.shared
        
        profile.setAppleAuthenticated(userId: "user.apple.temp", name: "AppleDancer")
        profile.setGameCenterAuthenticated(name: "GCDancer")
        profile.setPlayerName("CustomDancer")
        
        #expect(profile.isAppleAuthenticated == true)
        #expect(profile.isGameCenterAuthenticated == true)
        
        // Perform logout
        profile.logout()
        
        #expect(profile.isAppleAuthenticated == false, "Logout must clear Apple auth flag")
        #expect(profile.appleUserId == nil, "Logout must clear Apple user ID")
        #expect(profile.isGameCenterAuthenticated == false, "Logout must clear Game Center auth flag")
        #expect(profile.gameCenterPlayerName == nil, "Logout must clear Game Center player name")
        #expect(profile.customPlayerName == nil, "Logout must clear custom nickname")
        #expect(profile.playerName == "Groove Dancer", "Player name must reset to Guest default")
    }

    // MARK: - 13. Legal Documentation Compliance Tests

    @Test func testLegalDocumentationCompleteness() throws {
        // Terms of Service verification
        let terms = PlayerProfile.termsOfService
        #expect(terms.count >= 5, "Terms of service must contain at least 5 standard sections")
        for section in terms {
            #expect(!section.title.isEmpty, "Terms section title must not be empty")
            #expect(!section.body.isEmpty, "Terms section body must not be empty")
        }
        
        // Privacy Policy verification (App Store compliant)
        let privacy = PlayerProfile.privacyPolicy
        #expect(privacy.count >= 5, "Privacy policy must contain at least 5 standard compliance sections")
        for section in privacy {
            #expect(!section.title.isEmpty, "Privacy section title must not be empty")
            #expect(!section.body.isEmpty, "Privacy section body must not be empty")
        }
    }

    // MARK: - 14. HUD Navigation & Layer Visibility Tests

    @Test func testNewScreenStatesAndLayers() throws {
        let hud = GameHUDScene(size: CGSize(width: 852, height: 393))
        
        // 1. Profile screen transition
        hud.setScreenState(.profile)
        #expect(hud.currentScreenState == .profile)
        let profileNode = hud.childNode(withName: "//profileBackBtn")
        #expect(profileNode != nil, "Profile screen must display profileBackBtn")
        
        // 2. Settings screen transition
        hud.setScreenState(.settings)
        #expect(hud.currentScreenState == .settings)
        let settingsBack = hud.childNode(withName: "//settingsBackBtn")
        let musicBtn = hud.childNode(withName: "//settingsMusicBtn")
        let sfxBtn = hud.childNode(withName: "//settingsSFXBtn")
        let hapticsBtn = hud.childNode(withName: "//settingsHapticsBtn")
        let termsBtn = hud.childNode(withName: "//settingsTermsBtn")
        let privacyBtn = hud.childNode(withName: "//settingsPrivacyBtn")
        let logoutBtn = hud.childNode(withName: "//settingsLogoutBtn")
        
        #expect(settingsBack != nil, "Settings must have settingsBackBtn")
        #expect(musicBtn != nil, "Settings must have settingsMusicBtn")
        #expect(sfxBtn != nil, "Settings must have settingsSFXBtn")
        #expect(hapticsBtn != nil, "Settings must have settingsHapticsBtn")
        #expect(termsBtn != nil, "Settings must have settingsTermsBtn")
        #expect(privacyBtn != nil, "Settings must have settingsPrivacyBtn")
        #expect(logoutBtn != nil, "Settings must have settingsLogoutBtn")
        
        // 3. Terms of Service modal
        hud.setScreenState(.termsOfService)
        #expect(hud.currentScreenState == .termsOfService)
        let termsClose = hud.childNode(withName: "//termsCloseBtn")
        #expect(termsClose != nil, "Terms modal must have termsCloseBtn")
        
        // 4. Privacy Policy modal
        hud.setScreenState(.privacyPolicy)
        #expect(hud.currentScreenState == .privacyPolicy)
        let privacyClose = hud.childNode(withName: "//privacyCloseBtn")
        #expect(privacyClose != nil, "Privacy modal must have privacyCloseBtn")
        
        // 5. Return to Main Menu
        hud.setScreenState(.mainMenu)
        #expect(hud.currentScreenState == .mainMenu)
        let menuProfile = hud.childNode(withName: "//menuProfileBtn")
        let menuSettings = hud.childNode(withName: "//menuSettingsBtn")
        #expect(menuProfile != nil, "Main menu must have menuProfileBtn")
        #expect(menuSettings != nil, "Main menu must have menuSettingsBtn")
    }
    
    // MARK: - 15. Splash Authentication Requirement Test
    
    @Test func testSplashAuthenticationRequiredToEnter() throws {
        let profile = PlayerProfile.shared
        profile.logout()
        #expect(profile.isAppleLoggedIn == false)
        #expect(profile.isGameCenterLoggedIn == false)
        
        let hud = GameHUDScene(size: CGSize(width: 800, height: 400))
        hud.setScreenState(.splash)
        
        let lockBadge = hud.childNode(withName: "//splashLockBadge")
        #expect(lockBadge != nil, "Splash screen must show lock badge when unauthenticated")
        
        // When authenticated, splash screen shows enter badge
        profile.setAppleAuthenticated(userId: "apple.test.auth", name: "GrooveKing")
        #expect(profile.isAppleLoggedIn == true)
        
        hud.setScreenState(.splash)
        let enterBadge = hud.childNode(withName: "//splashEnterBadge")
        #expect(enterBadge != nil, "Splash screen must show enter badge when authenticated")
    }
}
