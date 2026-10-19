//
//  GameHUDScene.swift
//  GrooveGames
//
//  Full-fledged 2D SpriteKit HUD & Screen System for Groove Games.
//  Supports Splash, Main Menu, Song Select, Tutorial, Gameplay HUD, Pause, and Results.
//

import UIKit
import SpriteKit

public enum GameScreenState {
    case splash
    case mainMenu
    case songSelect
    case characterSelect
    case tutorial
    case playing
    case paused
    case results
    case profile
    case settings
    case termsOfService
    case privacyPolicy
}

public protocol GameHUDSceneDelegate: AnyObject {
    func hudDidRequestStartGame()
    func hudDidRequestPause()
    func hudDidRequestResume()
    func hudDidRequestRestart()
    func hudDidRequestMainMenu()
    func hudDidSelectSong(index: Int)
    func hudDidChangeDifficulty(_ difficulty: GameDifficulty)
    func hudDidSelectCharacter(index: Int)
    func hudDidRequestAppleLogin()
    func hudDidRequestGameCenter()
    func hudDidChangeScreenState(to state: GameScreenState)
    func hudDidTapPlayfield(at point: CGPoint)
}

public extension GameHUDSceneDelegate {
    func hudDidRequestAppleLogin() {}
    func hudDidRequestGameCenter() {}
    func hudDidChangeScreenState(to state: GameScreenState) {}
    func hudDidTapPlayfield(at point: CGPoint) {}
}

// MARK: - Apple Design System Tokens

enum AppleDesign {
    // Fonts (Native Apple San Francisco Pro)
    static func heavyFont(size: CGFloat) -> String {
        return UIFont.systemFont(ofSize: size, weight: .heavy).fontName
    }
    static func boldFont(size: CGFloat) -> String {
        return UIFont.systemFont(ofSize: size, weight: .bold).fontName
    }
    static func semiboldFont(size: CGFloat) -> String {
        return UIFont.systemFont(ofSize: size, weight: .semibold).fontName
    }
    static func mediumFont(size: CGFloat) -> String {
        return UIFont.systemFont(ofSize: size, weight: .medium).fontName
    }
    static func regularFont(size: CGFloat) -> String {
        return UIFont.systemFont(ofSize: size, weight: .regular).fontName
    }
    
    // Glass Backgrounds & Hairline Borders
    static let backdrop = UIColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 0.85)
    static let glassCard = UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 0.82)
    static let glassCardSelected = UIColor(red: 0.16, green: 0.18, blue: 0.26, alpha: 0.92)
    static let glassTile = UIColor(white: 0.14, alpha: 0.75)
    static let glassBorder = UIColor.white.withAlphaComponent(0.12)
    static let glassBorderHighlight = UIColor(red: 0.25, green: 0.82, blue: 1.0, alpha: 0.4)
    
    // Apple System Accents
    static let cyan = UIColor(red: 0.19, green: 0.82, blue: 0.98, alpha: 1.0)
    static let green = UIColor(red: 0.20, green: 0.84, blue: 0.40, alpha: 1.0)
    static let blue = UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0)
    static let purple = UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0)
    static let pink = UIColor(red: 1.0, green: 0.22, blue: 0.45, alpha: 1.0)
    static let gold = UIColor(red: 1.0, green: 0.80, blue: 0.0, alpha: 1.0)
    static let red = UIColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0)
    
    // Typography Colors
    static let label = UIColor.white
    static let secondaryLabel = UIColor(white: 0.72, alpha: 0.9)
    static let tertiaryLabel = UIColor(white: 0.48, alpha: 0.8)
}

public class GameHUDScene: SKScene {
    
    // MARK: - Delegate & Callbacks
    public weak var hudDelegate: GameHUDSceneDelegate?
    public var onScreenStateChanged: ((GameScreenState) -> Void)?
    public var onAppleLoginRequested: (() -> Void)?
    public var onGameCenterRequested: (() -> Void)?
    
    // MARK: - Static Texture Cache
    private static let cachedSplashTexture: SKTexture? = {
        if let splashPath = Bundle.main.path(forResource: "gameplay_verified", ofType: "png"),
           let splashImg = UIImage(contentsOfFile: splashPath) {
            return SKTexture(image: splashImg)
        }
        return nil
    }()
    
    private static let cachedLogoTexture: SKTexture? = {
        if let logoPath = Bundle.main.path(forResource: "GGLogo", ofType: "png"),
           let logoImg = UIImage(contentsOfFile: logoPath) {
            return SKTexture(image: logoImg)
        }
        return nil
    }()

    // MARK: - Screen State
    public private(set) var currentScreenState: GameScreenState = .splash
    
    // MARK: - Root Containers
    private let splashLayer = SKNode()
    private let mainMenuLayer = SKNode()
    private let songSelectLayer = SKNode()
    private let characterSelectLayer = SKNode()
    private let tutorialLayer = SKNode()
    private let gameplayLayer = SKNode()
    private let pauseLayer = SKNode()
    private let resultsLayer = SKNode()
    private let feedbackLayer = SKNode()
    private let profileLayer = SKNode()
    private let settingsLayer = SKNode()
    private let termsLayer = SKNode()
    private let privacyLayer = SKNode()
    
    // MARK: - Gameplay HUD Elements
    private let scoreLabel = SKLabelNode()
    private let bestScoreLabel = SKLabelNode()
    private let comboLabel = SKLabelNode()
    private let comboCountLabel = SKLabelNode()
    private let hitsLabel = SKLabelNode()
    private let missLabel = SKLabelNode()
    private let songTitleBadge = SKLabelNode()
    private let songProgressTrack = SKShapeNode()
    private let songProgressFill = SKShapeNode()
    private let energyTrackNode = SKShapeNode()
    private let energyFillNode = SKShapeNode()
    private let energyTitleLabel = SKLabelNode()
    
    // MARK: - State Cache
    private var displayedScore: Int = 0
    private var targetScore: Int = 0
    private var energyPercent: CGFloat = 0.0
    
    // MARK: - Touch Debouncing & Cooldown
    private var lastTouchTime: TimeInterval = 0.0
    private var lastScreenTransitionTime: TimeInterval = 0.0
    
    // MARK: - Lifecycle
    
    public override init(size: CGSize) {
        super.init(size: size)
        setupLayers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayers()
    }
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        if self.view == nil {
            layoutCurrentScreen()
        } else {
            isRebuildPending = true
        }
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if self.view == nil {
            layoutCurrentScreen()
        } else {
            isRebuildPending = true
        }
    }
    
    private func setupLayers() {
        self.backgroundColor = .clear
        self.scaleMode = .resizeFill
        
        addChild(gameplayLayer)
        addChild(feedbackLayer)
        addChild(splashLayer)
        addChild(mainMenuLayer)
        addChild(songSelectLayer)
        addChild(characterSelectLayer)
        addChild(tutorialLayer)
        addChild(profileLayer)
        addChild(settingsLayer)
        addChild(termsLayer)
        addChild(privacyLayer)
        addChild(pauseLayer)
        addChild(resultsLayer)
        
        feedbackLayer.zPosition = 100
        profileLayer.zPosition = 150
        settingsLayer.zPosition = 150
        termsLayer.zPosition = 180
        privacyLayer.zPosition = 180
        pauseLayer.zPosition = 200
        resultsLayer.zPosition = 200
        
        setupGameplayHUD()
        setScreenState(.splash)
    }
    
    // MARK: - Screen State Transitions
    
    public func setScreenState(_ state: GameScreenState) {
        self.currentScreenState = state
        self.lastScreenTransitionTime = CACurrentMediaTime()
        
        splashLayer.isHidden = (state != .splash)
        mainMenuLayer.isHidden = (state != .mainMenu)
        songSelectLayer.isHidden = (state != .songSelect)
        characterSelectLayer.isHidden = (state != .characterSelect)
        tutorialLayer.isHidden = (state != .tutorial)
        profileLayer.isHidden = (state != .profile)
        settingsLayer.isHidden = (state != .settings)
        termsLayer.isHidden = (state != .termsOfService)
        privacyLayer.isHidden = (state != .privacyPolicy)
        gameplayLayer.isHidden = (state != .playing && state != .paused)
        pauseLayer.isHidden = (state != .paused)
        resultsLayer.isHidden = (state != .results)
        
        if self.view == nil {
            layoutCurrentScreen()
        } else {
            isRebuildPending = true
        }
        onScreenStateChanged?(state)
        hudDelegate?.hudDidChangeScreenState(to: state)
    }
    
    private var isRebuildPending = false
    
    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if isRebuildPending {
            isRebuildPending = false
            layoutCurrentScreen()
        }
    }
    
    public func hideGameOver() {
        resultsLayer.removeAllChildren()
        setScreenState(.playing)
    }

    public func rebuildCurrentScreen() {
        if self.view == nil {
            layoutCurrentScreen()
        } else {
            isRebuildPending = true
        }
    }
    
    public func updateSplashAuthState() {
        let profile = PlayerProfile.shared
        let isLoggedIn = profile.isAppleLoggedIn || profile.isGameCenterLoggedIn
        
        if let authBadge = splashLayer.childNode(withName: "splashEnterBadge") {
            authBadge.isHidden = !isLoggedIn
            if let label = authBadge.childNode(withName: "splashEnterLabel") as? SKLabelNode {
                label.text = GameConstants.UIStrings.tapToEnter(profile.playerName)
            }
        }
        if let lockBadge = splashLayer.childNode(withName: "splashLockBadge") {
            lockBadge.isHidden = isLoggedIn
        }
    }

    private func layoutCurrentScreen() {
        guard size.width > 0 && size.height > 0 else { return }
        
        switch currentScreenState {
        case .splash:
            rebuildSplashScreen()
        case .mainMenu:
            rebuildMainMenuScreen()
        case .songSelect:
            rebuildSongSelectScreen()
        case .characterSelect:
            rebuildCharacterSelectScreen()
        case .tutorial:
            rebuildTutorialScreen()
        case .profile:
            rebuildProfileScreen()
        case .settings:
            rebuildSettingsScreen()
        case .termsOfService:
            rebuildTermsScreen()
        case .privacyPolicy:
            rebuildPrivacyScreen()
        case .playing, .paused:
            layoutGameplayHUD()
            if currentScreenState == .paused {
                rebuildPauseScreen()
            }
        case .results:
            break // Results are built when showGameOver is invoked
        }
    }
    
    // MARK: - 1. Splash Screen
    
    // MARK: - 1. Splash Screen
    
    private func rebuildSplashScreen() {
        splashLayer.removeAllChildren()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let profile = PlayerProfile.shared
        let isLoggedIn = profile.isAppleLoggedIn || profile.isGameCenterLoggedIn
        
        // 1. Ambient Backdrop (subtle dark glass so 3D dancer & lighting glow through)
        if let tex = GameHUDScene.cachedSplashTexture {
            let bgSprite = SKSpriteNode(texture: tex, size: size)
            bgSprite.name = "splashBackground"
            bgSprite.position = center
            bgSprite.zPosition = -10
            bgSprite.alpha = 0.0
            bgSprite.isHidden = true
            splashLayer.addChild(bgSprite)
        }
        
        let glassScrim = SKShapeNode(rectOf: size)
        if splashLayer.childNode(withName: "splashBackground") == nil {
            glassScrim.name = "splashBackground"
        }
        glassScrim.position = center
        glassScrim.fillColor = UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 0.45)
        glassScrim.strokeColor = .clear
        glassScrim.zPosition = -5
        splashLayer.addChild(glassScrim)
        
        // 2. Apple Hero Glass Card
        let cardW: CGFloat = min(size.width * 0.72, 460)
        let cardH: CGFloat = min(size.height * 0.52, 175)
        let cardY = center.y + 36
        
        let heroCard = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 22)
        heroCard.position = CGPoint(x: center.x, y: cardY)
        heroCard.fillColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.92)
        heroCard.strokeColor = AppleDesign.glassBorder
        heroCard.lineWidth = 1.0
        heroCard.zPosition = 10
        splashLayer.addChild(heroCard)
        
        // App Icon (GGLogo) in Apple Squircle
        var logoOffsetY: CGFloat = 28
        if let logoTex = GameHUDScene.cachedLogoTexture {
            let iconContainer = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 12)
            iconContainer.position = CGPoint(x: 0, y: cardH / 2 - 34)
            iconContainer.fillColor = UIColor(white: 0.12, alpha: 0.9)
            iconContainer.strokeColor = UIColor.white.withAlphaComponent(0.2)
            iconContainer.lineWidth = 1.0
            
            let logoSprite = SKSpriteNode(texture: logoTex, size: CGSize(width: 46, height: 46))
            iconContainer.addChild(logoSprite)
            heroCard.addChild(iconContainer)
            logoOffsetY = -20
        }
        
        // Title: GROOVE GAMES
        let logoTitle = SKLabelNode(text: GameConstants.UIStrings.appTitle)
        logoTitle.fontName = AppleDesign.heavyFont(size: 24)
        logoTitle.fontSize = 24
        logoTitle.fontColor = AppleDesign.label
        logoTitle.position = CGPoint(x: 0, y: cardH / 2 - 70 + logoOffsetY)
        heroCard.addChild(logoTitle)
        
        // Subtitle: 3D Dance Rhythm Arcade
        let logoSubtitle = SKLabelNode(text: GameConstants.UIStrings.appSubtitle)
        logoSubtitle.fontName = AppleDesign.semiboldFont(size: 10.5)
        logoSubtitle.fontSize = 10.5
        logoSubtitle.fontColor = AppleDesign.cyan
        logoSubtitle.position = CGPoint(x: 0, y: cardH / 2 - 90 + logoOffsetY)
        heroCard.addChild(logoSubtitle)
        
        // Studio byline
        let studioLabel = SKLabelNode(text: GameConstants.UIStrings.studioName)
        studioLabel.fontName = AppleDesign.mediumFont(size: 9.5)
        studioLabel.fontSize = 9.5
        studioLabel.fontColor = AppleDesign.secondaryLabel
        studioLabel.position = CGPoint(x: 0, y: cardH / 2 - 106 + logoOffsetY)
        heroCard.addChild(studioLabel)
        
        // 3. Interactive Auth Status Capsule (Centered between hero card and native buttons)
        let badgeW = min(cardW - 40, 360)
        let badgeH: CGFloat = 38
        let badgeY = max(88, cardY - cardH / 2 - 28)
        
        let authBadge = buildCapsule(
            size: CGSize(width: badgeW, height: badgeH),
            fillColor: UIColor(red: 0.10, green: 0.32, blue: 0.18, alpha: 0.94),
            strokeColor: AppleDesign.green.withAlphaComponent(0.7)
        )
        authBadge.name = "splashEnterBadge"
        authBadge.position = CGPoint(x: center.x, y: badgeY)
        authBadge.zPosition = 20
        authBadge.isHidden = !isLoggedIn
        splashLayer.addChild(authBadge)
        
        let authText = SKLabelNode(text: GameConstants.UIStrings.tapToEnter(profile.playerName))
        authText.name = "splashEnterLabel"
        authText.fontName = AppleDesign.boldFont(size: 11.5)
        authText.fontSize = 11.5
        authText.fontColor = AppleDesign.green
        authText.verticalAlignmentMode = .center
        authBadge.addChild(authText)
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.025, duration: 0.6),
            SKAction.scale(to: 0.985, duration: 0.6)
        ])
        authBadge.run(SKAction.repeatForever(pulse))
        
        let promptBadge = buildCapsule(
            size: CGSize(width: badgeW, height: badgeH),
            fillColor: AppleDesign.glassCard,
            strokeColor: AppleDesign.cyan.withAlphaComponent(0.4)
        )
        promptBadge.name = "splashLockBadge"
        promptBadge.position = CGPoint(x: center.x, y: badgeY)
        promptBadge.zPosition = 20
        promptBadge.isHidden = isLoggedIn
        splashLayer.addChild(promptBadge)
        
        let promptText = SKLabelNode(text: GameConstants.UIStrings.signInToPlay)
        promptText.name = "splashLockLabel"
        promptText.fontName = AppleDesign.semiboldFont(size: 11)
        promptText.fontSize = 11
        promptText.fontColor = AppleDesign.cyan
        promptText.verticalAlignmentMode = .center
        promptBadge.addChild(promptText)
        
        // Placeholders for hit-testing / tests
        buildSplashAuthButtons(center: center)
    }
    
    private func buildSplashAuthButtons(center: CGPoint) {
        let appleNode = SKNode()
        appleNode.name = "splashAppleLoginBtn"
        appleNode.position = CGPoint(x: center.x - 118, y: max(30, center.y - 120))
        splashLayer.addChild(appleNode)
        
        let gcNode = SKNode()
        gcNode.name = "splashGameCenterBtn"
        gcNode.position = CGPoint(x: center.x + 118, y: max(30, center.y - 120))
        splashLayer.addChild(gcNode)
    }
    
    public func showLoginRequiredPrompt() {
        splashLayer.childNode(withName: "loginRequiredToast")?.removeFromParent()
        
        let toast = SKShapeNode(rectOf: CGSize(width: min(size.width * 0.78, 460), height: 40), cornerRadius: 20)
        toast.name = "loginRequiredToast"
        toast.position = CGPoint(x: size.width / 2, y: max(95, size.height * 0.25))
        toast.fillColor = UIColor(red: 0.22, green: 0.08, blue: 0.10, alpha: 0.95)
        toast.strokeColor = AppleDesign.red.withAlphaComponent(0.8)
        toast.lineWidth = 1.0
        toast.zPosition = 100
        
        let label = SKLabelNode(text: GameConstants.UIStrings.signInPrompt)
        label.fontName = AppleDesign.boldFont(size: 11)
        label.fontSize = 11
        label.fontColor = AppleDesign.label
        label.verticalAlignmentMode = .center
        toast.addChild(label)
        
        splashLayer.addChild(toast)
        
        let shakeLeft = SKAction.moveBy(x: -8, y: 0, duration: 0.05)
        let shakeRight = SKAction.moveBy(x: 16, y: 0, duration: 0.10)
        let shakeBack = SKAction.moveBy(x: -8, y: 0, duration: 0.05)
        let wait = SKAction.wait(forDuration: 2.2)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        toast.run(SKAction.sequence([shakeLeft, shakeRight, shakeBack, wait, fade, remove]))
    }
    
    // MARK: - 2. Main Menu Screen
    
    private func rebuildMainMenuScreen() {
        mainMenuLayer.removeAllChildren()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let profile = PlayerProfile.shared
        
        // 1. Subtle Dark Vignette Backdrop (live 3D dancer grooves behind)
        let scrim = SKShapeNode(rectOf: size)
        scrim.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.55)
        scrim.strokeColor = .clear
        scrim.position = center
        scrim.zPosition = -10
        mainMenuLayer.addChild(scrim)
        
        // 2. Top Navigation & User Capsule Bar
        let topBarY = size.height - 38
        
        // Title (Left)
        let titleLabel = SKLabelNode(text: GameConstants.UIStrings.appTitle)
        titleLabel.fontName = AppleDesign.heavyFont(size: 24)
        titleLabel.fontSize = 24
        titleLabel.fontColor = AppleDesign.label
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 48, y: topBarY)
        mainMenuLayer.addChild(titleLabel)
        
        // Player Profile Status Pill (Top Right, Apple Glass Capsule)
        let userPillW: CGFloat = min(size.width * 0.38, 260)
        let userPill = buildCapsule(
            size: CGSize(width: userPillW, height: 34),
            fillColor: AppleDesign.glassCard,
            strokeColor: AppleDesign.glassBorder
        )
        userPill.name = "menuProfileBtn"
        userPill.position = CGPoint(x: size.width - 48 - userPillW / 2, y: topBarY)
        mainMenuLayer.addChild(userPill)
        
        let statsText = SKLabelNode(text: "👤 \(profile.playerName)  •  🏆 \(profile.bestScore)")
        statsText.name = "menuProfileBtn"
        statsText.fontName = AppleDesign.semiboldFont(size: 12)
        statsText.fontSize = 12
        statsText.fontColor = AppleDesign.gold
        statsText.verticalAlignmentMode = .center
        userPill.addChild(statsText)
        
        // 3. Two-Column Dashboard Layout
        let cardW: CGFloat = min(size.width * 0.42, 330)
        let cardH: CGFloat = min(size.height * 0.68, 235)
        let cardCenterY = center.y - 12
        let leftCenterX = 48 + cardW / 2
        
        // --- LEFT COLUMN: Apple Music-style Now Playing Card ---
        let songCard = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 22)
        songCard.position = CGPoint(x: leftCenterX, y: cardCenterY)
        songCard.fillColor = AppleDesign.glassCard
        songCard.strokeColor = AppleDesign.glassBorder
        songCard.lineWidth = 1.0
        mainMenuLayer.addChild(songCard)
        
        let cardHeader = SKLabelNode(text: GameConstants.UIStrings.nowPlaying)
        cardHeader.fontName = AppleDesign.boldFont(size: 10)
        cardHeader.fontSize = 10
        cardHeader.fontColor = AppleDesign.secondaryLabel
        cardHeader.position = CGPoint(x: 0, y: cardH / 2 - 24)
        songCard.addChild(cardHeader)
        
        let song = profile.currentSong
        let songTitle = SKLabelNode(text: song.title)
        songTitle.fontName = AppleDesign.boldFont(size: 20)
        songTitle.fontSize = 20
        songTitle.fontColor = AppleDesign.label
        songTitle.position = CGPoint(x: 0, y: cardH / 2 - 52)
        songCard.addChild(songTitle)
        
        let songMeta = SKLabelNode(text: "\(song.artist)  •  \(song.bpm) BPM")
        songMeta.fontName = AppleDesign.mediumFont(size: 12)
        songMeta.fontSize = 12
        songMeta.fontColor = AppleDesign.cyan
        songMeta.position = CGPoint(x: 0, y: cardH / 2 - 76)
        songCard.addChild(songMeta)
        
        // Golden Star Rating
        let starsStr = String(repeating: "★ ", count: song.difficultyStars) + String(repeating: "☆ ", count: 5 - song.difficultyStars)
        let starsLabel = SKLabelNode(text: starsStr.trimmingCharacters(in: .whitespaces))
        starsLabel.fontName = AppleDesign.boldFont(size: 13)
        starsLabel.fontSize = 13
        starsLabel.fontColor = AppleDesign.gold
        starsLabel.position = CGPoint(x: 0, y: cardH / 2 - 104)
        songCard.addChild(starsLabel)
        
        // Difficulty pill
        let diffColor = (profile.selectedDifficulty == .hard) ? AppleDesign.pink :
                        (profile.selectedDifficulty == .easy) ? AppleDesign.green : AppleDesign.cyan
        let diffPill = buildCapsule(size: CGSize(width: 140, height: 26), fillColor: diffColor.withAlphaComponent(0.18), strokeColor: diffColor.withAlphaComponent(0.5))
        diffPill.position = CGPoint(x: 0, y: cardH / 2 - 138)
        songCard.addChild(diffPill)
        
        let diffText = SKLabelNode(text: "\(profile.selectedDifficulty.rawValue) DIFFICULTY")
        diffText.fontName = AppleDesign.boldFont(size: 10)
        diffText.fontSize = 10
        diffText.fontColor = diffColor
        diffText.verticalAlignmentMode = .center
        diffPill.addChild(diffText)
        
        // Dancer Status Pill
        let charPill = buildCapsule(size: CGSize(width: cardW - 36, height: 28), fillColor: UIColor(white: 0.16, alpha: 0.6), strokeColor: AppleDesign.glassBorder)
        charPill.position = CGPoint(x: 0, y: -cardH / 2 + 30)
        songCard.addChild(charPill)
        
        let charText = SKLabelNode(text: "💃 Dancer: \(profile.currentCharacter.name) • \(profile.currentCharacter.genre)")
        charText.fontName = AppleDesign.mediumFont(size: 11)
        charText.fontSize = 11
        charText.fontColor = AppleDesign.label
        charText.verticalAlignmentMode = .center
        charPill.addChild(charText)
        
        // --- RIGHT COLUMN: Apple Action Hub ---
        let btnW: CGFloat = min(size.width * 0.38, 270)
        let rightX = size.width - 48 - btnW / 2
        let startBtnY = cardCenterY + cardH / 2 - 20
        
        // 1. Primary PLAY GAME Button (Apple Cyan Vibrant Capsule)
        let playBtn = buildButton(
            name: "menuPlayBtn",
            text: GameConstants.UIStrings.playNowButton,
            size: CGSize(width: btnW, height: 42),
            fillColor: AppleDesign.cyan,
            textColor: UIColor(white: 0.05, alpha: 1.0),
            strokeColor: UIColor.white.withAlphaComponent(0.4)
        )
        playBtn.position = CGPoint(x: rightX, y: startBtnY)
        mainMenuLayer.addChild(playBtn)
        
        // 2. Song Select Button
        let songBtn = buildButton(
            name: "menuSongBtn",
            text: GameConstants.UIStrings.selectTrackButton,
            size: CGSize(width: btnW, height: 35),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        songBtn.position = CGPoint(x: rightX, y: startBtnY - 44)
        mainMenuLayer.addChild(songBtn)
        
        // 3. Dancer Select Button
        let charBtn = buildButton(
            name: "menuCharBtn",
            text: GameConstants.UIStrings.selectDancerButton(profile.currentCharacter.name),
            size: CGSize(width: btnW, height: 35),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        charBtn.position = CGPoint(x: rightX, y: startBtnY - 84)
        mainMenuLayer.addChild(charBtn)
        
        // 4. Split Row: Profile & Settings
        let halfW = (btnW - 10) / 2
        let leftBtnX = rightX - halfW / 2 - 5
        let rightBtnX = rightX + halfW / 2 + 5
        
        let profileBtn = buildButton(
            name: "menuProfileBtn",
            text: GameConstants.UIStrings.profileButton,
            size: CGSize(width: halfW, height: 35),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        profileBtn.position = CGPoint(x: leftBtnX, y: startBtnY - 124)
        mainMenuLayer.addChild(profileBtn)
        
        let settingsBtn = buildButton(
            name: "menuSettingsBtn",
            text: GameConstants.UIStrings.settingsButton,
            size: CGSize(width: halfW, height: 35),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        settingsBtn.position = CGPoint(x: rightBtnX, y: startBtnY - 124)
        mainMenuLayer.addChild(settingsBtn)
        
        // 5. Split Row: Difficulty & Tutorial
        let diffBtn = buildButton(
            name: "menuDiffBtn",
            text: "🎯  \(profile.selectedDifficulty.rawValue)",
            size: CGSize(width: halfW, height: 35),
            fillColor: AppleDesign.glassCard,
            textColor: diffColor,
            strokeColor: diffColor.withAlphaComponent(0.4)
        )
        diffBtn.position = CGPoint(x: leftBtnX, y: startBtnY - 164)
        mainMenuLayer.addChild(diffBtn)
        
        let tutBtn = buildButton(
            name: "menuTutBtn",
            text: GameConstants.UIStrings.howToPlayButton,
            size: CGSize(width: halfW, height: 35),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.secondaryLabel,
            strokeColor: AppleDesign.glassBorder
        )
        tutBtn.position = CGPoint(x: rightBtnX, y: startBtnY - 164)
        mainMenuLayer.addChild(tutBtn)
    }
    
    // MARK: - 3. Song Select Screen
    
    private func rebuildSongSelectScreen() {
        songSelectLayer.removeAllChildren()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let profile = PlayerProfile.shared
        
        // 1. Subtle Dark Vignette Backdrop
        let bg = SKShapeNode(rectOf: size)
        bg.position = center
        bg.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.65)
        bg.strokeColor = .clear
        songSelectLayer.addChild(bg)
        
        // 2. Header
        let titleLabel = SKLabelNode(text: GameConstants.UIStrings.chooseTrack)
        titleLabel.fontName = AppleDesign.heavyFont(size: 22)
        titleLabel.fontSize = 22
        titleLabel.fontColor = AppleDesign.label
        titleLabel.position = CGPoint(x: center.x, y: size.height - 38)
        songSelectLayer.addChild(titleLabel)
        
        let subTitle = SKLabelNode(text: GameConstants.UIStrings.studioSubTitle)
        subTitle.fontName = AppleDesign.mediumFont(size: 11)
        subTitle.fontSize = 11
        subTitle.fontColor = AppleDesign.secondaryLabel
        subTitle.position = CGPoint(x: center.x, y: size.height - 54)
        songSelectLayer.addChild(subTitle)
        
        // 3. 3 Song Cards in Apple Arcade/Music Glass Style
        let songs = profile.availableSongs
        let cardW: CGFloat = min((size.width - 120) / 3, 230)
        let cardH: CGFloat = min(size.height * 0.52, 190)
        let startX = center.x - cardW * CGFloat(songs.count - 1) * 0.55
        
        for (i, song) in songs.enumerated() {
            let xPos = startX + CGFloat(i) * (cardW + 18)
            let isSelected = (i == profile.selectedSongIndex)
            
            let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 20)
            card.name = "songCard_\(i)"
            card.position = CGPoint(x: xPos, y: center.y + 10)
            card.fillColor = isSelected ? AppleDesign.glassCardSelected : AppleDesign.glassCard
            card.strokeColor = isSelected ? AppleDesign.cyan : AppleDesign.glassBorder
            card.lineWidth = isSelected ? 1.5 : 1.0
            songSelectLayer.addChild(card)
            
            let name = SKLabelNode(text: song.title)
            name.name = "songCard_\(i)"
            name.fontName = AppleDesign.boldFont(size: 16)
            name.fontSize = 16
            name.fontColor = isSelected ? AppleDesign.cyan : AppleDesign.label
            name.position = CGPoint(x: 0, y: cardH / 2 - 36)
            card.addChild(name)
            
            let artist = SKLabelNode(text: song.artist)
            artist.name = "songCard_\(i)"
            artist.fontName = AppleDesign.mediumFont(size: 12)
            artist.fontSize = 12
            artist.fontColor = AppleDesign.secondaryLabel
            artist.position = CGPoint(x: 0, y: cardH / 2 - 60)
            card.addChild(artist)
            
            let bpm = SKLabelNode(text: "⚡️ \(song.bpm) BPM  •  ⏱ \(song.duration)")
            bpm.name = "songCard_\(i)"
            bpm.fontName = AppleDesign.semiboldFont(size: 10)
            bpm.fontSize = 10
            bpm.fontColor = AppleDesign.pink
            bpm.position = CGPoint(x: 0, y: cardH / 2 - 86)
            card.addChild(bpm)
            
            let starsStr = String(repeating: "★ ", count: song.difficultyStars) + String(repeating: "☆ ", count: 5 - song.difficultyStars)
            let starLabel = SKLabelNode(text: starsStr.trimmingCharacters(in: .whitespaces))
            starLabel.name = "songCard_\(i)"
            starLabel.fontName = AppleDesign.boldFont(size: 12)
            starLabel.fontSize = 12
            starLabel.fontColor = AppleDesign.gold
            starLabel.position = CGPoint(x: 0, y: cardH / 2 - 114)
            card.addChild(starLabel)
            
            let tagPillW = cardW - 44
            let tagPill = buildCapsule(
                size: CGSize(width: tagPillW, height: 26),
                fillColor: isSelected ? AppleDesign.green.withAlphaComponent(0.2) : AppleDesign.glassCard,
                strokeColor: isSelected ? AppleDesign.green.withAlphaComponent(0.6) : AppleDesign.glassBorder
            )
            tagPill.name = "songCard_\(i)"
            tagPill.position = CGPoint(x: 0, y: -cardH / 2 + 24)
            card.addChild(tagPill)
            
            let tagText = isSelected ? GameConstants.UIStrings.selectedTag : GameConstants.UIStrings.selectTrackTag
            let tag = SKLabelNode(text: tagText)
            tag.name = "songCard_\(i)"
            tag.fontName = AppleDesign.boldFont(size: 10)
            tag.fontSize = 10
            tag.fontColor = isSelected ? AppleDesign.green : AppleDesign.secondaryLabel
            tag.verticalAlignmentMode = .center
            tagPill.addChild(tag)
        }
        
        // Bottom Action Buttons
        let backBtn = buildButton(
            name: "songBackBtn",
            text: GameConstants.UIStrings.backButton,
            size: CGSize(width: 130, height: 38),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        backBtn.position = CGPoint(x: center.x - 110, y: 38)
        songSelectLayer.addChild(backBtn)
        
        let confirmBtn = buildButton(
            name: "songConfirmBtn",
            text: GameConstants.UIStrings.startDancingButton,
            size: CGSize(width: 210, height: 38),
            fillColor: AppleDesign.cyan,
            textColor: UIColor(white: 0.05, alpha: 1.0),
            strokeColor: UIColor.white.withAlphaComponent(0.4)
        )
        confirmBtn.position = CGPoint(x: center.x + 85, y: 38)
        songSelectLayer.addChild(confirmBtn)
    }
    
    // MARK: - 3b. Character Select Screen
    
    private func rebuildCharacterSelectScreen() {
        characterSelectLayer.removeAllChildren()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let profile = PlayerProfile.shared
        
        // Dim background
        let bg = SKShapeNode(rectOf: size)
        bg.position = center
        bg.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.65)
        bg.strokeColor = .clear
        characterSelectLayer.addChild(bg)
        
        // Title Bar
        let titleLabel = SKLabelNode(text: GameConstants.UIStrings.selectDancer)
        titleLabel.fontName = AppleDesign.heavyFont(size: 22)
        titleLabel.fontSize = 22
        titleLabel.fontColor = AppleDesign.label
        titleLabel.position = CGPoint(x: center.x, y: size.height - 38)
        characterSelectLayer.addChild(titleLabel)
        
        let subTitle = SKLabelNode(text: GameConstants.UIStrings.dancerSubTitle)
        subTitle.fontName = AppleDesign.mediumFont(size: 11)
        subTitle.fontSize = 11
        subTitle.fontColor = AppleDesign.secondaryLabel
        subTitle.position = CGPoint(x: center.x, y: size.height - 54)
        characterSelectLayer.addChild(subTitle)
        
        // Coin Balance (Top Right)
        let coinPill = buildCapsule(
            size: CGSize(width: 140, height: 28),
            fillColor: AppleDesign.glassCard,
            strokeColor: AppleDesign.gold.withAlphaComponent(0.4)
        )
        coinPill.position = CGPoint(x: size.width - 95, y: size.height - 35)
        characterSelectLayer.addChild(coinPill)
        
        let coinText = SKLabelNode(text: GameConstants.UIStrings.coinsDisplay(profile.coinsTotal))
        coinText.fontName = AppleDesign.boldFont(size: 11)
        coinText.fontSize = 11
        coinText.fontColor = AppleDesign.gold
        coinText.verticalAlignmentMode = .center
        coinPill.addChild(coinText)
        
        // 6 Character Cards in 2 rows x 3 columns
        let chars = profile.availableCharacters
        let cardW: CGFloat = min((size.width - 120) / 3, 230)
        let cardH: CGFloat = min((size.height - 130) / 2, 105)
        let colStartX = center.x - (cardW + 14)
        let topRowY = center.y + 40
        let bottomRowY = center.y - cardH - 12 + 40
        
        for (i, char) in chars.enumerated() {
            let col = i % 3
            let row = i / 3
            let xPos = colStartX + CGFloat(col) * (cardW + 14)
            let yPos = (row == 0) ? topRowY : bottomRowY
            let isSelected = (i == profile.selectedCharacterIndex)
            let isUnlocked = profile.isCharacterUnlocked(at: i)
            
            let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 16)
            card.name = "charCard_\(i)"
            card.position = CGPoint(x: xPos, y: yPos)
            
            if isSelected {
                card.fillColor = AppleDesign.glassCardSelected
                card.strokeColor = AppleDesign.cyan
                card.lineWidth = 1.5
            } else if isUnlocked {
                card.fillColor = AppleDesign.glassCard
                card.strokeColor = AppleDesign.glassBorder
                card.lineWidth = 1.0
            } else {
                card.fillColor = UIColor(white: 0.08, alpha: 0.75)
                card.strokeColor = UIColor(white: 0.22, alpha: 0.4)
                card.lineWidth = 1.0
            }
            characterSelectLayer.addChild(card)
            
            // Name
            let nameNode = SKLabelNode(text: char.name)
            nameNode.name = "charCard_\(i)"
            nameNode.fontName = AppleDesign.boldFont(size: 14)
            nameNode.fontSize = 14
            nameNode.fontColor = isSelected ? AppleDesign.cyan : AppleDesign.label
            nameNode.position = CGPoint(x: 0, y: cardH / 2 - 24)
            card.addChild(nameNode)
            
            // Subtitle
            let subNode = SKLabelNode(text: char.subtitle)
            subNode.name = "charCard_\(i)"
            subNode.fontName = AppleDesign.mediumFont(size: 10)
            subNode.fontSize = 10
            subNode.fontColor = AppleDesign.secondaryLabel
            subNode.position = CGPoint(x: 0, y: cardH / 2 - 42)
            card.addChild(subNode)
            
            // Genre
            let genreNode = SKLabelNode(text: "Style: \(char.genre)")
            genreNode.name = "charCard_\(i)"
            genreNode.fontName = AppleDesign.regularFont(size: 10)
            genreNode.fontSize = 10
            genreNode.fontColor = AppleDesign.secondaryLabel
            genreNode.position = CGPoint(x: 0, y: cardH / 2 - 58)
            card.addChild(genreNode)
            
            // Status Tag
            let tagText: String
            let tagColor: UIColor
            if isSelected {
                tagText = GameConstants.UIStrings.activeDancerTag
                tagColor = AppleDesign.green
            } else if isUnlocked {
                tagText = GameConstants.UIStrings.chooseDancerTag
                tagColor = AppleDesign.cyan
            } else {
                tagText = GameConstants.UIStrings.lockedCostTag(char.unlockCost)
                tagColor = (profile.coinsTotal >= char.unlockCost) ? AppleDesign.gold : AppleDesign.red
            }
            
            let tagNode = SKLabelNode(text: tagText)
            tagNode.name = "charCard_\(i)"
            tagNode.fontName = AppleDesign.boldFont(size: 10)
            tagNode.fontSize = 10
            tagNode.fontColor = tagColor
            tagNode.position = CGPoint(x: 0, y: -cardH / 2 + 12)
            card.addChild(tagNode)
        }
        
        // Bottom Action Buttons
        let backBtn = buildButton(
            name: "charBackBtn",
            text: GameConstants.UIStrings.backButton,
            size: CGSize(width: 140, height: 38),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        backBtn.position = CGPoint(x: center.x - 110, y: 32)
        characterSelectLayer.addChild(backBtn)
        
        let confirmBtn = buildButton(
            name: "charConfirmBtn",
            text: GameConstants.UIStrings.confirmDancerButton,
            size: CGSize(width: 190, height: 38),
            fillColor: AppleDesign.cyan,
            textColor: UIColor(white: 0.05, alpha: 1.0),
            strokeColor: UIColor.white.withAlphaComponent(0.4)
        )
        confirmBtn.position = CGPoint(x: center.x + 95, y: 32)
        characterSelectLayer.addChild(confirmBtn)
    }
    
    // MARK: - 4. Tutorial Screen
    
    private func rebuildTutorialScreen() {
        tutorialLayer.removeAllChildren()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        let bg = SKShapeNode(rectOf: size)
        bg.position = center
        bg.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.65)
        bg.strokeColor = .clear
        tutorialLayer.addChild(bg)
        
        let titleLabel = SKLabelNode(text: GameConstants.UIStrings.howToPlay)
        titleLabel.fontName = AppleDesign.heavyFont(size: 22)
        titleLabel.fontSize = 22
        titleLabel.fontColor = AppleDesign.label
        titleLabel.position = CGPoint(x: center.x, y: size.height - 38)
        tutorialLayer.addChild(titleLabel)
        
        let subTitle = SKLabelNode(text: GameConstants.UIStrings.howToPlaySubTitle)
        subTitle.fontName = AppleDesign.mediumFont(size: 11)
        subTitle.fontSize = 11
        subTitle.fontColor = AppleDesign.secondaryLabel
        subTitle.position = CGPoint(x: center.x, y: size.height - 54)
        tutorialLayer.addChild(subTitle)
        
        // 3 Feature Cards
        let cardW: CGFloat = min((size.width - 100) / 3, 230)
        let cardH: CGFloat = min(size.height * 0.52, 185)
        let startX = center.x - cardW * 1.1
        
        let steps = [
            ("🎵 1. INCOMING NOTES", "Notes float along the 3D stage towards the scoring ring.", "Silver = Prepare", AppleDesign.cyan),
            ("🎯 2. HIT TIMING", "Tap the note when it reaches the ring!\n• PERFECT: +50\n• GREAT: +25\n• GOOD: +10", "Gold/Cyan = Tap Now!", AppleDesign.gold),
            ("⚡️ 3. GROOVE FEVER", "Maintain combos and fill the groove gauge for a +500 point Fever Bonus!", "🔥 20x Combo = Fever", AppleDesign.pink)
        ]
        
        for (i, step) in steps.enumerated() {
            let xPos = startX + CGFloat(i) * (cardW + 16)
            
            let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 20)
            card.position = CGPoint(x: xPos, y: center.y + 10)
            card.fillColor = AppleDesign.glassCard
            card.strokeColor = AppleDesign.glassBorder
            card.lineWidth = 1.0
            tutorialLayer.addChild(card)
            
            let cardHeader = SKLabelNode(text: step.0)
            cardHeader.fontName = AppleDesign.boldFont(size: 12)
            cardHeader.fontSize = 12
            cardHeader.fontColor = step.3
            cardHeader.position = CGPoint(x: 0, y: cardH / 2 - 28)
            card.addChild(cardHeader)
            
            let body = SKLabelNode(text: step.1)
            body.numberOfLines = 4
            body.preferredMaxLayoutWidth = cardW - 24
            body.fontName = AppleDesign.regularFont(size: 11)
            body.fontSize = 11
            body.fontColor = AppleDesign.label
            body.position = CGPoint(x: 0, y: cardH / 2 - 70)
            card.addChild(body)
            
            let hint = SKLabelNode(text: step.2)
            hint.fontName = AppleDesign.semiboldFont(size: 10)
            hint.fontSize = 10
            hint.fontColor = step.3.withAlphaComponent(0.9)
            hint.position = CGPoint(x: 0, y: -cardH / 2 + 18)
            card.addChild(hint)
        }
        
        let gotItBtn = buildButton(
            name: "tutGotItBtn",
            text: GameConstants.UIStrings.letsGrooveButton,
            size: CGSize(width: 210, height: 40),
            fillColor: AppleDesign.cyan,
            textColor: UIColor(white: 0.05, alpha: 1.0),
            strokeColor: UIColor.white.withAlphaComponent(0.4)
        )
        gotItBtn.position = CGPoint(x: center.x, y: 38)
        tutorialLayer.addChild(gotItBtn)
    }
    
    // MARK: - 4b. Player Profile Screen
    
    private func rebuildProfileScreen() {
        profileLayer.removeAllChildren()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let profile = PlayerProfile.shared
        
        // 1. Background Dimming
        let bg = SKShapeNode(rectOf: size)
        bg.position = center
        bg.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.65)
        bg.strokeColor = .clear
        profileLayer.addChild(bg)
        
        // 2. Top Header Bar
        let titleLabel = SKLabelNode(text: GameConstants.UIStrings.playerProfile)
        titleLabel.fontName = AppleDesign.heavyFont(size: 22)
        titleLabel.fontSize = 22
        titleLabel.fontColor = AppleDesign.label
        titleLabel.position = CGPoint(x: center.x, y: size.height - 38)
        profileLayer.addChild(titleLabel)
        
        let backBtn = buildButton(
            name: "profileBackBtn",
            text: GameConstants.UIStrings.menuButton,
            size: CGSize(width: 95, height: 34),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        backBtn.position = CGPoint(x: 65, y: size.height - 38)
        profileLayer.addChild(backBtn)
        
        let settingsBtn = buildButton(
            name: "profileSettingsBtn",
            text: GameConstants.UIStrings.settingsButton,
            size: CGSize(width: 120, height: 34),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        settingsBtn.position = CGPoint(x: size.width - 80, y: size.height - 38)
        profileLayer.addChild(settingsBtn)
        
        // 3. Two Apple Glass Cards Side-by-Side
        let cardW: CGFloat = min(size.width * 0.44, 370)
        let cardH: CGFloat = min(size.height * 0.68, 255)
        let leftCenterX = center.x - cardW / 2 - 12
        let rightCenterX = center.x + cardW / 2 + 12
        let cardY = center.y - 12
        
        // --- LEFT CARD: Identity & Session ---
        let leftCard = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 22)
        leftCard.position = CGPoint(x: leftCenterX, y: cardY)
        leftCard.fillColor = AppleDesign.glassCard
        leftCard.strokeColor = AppleDesign.glassBorder
        leftCard.lineWidth = 1.0
        profileLayer.addChild(leftCard)
        
        let idHeader = SKLabelNode(text: GameConstants.UIStrings.identitySession)
        idHeader.fontName = AppleDesign.boldFont(size: 10)
        idHeader.fontSize = 10
        idHeader.fontColor = AppleDesign.secondaryLabel
        idHeader.position = CGPoint(x: 0, y: cardH / 2 - 26)
        leftCard.addChild(idHeader)
        
        // Player Nickname
        let nameLabel = SKLabelNode(text: "👤 \(profile.playerName)")
        nameLabel.fontName = AppleDesign.boldFont(size: 20)
        nameLabel.fontSize = 20
        nameLabel.fontColor = AppleDesign.label
        nameLabel.position = CGPoint(x: 0, y: cardH / 2 - 54)
        leftCard.addChild(nameLabel)
        
        // Dancer & Genre
        let dancerInfo = SKLabelNode(text: "💃 \(profile.currentCharacter.name) • \(profile.currentCharacter.genre)")
        dancerInfo.fontName = AppleDesign.semiboldFont(size: 12)
        dancerInfo.fontSize = 12
        dancerInfo.fontColor = AppleDesign.gold
        dancerInfo.position = CGPoint(x: 0, y: cardH / 2 - 80)
        leftCard.addChild(dancerInfo)
        
        // Apple ID Status
        let appleDot = profile.isAppleAuthenticated ? "● Apple ID: Connected" : "○ Apple ID: Guest"
        let appleLabel = SKLabelNode(text: appleDot)
        appleLabel.fontName = AppleDesign.mediumFont(size: 11)
        appleLabel.fontSize = 11
        appleLabel.fontColor = profile.isAppleAuthenticated ? AppleDesign.green : AppleDesign.secondaryLabel
        appleLabel.position = CGPoint(x: 0, y: cardH / 2 - 108)
        leftCard.addChild(appleLabel)
        
        // Game Center Status
        let gcName = profile.gameCenterPlayerName ?? "Offline"
        let gcDot = profile.isGameCenterAuthenticated ? "● Game Center: \(gcName)" : "○ Game Center: Offline"
        let gcLabel = SKLabelNode(text: gcDot)
        gcLabel.fontName = AppleDesign.mediumFont(size: 11)
        gcLabel.fontSize = 11
        gcLabel.fontColor = profile.isGameCenterAuthenticated ? AppleDesign.green : AppleDesign.secondaryLabel
        gcLabel.position = CGPoint(x: 0, y: cardH / 2 - 130)
        leftCard.addChild(gcLabel)
        
        // Rank Badge
        let level = max(1, profile.coinsTotal / 50 + 1)
        let rankLabel = SKLabelNode(text: "🌟 Rank: Level \(level) Groove Master")
        rankLabel.fontName = AppleDesign.boldFont(size: 11)
        rankLabel.fontSize = 11
        rankLabel.fontColor = AppleDesign.pink
        rankLabel.position = CGPoint(x: 0, y: cardH / 2 - 154)
        leftCard.addChild(rankLabel)
        
        // Logout / Switch User Button (Destructive Apple Style)
        let logoutBtn = buildButton(
            name: "profileLogoutBtn",
            text: GameConstants.UIStrings.logoutButton,
            size: CGSize(width: cardW - 40, height: 34),
            fillColor: UIColor(red: 0.35, green: 0.08, blue: 0.10, alpha: 0.9),
            textColor: AppleDesign.red,
            strokeColor: AppleDesign.red.withAlphaComponent(0.6)
        )
        logoutBtn.position = CGPoint(x: 0, y: -cardH / 2 + 28)
        leftCard.addChild(logoutBtn)
        
        // --- RIGHT CARD: Career Statistics ---
        let rightCard = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 22)
        rightCard.position = CGPoint(x: rightCenterX, y: cardY)
        rightCard.fillColor = AppleDesign.glassCard
        rightCard.strokeColor = AppleDesign.glassBorder
        rightCard.lineWidth = 1.0
        profileLayer.addChild(rightCard)
        
        let statsHeader = SKLabelNode(text: GameConstants.UIStrings.careerPerformance)
        statsHeader.fontName = AppleDesign.boldFont(size: 10)
        statsHeader.fontSize = 10
        statsHeader.fontColor = AppleDesign.secondaryLabel
        statsHeader.position = CGPoint(x: 0, y: cardH / 2 - 26)
        rightCard.addChild(statsHeader)
        
        // 4 Stat Tiles in 2x2 grid
        let tileW: CGFloat = (cardW - 44) / 2
        let tileH: CGFloat = 56
        let tileOffsetX = tileW / 2 + 6
        
        let statTiles = [
            ("BEST SCORE", "\(profile.bestScore)", AppleDesign.gold),
            ("ACCURACY", String(format: "%.1f%%", profile.accuracyPercentage), AppleDesign.green),
            ("NOTES HIT", "\(profile.totalNotesHit)", AppleDesign.cyan),
            ("GROOVE COINS", "\(profile.coinsTotal)", AppleDesign.gold)
        ]
        
        let positions = [
            CGPoint(x: -tileOffsetX, y: cardH / 2 - 72),
            CGPoint(x: tileOffsetX, y: cardH / 2 - 72),
            CGPoint(x: -tileOffsetX, y: cardH / 2 - 138),
            CGPoint(x: tileOffsetX, y: cardH / 2 - 138)
        ]
        
        for (idx, tileData) in statTiles.enumerated() {
            let pos = positions[idx]
            let tile = SKShapeNode(rectOf: CGSize(width: tileW, height: tileH), cornerRadius: 14)
            tile.position = pos
            tile.fillColor = UIColor(white: 0.14, alpha: 0.6)
            tile.strokeColor = AppleDesign.glassBorder
            tile.lineWidth = 1.0
            rightCard.addChild(tile)
            
            let lblTitle = SKLabelNode(text: tileData.0)
            lblTitle.fontName = AppleDesign.boldFont(size: 9.5)
            lblTitle.fontSize = 9.5
            lblTitle.fontColor = AppleDesign.secondaryLabel
            lblTitle.position = CGPoint(x: 0, y: 10)
            tile.addChild(lblTitle)
            
            let lblVal = SKLabelNode(text: tileData.1)
            lblVal.fontName = AppleDesign.heavyFont(size: 18)
            lblVal.fontSize = 18
            lblVal.fontColor = tileData.2
            lblVal.position = CGPoint(x: 0, y: -14)
            tile.addChild(lblVal)
        }
        
        // Footer stats summary
        let footerStats = SKLabelNode(text: "🎵 Songs: \(profile.totalSongsPlayed)   •   ❌ Misses: \(profile.totalNotesMissed)   •   💃 Dancers: \(profile.unlockedCharacterCount)/\(profile.availableCharacters.count)")
        footerStats.fontName = AppleDesign.mediumFont(size: 10)
        footerStats.fontSize = 10
        footerStats.fontColor = AppleDesign.secondaryLabel
        footerStats.position = CGPoint(x: 0, y: -cardH / 2 + 24)
        rightCard.addChild(footerStats)
    }
    
    // MARK: - 4c. Settings & Preferences Screen
    
    private func rebuildSettingsScreen() {
        settingsLayer.removeAllChildren()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let profile = PlayerProfile.shared
        
        // 1. Background Dimming
        let bg = SKShapeNode(rectOf: size)
        bg.position = center
        bg.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.65)
        bg.strokeColor = .clear
        settingsLayer.addChild(bg)
        
        // 2. Top Header
        let titleLabel = SKLabelNode(text: GameConstants.UIStrings.settings)
        titleLabel.fontName = AppleDesign.heavyFont(size: 22)
        titleLabel.fontSize = 22
        titleLabel.fontColor = AppleDesign.label
        titleLabel.position = CGPoint(x: center.x, y: size.height - 38)
        settingsLayer.addChild(titleLabel)
        
        let backBtn = buildButton(
            name: "settingsBackBtn",
            text: GameConstants.UIStrings.menuButton,
            size: CGSize(width: 95, height: 34),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        backBtn.position = CGPoint(x: 65, y: size.height - 38)
        settingsLayer.addChild(backBtn)
        
        // 3. Two Apple Glass Cards Side-by-Side
        let cardW: CGFloat = min(size.width * 0.44, 370)
        let cardH: CGFloat = min(size.height * 0.68, 255)
        let leftCenterX = center.x - cardW / 2 - 12
        let rightCenterX = center.x + cardW / 2 + 12
        let cardY = center.y - 12
        
        let btnInnerW = cardW - 36
        let btnInnerH: CGFloat = 36
        let startOptionY = cardH / 2 - 60
        
        // --- LEFT CARD: Audio & Gameplay Settings ---
        let leftCard = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 22)
        leftCard.position = CGPoint(x: leftCenterX, y: cardY)
        leftCard.fillColor = AppleDesign.glassCard
        leftCard.strokeColor = AppleDesign.glassBorder
        leftCard.lineWidth = 1.0
        settingsLayer.addChild(leftCard)
        
        let audioHeader = SKLabelNode(text: GameConstants.UIStrings.audioHaptics)
        audioHeader.fontName = AppleDesign.boldFont(size: 10)
        audioHeader.fontSize = 10
        audioHeader.fontColor = AppleDesign.secondaryLabel
        audioHeader.position = CGPoint(x: 0, y: cardH / 2 - 26)
        leftCard.addChild(audioHeader)
        
        // 1. Music Volume Button
        let musicPct = Int(profile.musicVolume * 100)
        let musicBtn = buildButton(
            name: "settingsMusicBtn",
            text: "🎵  MUSIC VOLUME: \(musicPct)%",
            size: CGSize(width: btnInnerW, height: btnInnerH),
            fillColor: UIColor(white: 0.14, alpha: 0.7),
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.cyan.withAlphaComponent(0.4)
        )
        musicBtn.position = CGPoint(x: 0, y: startOptionY)
        leftCard.addChild(musicBtn)
        
        // 2. SFX Volume Button
        let sfxPct = Int(profile.sfxVolume * 100)
        let sfxBtn = buildButton(
            name: "settingsSFXBtn",
            text: "🔊  SOUND EFFECTS: \(sfxPct)%",
            size: CGSize(width: btnInnerW, height: btnInnerH),
            fillColor: UIColor(white: 0.14, alpha: 0.7),
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.green.withAlphaComponent(0.4)
        )
        sfxBtn.position = CGPoint(x: 0, y: startOptionY - 44)
        leftCard.addChild(sfxBtn)
        
        // 3. Haptics Button
        let hapticText = profile.isHapticsEnabled ? "📳  HAPTICS: ENABLED" : "📳  HAPTICS: MUTED"
        let hapticColor = profile.isHapticsEnabled ? AppleDesign.green : AppleDesign.secondaryLabel
        let hapticBtn = buildButton(
            name: "settingsHapticsBtn",
            text: hapticText,
            size: CGSize(width: btnInnerW, height: btnInnerH),
            fillColor: UIColor(white: 0.14, alpha: 0.7),
            textColor: AppleDesign.label,
            strokeColor: hapticColor.withAlphaComponent(0.4)
        )
        hapticBtn.position = CGPoint(x: 0, y: startOptionY - 88)
        leftCard.addChild(hapticBtn)
        
        // 4. Difficulty Selector
        let diffColor = (profile.selectedDifficulty == .hard) ? AppleDesign.pink :
                        (profile.selectedDifficulty == .easy) ? AppleDesign.green : AppleDesign.cyan
        let diffBtn = buildButton(
            name: "settingsDiffBtn",
            text: "🎯  DIFFICULTY: \(profile.selectedDifficulty.rawValue.uppercased())",
            size: CGSize(width: btnInnerW, height: btnInnerH),
            fillColor: UIColor(white: 0.14, alpha: 0.7),
            textColor: diffColor,
            strokeColor: diffColor.withAlphaComponent(0.4)
        )
        diffBtn.position = CGPoint(x: 0, y: startOptionY - 132)
        leftCard.addChild(diffBtn)
        
        // --- RIGHT CARD: Legal & Account ---
        let rightCard = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 22)
        rightCard.position = CGPoint(x: rightCenterX, y: cardY)
        rightCard.fillColor = AppleDesign.glassCard
        rightCard.strokeColor = AppleDesign.glassBorder
        rightCard.lineWidth = 1.0
        settingsLayer.addChild(rightCard)
        
        let legalHeader = SKLabelNode(text: GameConstants.UIStrings.legalAbout)
        legalHeader.fontName = AppleDesign.boldFont(size: 10)
        legalHeader.fontSize = 10
        legalHeader.fontColor = AppleDesign.secondaryLabel
        legalHeader.position = CGPoint(x: 0, y: cardH / 2 - 26)
        rightCard.addChild(legalHeader)
        
        // 1. Terms of Service Button
        let termsBtn = buildButton(
            name: "settingsTermsBtn",
            text: GameConstants.UIStrings.termsButton,
            size: CGSize(width: btnInnerW, height: btnInnerH),
            fillColor: UIColor(white: 0.14, alpha: 0.7),
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        termsBtn.position = CGPoint(x: 0, y: startOptionY)
        rightCard.addChild(termsBtn)
        
        // 2. Privacy Policy Button
        let privacyBtn = buildButton(
            name: "settingsPrivacyBtn",
            text: GameConstants.UIStrings.privacyButton,
            size: CGSize(width: btnInnerW, height: btnInnerH),
            fillColor: UIColor(white: 0.14, alpha: 0.7),
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        privacyBtn.position = CGPoint(x: 0, y: startOptionY - 44)
        rightCard.addChild(privacyBtn)
        
        // 3. Logout / Reset Button
        let logoutBtn = buildButton(
            name: "settingsLogoutBtn",
            text: GameConstants.UIStrings.resetSessionButton,
            size: CGSize(width: btnInnerW, height: btnInnerH),
            fillColor: UIColor(red: 0.35, green: 0.08, blue: 0.10, alpha: 0.9),
            textColor: AppleDesign.red,
            strokeColor: AppleDesign.red.withAlphaComponent(0.6)
        )
        logoutBtn.position = CGPoint(x: 0, y: startOptionY - 88)
        rightCard.addChild(logoutBtn)
        
        // 4. App Info & Version
        let appInfo = SKLabelNode(text: "Groove Games v1.0.0 • Boogie Down Games")
        appInfo.fontName = AppleDesign.mediumFont(size: 10)
        appInfo.fontSize = 10
        appInfo.fontColor = AppleDesign.secondaryLabel
        appInfo.position = CGPoint(x: 0, y: startOptionY - 130)
        rightCard.addChild(appInfo)
        
        let copyInfo = SKLabelNode(text: "Rai Enterprise • Apple Game Center & Sign In")
        copyInfo.fontName = AppleDesign.regularFont(size: 9)
        copyInfo.fontSize = 9
        copyInfo.fontColor = AppleDesign.secondaryLabel.withAlphaComponent(0.6)
        copyInfo.position = CGPoint(x: 0, y: startOptionY - 146)
        rightCard.addChild(copyInfo)
    }
    
    // MARK: - 4d. Terms of Service Screen
    
    private func rebuildTermsScreen() {
        termsLayer.removeAllChildren()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Dark backdrop
        let bg = SKShapeNode(rectOf: size)
        bg.position = center
        bg.fillColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.88)
        bg.strokeColor = .clear
        termsLayer.addChild(bg)
        
        // Apple Sheet Modal Container
        let modalW: CGFloat = min(size.width * 0.88, 720)
        let modalH: CGFloat = min(size.height * 0.88, 335)
        let modal = SKShapeNode(rectOf: CGSize(width: modalW, height: modalH), cornerRadius: 22)
        modal.position = center
        modal.fillColor = UIColor(red: 0.09, green: 0.09, blue: 0.13, alpha: 0.98)
        modal.strokeColor = AppleDesign.glassBorder
        modal.lineWidth = 1.0
        termsLayer.addChild(modal)
        
        // Header
        let titleLabel = SKLabelNode(text: GameConstants.UIStrings.termsOfServiceTitle)
        titleLabel.fontName = AppleDesign.heavyFont(size: 18)
        titleLabel.fontSize = 18
        titleLabel.fontColor = AppleDesign.cyan
        titleLabel.position = CGPoint(x: 0, y: modalH / 2 - 28)
        modal.addChild(titleLabel)
        
        let closeTopBtn = buildButton(
            name: "termsCloseBtn",
            text: GameConstants.UIStrings.closeButton,
            size: CGSize(width: 32, height: 32),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        closeTopBtn.position = CGPoint(x: modalW / 2 - 36, y: modalH / 2 - 28)
        modal.addChild(closeTopBtn)
        
        // 5 Sections Layout in 2 columns with generous non-overlapping spacing
        let colW = (modalW - 64) / 2
        let sections = PlayerProfile.termsOfService
        
        let leftColX: CGFloat = -modalW / 2 + 32
        let rightColX: CGFloat = 16
        let startY: CGFloat = modalH / 2 - 56
        
        for (i, sec) in sections.enumerated() {
            let isLeft = (i < 3)
            let colX = isLeft ? leftColX : rightColX
            let curY = isLeft ? (startY - CGFloat(i) * 74) : (startY - CGFloat(i - 3) * 88)
            
            let secTitle = SKLabelNode(text: sec.title)
            secTitle.horizontalAlignmentMode = .left
            secTitle.verticalAlignmentMode = .top
            secTitle.fontName = AppleDesign.boldFont(size: 11)
            secTitle.fontSize = 11
            secTitle.fontColor = AppleDesign.gold
            secTitle.position = CGPoint(x: colX, y: curY)
            modal.addChild(secTitle)
            
            let secBody = SKLabelNode(text: sec.body)
            secBody.numberOfLines = 3
            secBody.horizontalAlignmentMode = .left
            secBody.verticalAlignmentMode = .top
            secBody.preferredMaxLayoutWidth = colW - 12
            secBody.fontName = AppleDesign.regularFont(size: 9.5)
            secBody.fontSize = 9.5
            secBody.fontColor = AppleDesign.label.withAlphaComponent(0.85)
            secBody.position = CGPoint(x: colX, y: curY - 16)
            modal.addChild(secBody)
        }
        
        let acceptBtn = buildButton(
            name: "termsCloseBtn",
            text: GameConstants.UIStrings.agreeAndReturnButton,
            size: CGSize(width: 220, height: 36),
            fillColor: AppleDesign.cyan,
            textColor: UIColor(white: 0.05, alpha: 1.0),
            strokeColor: UIColor.white.withAlphaComponent(0.4)
        )
        acceptBtn.position = CGPoint(x: 0, y: -modalH / 2 + 28)
        modal.addChild(acceptBtn)
    }
    
    // MARK: - 4e. Privacy Policy Screen
    
    private func rebuildPrivacyScreen() {
        privacyLayer.removeAllChildren()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Dark backdrop
        let bg = SKShapeNode(rectOf: size)
        bg.position = center
        bg.fillColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.88)
        bg.strokeColor = .clear
        privacyLayer.addChild(bg)
        
        // Apple Sheet Modal Container
        let modalW: CGFloat = min(size.width * 0.88, 720)
        let modalH: CGFloat = min(size.height * 0.88, 335)
        let modal = SKShapeNode(rectOf: CGSize(width: modalW, height: modalH), cornerRadius: 22)
        modal.position = center
        modal.fillColor = UIColor(red: 0.09, green: 0.09, blue: 0.13, alpha: 0.98)
        modal.strokeColor = AppleDesign.glassBorder
        modal.lineWidth = 1.0
        privacyLayer.addChild(modal)
        
        // Header
        let titleLabel = SKLabelNode(text: GameConstants.UIStrings.privacyPolicyTitle)
        titleLabel.fontName = AppleDesign.heavyFont(size: 18)
        titleLabel.fontSize = 18
        titleLabel.fontColor = AppleDesign.green
        titleLabel.position = CGPoint(x: 0, y: modalH / 2 - 28)
        modal.addChild(titleLabel)
        
        let closeTopBtn = buildButton(
            name: "privacyCloseBtn",
            text: GameConstants.UIStrings.closeButton,
            size: CGSize(width: 32, height: 32),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        closeTopBtn.position = CGPoint(x: modalW / 2 - 36, y: modalH / 2 - 28)
        modal.addChild(closeTopBtn)
        
        // 5 Sections Layout in 2 columns with generous non-overlapping spacing
        let colW = (modalW - 64) / 2
        let sections = PlayerProfile.privacyPolicy
        
        let leftColX: CGFloat = -modalW / 2 + 32
        let rightColX: CGFloat = 16
        let startY: CGFloat = modalH / 2 - 56
        
        for (i, sec) in sections.enumerated() {
            let isLeft = (i < 3)
            let colX = isLeft ? leftColX : rightColX
            let curY = isLeft ? (startY - CGFloat(i) * 74) : (startY - CGFloat(i - 3) * 88)
            
            let secTitle = SKLabelNode(text: sec.title)
            secTitle.horizontalAlignmentMode = .left
            secTitle.verticalAlignmentMode = .top
            secTitle.fontName = AppleDesign.boldFont(size: 11)
            secTitle.fontSize = 11
            secTitle.fontColor = AppleDesign.green
            secTitle.position = CGPoint(x: colX, y: curY)
            modal.addChild(secTitle)
            
            let secBody = SKLabelNode(text: sec.body)
            secBody.numberOfLines = 3
            secBody.horizontalAlignmentMode = .left
            secBody.verticalAlignmentMode = .top
            secBody.preferredMaxLayoutWidth = colW - 12
            secBody.fontName = AppleDesign.regularFont(size: 9.5)
            secBody.fontSize = 9.5
            secBody.fontColor = AppleDesign.label.withAlphaComponent(0.85)
            secBody.position = CGPoint(x: colX, y: curY - 16)
            modal.addChild(secBody)
        }
        
        let acceptBtn = buildButton(
            name: "privacyCloseBtn",
            text: GameConstants.UIStrings.understoodAndReturnButton,
            size: CGSize(width: 230, height: 36),
            fillColor: AppleDesign.green,
            textColor: UIColor(white: 0.05, alpha: 1.0),
            strokeColor: UIColor.white.withAlphaComponent(0.4)
        )
        acceptBtn.position = CGPoint(x: 0, y: -modalH / 2 + 28)
        modal.addChild(acceptBtn)
    }
    
    // MARK: - 5. Gameplay HUD (Landscape Optimized)
    
    private func setupGameplayHUD() {
        // Top Left: Score
        let scoreTitle = SKLabelNode(text: GameConstants.UIStrings.scoreTitle)
        scoreTitle.fontName = AppleDesign.boldFont(size: 9)
        scoreTitle.fontSize = 9
        scoreTitle.fontColor = AppleDesign.secondaryLabel
        scoreTitle.horizontalAlignmentMode = .left
        scoreTitle.position = CGPoint(x: 35, y: -16)
        gameplayLayer.addChild(scoreTitle)
        
        scoreLabel.text = "000000"
        scoreLabel.fontName = AppleDesign.heavyFont(size: 24)
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = AppleDesign.label
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 35, y: -42)
        gameplayLayer.addChild(scoreLabel)
        
        bestScoreLabel.text = "BEST: 000000"
        bestScoreLabel.fontName = AppleDesign.semiboldFont(size: 10)
        bestScoreLabel.fontSize = 10
        bestScoreLabel.fontColor = AppleDesign.gold
        bestScoreLabel.horizontalAlignmentMode = .left
        bestScoreLabel.position = CGPoint(x: 35, y: -58)
        gameplayLayer.addChild(bestScoreLabel)
        
        // Top Center: Song Title & Progress
        songTitleBadge.text = "🎵 Alone Tonight"
        songTitleBadge.fontName = AppleDesign.boldFont(size: 12)
        songTitleBadge.fontSize = 12
        songTitleBadge.fontColor = AppleDesign.label
        songTitleBadge.horizontalAlignmentMode = .center
        gameplayLayer.addChild(songTitleBadge)
        
        songProgressTrack.strokeColor = .clear
        songProgressTrack.fillColor = UIColor(white: 0.22, alpha: 0.5)
        gameplayLayer.addChild(songProgressTrack)
        
        songProgressFill.strokeColor = .clear
        songProgressFill.fillColor = AppleDesign.cyan
        gameplayLayer.addChild(songProgressFill)
        
        // Top Right: Combo & Counters
        comboLabel.text = GameConstants.UIStrings.combo
        comboLabel.fontName = AppleDesign.boldFont(size: 8.5)
        comboLabel.fontSize = 8.5
        comboLabel.fontColor = AppleDesign.gold
        comboLabel.horizontalAlignmentMode = .right
        gameplayLayer.addChild(comboLabel)
        
        comboCountLabel.text = "0"
        comboCountLabel.fontName = AppleDesign.heavyFont(size: 24)
        comboCountLabel.fontSize = 24
        comboCountLabel.fontColor = AppleDesign.gold
        comboCountLabel.horizontalAlignmentMode = .right
        gameplayLayer.addChild(comboCountLabel)
        
        hitsLabel.text = "HITS: 0"
        hitsLabel.fontName = AppleDesign.boldFont(size: 10.5)
        hitsLabel.fontSize = 10.5
        hitsLabel.fontColor = AppleDesign.green
        hitsLabel.horizontalAlignmentMode = .right
        gameplayLayer.addChild(hitsLabel)
        
        missLabel.text = "MISS: 0"
        missLabel.fontName = AppleDesign.boldFont(size: 10.5)
        missLabel.fontSize = 10.5
        missLabel.fontColor = AppleDesign.red
        missLabel.horizontalAlignmentMode = .right
        gameplayLayer.addChild(missLabel)
        
        // Pause Button (Top Right Corner)
        let pauseBtn = buildCapsule(
            size: CGSize(width: 36, height: 36),
            fillColor: AppleDesign.glassCard,
            strokeColor: AppleDesign.glassBorder
        )
        pauseBtn.name = "hudPauseBtn"
        pauseBtn.position = CGPoint(x: -60, y: -36)
        gameplayLayer.addChild(pauseBtn)
        
        let pauseIcon = SKLabelNode(text: "⏸")
        pauseIcon.name = "hudPauseBtn"
        pauseIcon.fontSize = 14
        pauseIcon.fontColor = AppleDesign.label
        pauseIcon.verticalAlignmentMode = .center
        pauseBtn.addChild(pauseIcon)
        
        // Bottom: Groove Energy / Fever Meter
        energyTitleLabel.text = GameConstants.UIStrings.grooveGauge
        energyTitleLabel.fontName = AppleDesign.boldFont(size: 9.5)
        energyTitleLabel.fontSize = 9.5
        energyTitleLabel.fontColor = AppleDesign.pink
        energyTitleLabel.horizontalAlignmentMode = .left
        gameplayLayer.addChild(energyTitleLabel)
        
        energyTrackNode.strokeColor = AppleDesign.glassBorder
        energyTrackNode.fillColor = UIColor(white: 0.12, alpha: 0.6)
        energyTrackNode.lineWidth = 1
        gameplayLayer.addChild(energyTrackNode)
        
        energyFillNode.strokeColor = .clear
        energyFillNode.fillColor = AppleDesign.pink
        gameplayLayer.addChild(energyFillNode)
    }
    
    private func layoutGameplayHUD() {
        let topY = size.height - 20
        
        // Top Left Score
        scoreLabel.position = CGPoint(x: 35, y: topY - 26)
        bestScoreLabel.position = CGPoint(x: 35, y: topY - 44)
        bestScoreLabel.text = "BEST: \(String(format: "%06d", PlayerProfile.shared.bestScore))"
        
        // Top Center Song & Bar
        let barW: CGFloat = min(size.width * 0.32, 260)
        songTitleBadge.position = CGPoint(x: size.width / 2, y: topY - 12)
        songTitleBadge.text = "🎵 \(PlayerProfile.shared.currentSong.title)"
        
        let barRect = CGRect(x: size.width / 2 - barW / 2, y: topY - 24, width: barW, height: 4)
        songProgressTrack.path = CGPath(roundedRect: barRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
        updateSongProgress(percentage: 0.0)
        
        // Top Right Pause & Stats (Generously spaced)
        if let pauseBtn = gameplayLayer.childNode(withName: "hudPauseBtn") {
            pauseBtn.position = CGPoint(x: size.width - 42, y: topY - 16)
        }
        
        comboCountLabel.position = CGPoint(x: size.width - 86, y: topY - 14)
        comboLabel.position = CGPoint(x: size.width - 86, y: topY - 28)
        
        hitsLabel.position = CGPoint(x: size.width - 152, y: topY - 12)
        missLabel.position = CGPoint(x: size.width - 152, y: topY - 26)
        
        // Bottom Left Energy Gauge
        let meterW: CGFloat = min(size.width * 0.28, 200)
        let meterH: CGFloat = 7
        energyTitleLabel.position = CGPoint(x: 35, y: 30)
        let meterRect = CGRect(x: 35, y: 16, width: meterW, height: meterH)
        energyTrackNode.path = CGPath(roundedRect: meterRect, cornerWidth: 3.5, cornerHeight: 3.5, transform: nil)
        updateEnergyMeter(percentage: energyPercent)
    }
    
    // MARK: - 6. Pause Screen
    
    private func rebuildPauseScreen() {
        pauseLayer.removeAllChildren()
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        let bg = SKShapeNode(rectOf: size)
        bg.position = center
        bg.fillColor = UIColor(white: 0.04, alpha: 0.72)
        bg.strokeColor = .clear
        pauseLayer.addChild(bg)
        
        let cardW: CGFloat = min(size.width * 0.45, 330)
        let cardH: CGFloat = min(size.height * 0.72, 245)
        let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 22)
        card.position = center
        card.fillColor = AppleDesign.glassCard
        card.strokeColor = AppleDesign.glassBorder
        card.lineWidth = 1.0
        pauseLayer.addChild(card)
        
        let title = SKLabelNode(text: GameConstants.UIStrings.gamePaused)
        title.fontName = AppleDesign.heavyFont(size: 20)
        title.fontSize = 20
        title.fontColor = AppleDesign.label
        title.position = CGPoint(x: 0, y: cardH / 2 - 36)
        card.addChild(title)
        
        let resumeBtn = buildButton(
            name: "pauseResumeBtn",
            text: GameConstants.UIStrings.resumeButton,
            size: CGSize(width: 220, height: 38),
            fillColor: AppleDesign.cyan,
            textColor: UIColor(white: 0.05, alpha: 1.0),
            strokeColor: UIColor.white.withAlphaComponent(0.4)
        )
        resumeBtn.position = CGPoint(x: 0, y: 22)
        card.addChild(resumeBtn)
        
        let restartBtn = buildButton(
            name: "pauseRestartBtn",
            text: GameConstants.UIStrings.restartButton,
            size: CGSize(width: 220, height: 36),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        restartBtn.position = CGPoint(x: 0, y: -24)
        card.addChild(restartBtn)
        
        let menuBtn = buildButton(
            name: "pauseMenuBtn",
            text: GameConstants.UIStrings.mainMenuButton,
            size: CGSize(width: 220, height: 36),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        menuBtn.position = CGPoint(x: 0, y: -68)
        card.addChild(menuBtn)
    }
    
    // MARK: - 7. Results / Game Over Screen (Ported from GameOverCtrl.cs)
    
    public func showGameOver(score: Int, hits: Int, misses: Int, maxCombo: Int, isWon: Bool) {
        resultsLayer.removeAllChildren()
        setScreenState(.results)
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let profile = PlayerProfile.shared
        
        let coinsEarned = isWon ? 35 : 10
        profile.recordGameCompleted(score: score, hits: hits, misses: misses, coins: coinsEarned)
        
        let bg = SKShapeNode(rectOf: size)
        bg.position = center
        bg.fillColor = UIColor(white: 0.04, alpha: 0.75)
        bg.strokeColor = .clear
        resultsLayer.addChild(bg)
        
        let cardW: CGFloat = min(size.width * 0.76, 520)
        let cardH: CGFloat = min(size.height * 0.82, 290)
        let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 24)
        card.position = center
        card.fillColor = AppleDesign.glassCard
        card.strokeColor = isWon ? AppleDesign.gold.withAlphaComponent(0.6) : AppleDesign.glassBorder
        card.lineWidth = 1.0
        resultsLayer.addChild(card)
        
        // Header
        let title = SKLabelNode(text: isWon ? GameConstants.UIStrings.grooveCompleted : GameConstants.UIStrings.niceTry)
        title.fontName = AppleDesign.heavyFont(size: 16)
        title.fontSize = 16
        title.fontColor = isWon ? AppleDesign.gold : AppleDesign.label
        title.position = CGPoint(x: 0, y: cardH / 2 - 32)
        card.addChild(title)
        
        // Left Column: Big Final Score & Rank
        let total = hits + misses
        let accuracy = total > 0 ? Int((Double(hits) / Double(total)) * 100) : 0
        let letterRank = (accuracy >= 95) ? "S" : (accuracy >= 85) ? "A" : (accuracy >= 70) ? "B" : "C"
        
        let rankBadge = buildCapsule(
            size: CGSize(width: 76, height: 76),
            fillColor: UIColor(white: 0.14, alpha: 0.7),
            strokeColor: AppleDesign.gold.withAlphaComponent(0.6)
        )
        rankBadge.position = CGPoint(x: -cardW * 0.3, y: 15)
        card.addChild(rankBadge)
        
        let rankLabel = SKLabelNode(text: letterRank)
        rankLabel.fontName = AppleDesign.heavyFont(size: 38)
        rankLabel.fontSize = 38
        rankLabel.fontColor = AppleDesign.gold
        rankLabel.verticalAlignmentMode = .center
        rankBadge.addChild(rankLabel)
        
        let scoreLabelResult = SKLabelNode(text: "\(score)")
        scoreLabelResult.fontName = AppleDesign.heavyFont(size: 32)
        scoreLabelResult.fontSize = 32
        scoreLabelResult.fontColor = AppleDesign.label
        scoreLabelResult.position = CGPoint(x: 40, y: 38)
        card.addChild(scoreLabelResult)
        
        let scoreSub = SKLabelNode(text: "\(GameConstants.UIStrings.finalScore)  •  \(accuracy)% ACCURACY")
        scoreSub.fontName = AppleDesign.boldFont(size: 11)
        scoreSub.fontSize = 11
        scoreSub.fontColor = AppleDesign.cyan
        scoreSub.position = CGPoint(x: 40, y: 18)
        card.addChild(scoreSub)
        
        // Stats summary row
        let statsRow = SKLabelNode(text: "Hits: \(hits)   •   Misses: \(misses)   •   Max Combo: \(maxCombo)   •   +💰 \(coinsEarned) Coins")
        statsRow.fontName = AppleDesign.mediumFont(size: 12)
        statsRow.fontSize = 12
        statsRow.fontColor = AppleDesign.secondaryLabel
        statsRow.position = CGPoint(x: 40, y: -10)
        card.addChild(statsRow)
        
        // Bottom Action Buttons
        let playAgainBtn = buildButton(
            name: "resultPlayAgainBtn",
            text: GameConstants.UIStrings.playAgainButton,
            size: CGSize(width: 170, height: 38),
            fillColor: AppleDesign.cyan,
            textColor: UIColor(white: 0.05, alpha: 1.0),
            strokeColor: UIColor.white.withAlphaComponent(0.4)
        )
        playAgainBtn.position = CGPoint(x: -95, y: -cardH / 2 + 36)
        card.addChild(playAgainBtn)
        
        let mainMenuBtn = buildButton(
            name: "resultMainMenuBtn",
            text: GameConstants.UIStrings.mainMenuButton,
            size: CGSize(width: 170, height: 38),
            fillColor: AppleDesign.glassCard,
            textColor: AppleDesign.label,
            strokeColor: AppleDesign.glassBorder
        )
        mainMenuBtn.position = CGPoint(x: 95, y: -cardH / 2 + 36)
        card.addChild(mainMenuBtn)
        
        resultsLayer.alpha = 0
        resultsLayer.run(SKAction.fadeIn(withDuration: 0.25))
    }
    
    // MARK: - Real-Time HUD Updates
    
    public func updateScore(_ newScore: Int) {
        targetScore = newScore
        let incrementAction = SKAction.customAction(withDuration: 0.25) { [weak self] _, elapsedTime in
            guard let self = self else { return }
            let progress = elapsedTime / 0.25
            let current = Int(Double(self.displayedScore) + Double(self.targetScore - self.displayedScore) * Double(progress))
            self.scoreLabel.text = String(format: "%06d", current)
        }
        scoreLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.12)
        ]))
        scoreLabel.run(incrementAction) { [weak self] in
            guard let self = self else { return }
            self.displayedScore = self.targetScore
            self.scoreLabel.text = String(format: "%06d", self.targetScore)
        }
    }
    
    public func updateCombo(_ combo: Int) {
        comboCountLabel.text = "\(combo)"
        if combo > 0 {
            if combo >= 20 {
                comboCountLabel.fontColor = UIColor(red: 1.0, green: 0.25, blue: 0.9, alpha: 1.0)
                comboLabel.text = GameConstants.UIStrings.feverCombo
            } else if combo >= 10 {
                comboCountLabel.fontColor = UIColor(red: 1.0, green: 0.8, blue: 0.1, alpha: 1.0)
                comboLabel.text = GameConstants.UIStrings.starCombo
            } else {
                comboCountLabel.fontColor = UIColor(red: 0.3, green: 0.85, blue: 1.0, alpha: 1.0)
                comboLabel.text = GameConstants.UIStrings.combo
            }
            comboCountLabel.run(SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.06),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
        } else {
            comboLabel.text = GameConstants.UIStrings.combo
            comboCountLabel.fontColor = UIColor(white: 0.6, alpha: 0.8)
        }
    }
    
    public func updateCounters(hits: Int, misses: Int) {
        hitsLabel.text = "HITS: \(hits)"
        missLabel.text = "MISS: \(misses)"
    }
    
    public func updateEnergyMeter(percentage: CGFloat) {
        energyPercent = min(max(percentage, 0.0), 1.0)
        let meterW: CGFloat = min(size.width * 0.28, 200)
        let meterH: CGFloat = 8
        let fillW = max(meterW * energyPercent, 0.0)
        let fillRect = CGRect(x: 35, y: 16, width: fillW, height: meterH)
        energyFillNode.path = CGPath(roundedRect: fillRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        
        if energyPercent >= 1.0 {
            energyFillNode.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        } else {
            energyFillNode.fillColor = UIColor(red: 1.0, green: 0.25, blue: 0.85, alpha: 1.0)
        }
    }
    
    public func updateSongProgress(percentage: CGFloat) {
        let topY = size.height - 20
        let barW: CGFloat = min(size.width * 0.34, 280)
        let currentW = barW * min(max(percentage, 0.0), 1.0)
        let fillRect = CGRect(x: size.width / 2 - barW / 2, y: topY - 26, width: currentW, height: 5)
        songProgressFill.path = CGPath(roundedRect: fillRect, cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)
    }
    
    public func showJudgment(text: String, scoreEarned: Int, color: UIColor, at point: CGPoint? = nil) {
        let spawnPos = point ?? CGPoint(x: size.width / 2, y: size.height * 0.45)
        let label = SKLabelNode(text: scoreEarned > 0 ? "\(text) +\(scoreEarned)" : text)
        label.fontName = AppleDesign.heavyFont(size: (text == "PERFECT") ? 28 : 22)
        label.fontSize = (text == "PERFECT") ? 28 : 22
        label.fontColor = color
        label.position = spawnPos
        label.zPosition = 100
        label.xScale = 0.5
        label.yScale = 0.5
        label.alpha = 0.0
        feedbackLayer.addChild(label)
        
        let seq = SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.08),
                SKAction.scale(to: 1.25, duration: 0.12)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 40, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.22),
                SKAction.scale(to: 1.0, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        label.run(seq)
    }
    
    // MARK: - Touch Interaction & Button Dispatch
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        // 1. Gameplay Mode Tap Handling: responsive zero-latency hit testing
        if currentScreenState == .playing {
            for node in touchedNodes {
                if node.name == "hudPauseBtn" || node.parent?.name == "hudPauseBtn" {
                    setScreenState(.paused)
                    hudDelegate?.hudDidRequestPause()
                    return
                }
            }
            // Active rhythm tap on playfield -> forward to 3D raycast hit-testing & scoring
            let viewPoint = self.view != nil ? touch.location(in: self.view) : location
            hudDelegate?.hudDidTapPlayfield(at: viewPoint)
            return
        }
        
        // Menu debounce: prevents accidental double-tap on UI buttons & transitions
        let now = CACurrentMediaTime()
        guard now - lastTouchTime >= 0.12 else { return }
        guard now - lastScreenTransitionTime >= 0.20 else { return }
        lastTouchTime = now
        
        // 2. Splash Screen Tap -> Check Apple Login / Game Center or transition to Main Menu
        if currentScreenState == .splash {
            for node in touchedNodes {
                if node.name == "splashAppleLoginBtn" || node.parent?.name == "splashAppleLoginBtn" {
                    onAppleLoginRequested?()
                    hudDelegate?.hudDidRequestAppleLogin()
                    return
                }
                if node.name == "splashGameCenterBtn" || node.parent?.name == "splashGameCenterBtn" {
                    onGameCenterRequested?()
                    hudDelegate?.hudDidRequestGameCenter()
                    return
                }
            }
            
            // Require authentication before entering Main Menu
            let profile = PlayerProfile.shared
            if profile.isAppleLoggedIn || profile.isGameCenterLoggedIn {
                setScreenState(.mainMenu)
            } else {
                showLoginRequiredPrompt()
            }
            return
        }
        
        // 2. Button dispatch across screens
        for node in touchedNodes {
            guard let name = node.name else { continue }
            
            switch name {
            // Main Menu Buttons
            case "menuPlayBtn":
                hudDelegate?.hudDidRequestStartGame()
                return
            case "menuSongBtn":
                setScreenState(.songSelect)
                return
            case "menuCharBtn":
                setScreenState(.characterSelect)
                return
            case "menuProfileBtn":
                setScreenState(.profile)
                return
            case "menuSettingsBtn":
                setScreenState(.settings)
                return
            case "menuDiffBtn":
                cycleDifficulty()
                return
            case "menuTutBtn":
                setScreenState(.tutorial)
                return
                
            // Profile Screen Buttons
            case "profileBackBtn":
                setScreenState(.mainMenu)
                return
            case "profileSettingsBtn":
                setScreenState(.settings)
                return
            case "profileLogoutBtn":
                PlayerProfile.shared.logout()
                showJudgment(text: GameConstants.Judgments.loggedOut, scoreEarned: 0, color: GameConstants.Palette.warningRed)
                setScreenState(.splash)
                return
                
            // Settings Screen Buttons
            case "settingsBackBtn":
                setScreenState(.mainMenu)
                return
            case "settingsMusicBtn":
                _ = PlayerProfile.shared.cycleMusicVolume()
                DanceGameManager.shared.applyAudioSettings()
                rebuildCurrentScreen()
                return
            case "settingsSFXBtn":
                _ = PlayerProfile.shared.cycleSFXVolume()
                DanceGameManager.shared.applyAudioSettings()
                DanceGameManager.shared.playSFX(GameConstants.Audio.sfxGood1)
                rebuildCurrentScreen()
                return
            case "settingsHapticsBtn":
                let enabled = PlayerProfile.shared.toggleHaptics()
                if enabled {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                }
                rebuildCurrentScreen()
                return
            case "settingsDiffBtn":
                cycleDifficulty()
                rebuildCurrentScreen()
                return
            case "settingsTermsBtn":
                setScreenState(.termsOfService)
                return
            case "settingsPrivacyBtn":
                setScreenState(.privacyPolicy)
                return
            case "settingsLogoutBtn":
                PlayerProfile.shared.logout()
                showJudgment(text: GameConstants.Judgments.loggedOut, scoreEarned: 0, color: GameConstants.Palette.warningRed)
                setScreenState(.splash)
                return
                
            // Legal Modals Close
            case "termsCloseBtn":
                setScreenState(.settings)
                return
            case "privacyCloseBtn":
                setScreenState(.settings)
                return
                
            // Song Select Buttons
            case _ where name.starts(with: "songCard_"):
                if let idxStr = name.split(separator: "_").last, let idx = Int(idxStr) {
                    PlayerProfile.shared.selectSong(at: idx)
                    hudDelegate?.hudDidSelectSong(index: idx)
                    rebuildCurrentScreen()
                }
                return
            case "songBackBtn":
                setScreenState(.mainMenu)
                return
            case "songConfirmBtn":
                hudDelegate?.hudDidRequestStartGame()
                return
                
            // Character Select Buttons
            case _ where name.starts(with: "charCard_"):
                if let idxStr = name.split(separator: "_").last, let idx = Int(idxStr) {
                    let profile = PlayerProfile.shared
                    if profile.isCharacterUnlocked(at: idx) {
                        profile.selectCharacter(at: idx)
                        hudDelegate?.hudDidSelectCharacter(index: idx)
                        rebuildCurrentScreen()
                    } else {
                        let char = profile.availableCharacters[idx]
                        if profile.unlockCharacter(at: idx) {
                            hudDelegate?.hudDidSelectCharacter(index: idx)
                            showJudgment(text: GameConstants.Judgments.unlockedCharacter(char.name), scoreEarned: 0, color: GameConstants.Palette.successGreenColor)
                            rebuildCurrentScreen()
                        } else {
                            let needed = char.unlockCost - profile.coinsTotal
                            showJudgment(text: GameConstants.Judgments.needMoreCoins(needed), scoreEarned: 0, color: GameConstants.Palette.warningRed)
                        }
                    }
                }
                return
            case "charBackBtn":
                setScreenState(.mainMenu)
                return
            case "charConfirmBtn":
                setScreenState(.mainMenu)
                return
                
            // Tutorial Buttons
            case "tutGotItBtn":
                setScreenState(.mainMenu)
                return
                
            // Gameplay Pause Button
            case "hudPauseBtn":
                setScreenState(.paused)
                hudDelegate?.hudDidRequestPause()
                return
                
            // Pause Screen Buttons
            case "pauseResumeBtn":
                setScreenState(.playing)
                hudDelegate?.hudDidRequestResume()
                return
            case "pauseRestartBtn":
                hudDelegate?.hudDidRequestRestart()
                return
            case "pauseMenuBtn":
                setScreenState(.mainMenu)
                hudDelegate?.hudDidRequestMainMenu()
                return
                
            // Result Screen Buttons
            case "resultPlayAgainBtn":
                hudDelegate?.hudDidRequestRestart()
                return
            case "resultMainMenuBtn":
                setScreenState(.mainMenu)
                hudDelegate?.hudDidRequestMainMenu()
                return
                
            default:
                break
            }
        }
    }
    
    private func cycleDifficulty() {
        let profile = PlayerProfile.shared
        switch profile.selectedDifficulty {
        case .easy:
            profile.selectedDifficulty = .normal
        case .normal:
            profile.selectedDifficulty = .hard
        case .hard:
            profile.selectedDifficulty = .easy
        }
        profile.save()
        hudDelegate?.hudDidChangeDifficulty(profile.selectedDifficulty)
        rebuildCurrentScreen()
    }
    
    // MARK: - UI Node Builders
    
    private func buildButton(name: String, text: String, size: CGSize, fillColor: UIColor, textColor: UIColor, strokeColor: UIColor? = nil) -> SKShapeNode {
        let cornerRadius: CGFloat = min(22, size.height / 2)
        let btn = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        btn.name = name
        btn.fillColor = fillColor
        btn.strokeColor = strokeColor ?? AppleDesign.glassBorder
        btn.lineWidth = 1.0
        
        let label = SKLabelNode(text: text)
        label.name = name
        label.fontName = AppleDesign.semiboldFont(size: size.height >= 40 ? 14 : 12)
        label.fontSize = size.height >= 40 ? 14 : 12
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        btn.addChild(label)
        return btn
    }
    
    private func buildCapsule(size: CGSize, fillColor: UIColor, strokeColor: UIColor) -> SKShapeNode {
        let cornerRadius: CGFloat = min(22, size.height / 2)
        let node = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        node.fillColor = fillColor
        node.strokeColor = strokeColor
        node.lineWidth = 1.0
        return node
    }
}
