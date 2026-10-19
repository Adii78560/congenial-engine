//
//  PlayerProfile.swift
//  GrooveGames
//
//  Ported from Player.cs
//  Manages persistent player stats, unlockables, and preferences.
//

import Foundation

public struct SongData: Equatable {
    public let id: String
    public let title: String
    public let artist: String
    public let duration: String
    public let bpm: Int
    public let difficultyStars: Int
    public let audioFileName: String
    public let isPaid: Bool
}

public struct CharacterData: Equatable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let genre: String
    public let modelFileName: String
    public let unlockCost: Int
}

public enum GameDifficulty: String, CaseIterable {
    case easy = "EASY"
    case normal = "NORMAL"
    case hard = "HARD"
    
    public var speedMultiplier: Float {
        switch self {
        case .easy: return 0.8
        case .normal: return 1.0
        case .hard: return 1.3
        }
    }
    
    public var spawnIntervalMultiplier: Double {
        switch self {
        case .easy: return 1.3
        case .normal: return 1.0
        case .hard: return 0.75
        }
    }
}

public class PlayerProfile {
    public static let shared = PlayerProfile()
    
    // MARK: - Available Songs Catalog (Ported from TextMachine.cs)
    public let availableSongs: [SongData] = [
        SongData(id: "AloneTonight", title: "Alone Tonight", artist: "Sky Girlz", duration: "1:00", bpm: 124, difficultyStars: 3, audioFileName: "AloneTonight", isPaid: false),
        SongData(id: "JapanJapan", title: "Japan, Japan", artist: "Sky Girlz", duration: "1:21", bpm: 128, difficultyStars: 4, audioFileName: "JapanJapan", isPaid: false),
        SongData(id: "SheSaid", title: "She Said", artist: "Sky Girlz", duration: "1:15", bpm: 120, difficultyStars: 2, audioFileName: "SheSaid", isPaid: false)
    ]
    
    // MARK: - Available Characters Catalog (Ported from CharacterController.cs)
    public let availableCharacters: [CharacterData] = [
        CharacterData(id: "blue", name: "Blue", subtitle: "Neon DJ", genre: "EDM & House", modelFileName: "Dancer", unlockCost: 0),
        CharacterData(id: "alexis", name: "Alexis", subtitle: "Hip-Hop Diva", genre: "Urban & Trap", modelFileName: "Alexis", unlockCost: 0),
        CharacterData(id: "mia", name: "Mia", subtitle: "Pop Superstar", genre: "Dance-Pop", modelFileName: "Mia", unlockCost: 0),
        CharacterData(id: "silverface", name: "Silver Face", subtitle: "Cyber Droid", genre: "Electro & Glitch", modelFileName: "SilverFace", unlockCost: 100),
        CharacterData(id: "chickenman", name: "Chicken Man", subtitle: "Party Mascot", genre: "Disco & Funk", modelFileName: "ChickenMan", unlockCost: 200),
        CharacterData(id: "firefighter", name: "Blaze", subtitle: "Hero Groover", genre: "Rock & Beats", modelFileName: "Firefighter", unlockCost: 300)
    ]
    
    // MARK: - Properties
    public private(set) var bestScore: Int = 0
    public private(set) var coinsTotal: Int = 0
    public private(set) var totalNotesHit: Int = 0
    public private(set) var totalNotesMissed: Int = 0
    public private(set) var totalSongsPlayed: Int = 0
    public private(set) var selectedSongIndex: Int = 0
    public private(set) var selectedCharacterIndex: Int = 0
    public var selectedDifficulty: GameDifficulty = .normal
    private var unlockedCharacterIds: Set<String> = ["blue", "alexis", "mia"]
    
    // Settings Preferences
    public private(set) var musicVolume: Float = 0.8
    public private(set) var sfxVolume: Float = 1.0
    public private(set) var isHapticsEnabled: Bool = true
    
    // Player Identity & Authentication
    public private(set) var customPlayerName: String?
    public private(set) var appleUserId: String?
    public private(set) var appleDisplayName: String?
    public private(set) var isAppleAuthenticated: Bool = false
    public private(set) var gameCenterPlayerName: String?
    public private(set) var isGameCenterAuthenticated: Bool = false
    
    public var isAppleLoggedIn: Bool {
        return isAppleAuthenticated
    }
    public var isGameCenterLoggedIn: Bool {
        return isGameCenterAuthenticated
    }
    
    public var playerName: String {
        if let custom = customPlayerName, !custom.trimmingCharacters(in: .whitespaces).isEmpty {
            return custom
        }
        if let apple = appleDisplayName, !apple.trimmingCharacters(in: .whitespaces).isEmpty {
            return apple
        }
        if let gc = gameCenterPlayerName, !gc.trimmingCharacters(in: .whitespaces).isEmpty {
            return gc
        }
        return "Groove Dancer"
    }
    
    public var accuracyPercentage: Double {
        let total = totalNotesHit + totalNotesMissed
        guard total > 0 else { return 100.0 }
        return (Double(totalNotesHit) / Double(total)) * 100.0
    }
    
    public var unlockedCharacterCount: Int {
        return availableCharacters.filter { isCharacterUnlocked(at: availableCharacters.firstIndex(of: $0)!) }.count
    }
    
    private let kBestScore = "Player_BestScore"
    private let kCoinsTotal = "Player_CoinsTotal"
    private let kNotesHit = "Player_NotesHit"
    private let kNotesMissed = "Player_NotesMissed"
    private let kSongsPlayed = "Player_SongsPlayed"
    private let kSelectedSong = "Player_SelectedSong"
    private let kSelectedChar = "Player_SelectedCharacter"
    private let kSelectedDiff = "Player_SelectedDifficulty"
    private let kUnlockedChars = "Player_UnlockedCharacters"
    private let kHasPlayed = "Player_HasPlayed"
    private let kMusicVolume = "Player_MusicVolume"
    private let kSFXVolume = "Player_SFXVolume"
    private let kHaptics = "Player_Haptics"
    private let kCustomName = "Player_CustomName"
    
    public var isFirstPlay: Bool {
        return !UserDefaults.standard.bool(forKey: kHasPlayed)
    }
    
    public var currentSong: SongData {
        if selectedSongIndex >= 0 && selectedSongIndex < availableSongs.count {
            return availableSongs[selectedSongIndex]
        }
        return availableSongs[0]
    }
    
    public var currentCharacter: CharacterData {
        if selectedCharacterIndex >= 0 && selectedCharacterIndex < availableCharacters.count {
            return availableCharacters[selectedCharacterIndex]
        }
        return availableCharacters[0]
    }
    
    private init() {
        load()
    }
    
    public func selectSong(at index: Int) {
        guard index >= 0 && index < availableSongs.count else { return }
        selectedSongIndex = index
        UserDefaults.standard.set(selectedSongIndex, forKey: kSelectedSong)
    }
    
    public func selectCharacter(at index: Int) {
        guard index >= 0 && index < availableCharacters.count else { return }
        selectedCharacterIndex = index
        UserDefaults.standard.set(selectedCharacterIndex, forKey: kSelectedChar)
    }
    
    public func isCharacterUnlocked(at index: Int) -> Bool {
        guard index >= 0 && index < availableCharacters.count else { return false }
        let char = availableCharacters[index]
        return char.unlockCost == 0 || unlockedCharacterIds.contains(char.id)
    }
    
    @discardableResult
    public func unlockCharacter(at index: Int) -> Bool {
        guard index >= 0 && index < availableCharacters.count else { return false }
        let char = availableCharacters[index]
        if isCharacterUnlocked(at: index) { return true }
        if coinsTotal >= char.unlockCost {
            coinsTotal -= char.unlockCost
            unlockedCharacterIds.insert(char.id)
            selectCharacter(at: index)
            save()
            return true
        }
        return false
    }
    
    @discardableResult
    public func setBestScore(_ newScore: Int) -> Bool {
        if newScore > bestScore {
            bestScore = newScore
            save()
            return true
        }
        return false
    }
    
    public func addCoins(_ amount: Int) {
        coinsTotal += amount
        save()
    }
    
    public func recordGameCompleted(score: Int, hits: Int, misses: Int, coins: Int) {
        totalNotesHit += hits
        totalNotesMissed += misses
        totalSongsPlayed += 1
        addCoins(coins)
        _ = setBestScore(score)
        UserDefaults.standard.set(true, forKey: kHasPlayed)
        save()
    }
    
    // MARK: - Settings Mutators
    
    public func setMusicVolume(_ volume: Float) {
        self.musicVolume = max(0.0, min(1.0, volume))
        UserDefaults.standard.set(self.musicVolume, forKey: kMusicVolume)
    }
    
    public func cycleMusicVolume() -> Float {
        // Cycles: 0.0 -> 0.3 -> 0.6 -> 0.8 -> 1.0 -> 0.0
        let current = musicVolume
        let next: Float
        if current < 0.2 { next = 0.5 }
        else if current < 0.6 { next = 0.8 }
        else if current < 0.9 { next = 1.0 }
        else { next = 0.0 }
        setMusicVolume(next)
        return next
    }
    
    public func setSFXVolume(_ volume: Float) {
        self.sfxVolume = max(0.0, min(1.0, volume))
        UserDefaults.standard.set(self.sfxVolume, forKey: kSFXVolume)
    }
    
    public func cycleSFXVolume() -> Float {
        let current = sfxVolume
        let next: Float
        if current < 0.2 { next = 0.5 }
        else if current < 0.6 { next = 0.8 }
        else if current < 0.9 { next = 1.0 }
        else { next = 0.0 }
        setSFXVolume(next)
        return next
    }
    
    public func setHapticsEnabled(_ enabled: Bool) {
        self.isHapticsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: kHaptics)
    }
    
    public func toggleHaptics() -> Bool {
        let newStatus = !isHapticsEnabled
        setHapticsEnabled(newStatus)
        return newStatus
    }
    
    public func setPlayerName(_ name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            self.customPlayerName = nil
            UserDefaults.standard.removeObject(forKey: kCustomName)
        } else {
            self.customPlayerName = clean
            UserDefaults.standard.set(clean, forKey: kCustomName)
        }
    }
    
    // MARK: - Authentication & Logout
    
    public func setAppleAuthenticated(userId: String, name: String?) {
        self.appleUserId = userId
        self.appleDisplayName = name
        self.isAppleAuthenticated = true
        UserDefaults.standard.set(userId, forKey: "Apple_UserId")
        if let name = name {
            UserDefaults.standard.set(name, forKey: "Apple_DisplayName")
        }
    }
    
    public func setGameCenterAuthenticated(name: String) {
        self.gameCenterPlayerName = name
        self.isGameCenterAuthenticated = true
        UserDefaults.standard.set(name, forKey: "GameCenter_PlayerName")
    }
    
    /// Signs out the player from Apple and Game Center sessions, clearing stored identity tokens.
    public func logout() {
        self.appleUserId = nil
        self.appleDisplayName = nil
        self.isAppleAuthenticated = false
        self.gameCenterPlayerName = nil
        self.isGameCenterAuthenticated = false
        self.customPlayerName = nil
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "Apple_UserId")
        defaults.removeObject(forKey: "Apple_DisplayName")
        defaults.removeObject(forKey: "GameCenter_PlayerName")
        defaults.removeObject(forKey: kCustomName)
        defaults.synchronize()
    }
    
    // MARK: - Persistence
    
    public func save() {
        let defaults = UserDefaults.standard
        defaults.set(bestScore, forKey: kBestScore)
        defaults.set(coinsTotal, forKey: kCoinsTotal)
        defaults.set(totalNotesHit, forKey: kNotesHit)
        defaults.set(totalNotesMissed, forKey: kNotesMissed)
        defaults.set(totalSongsPlayed, forKey: kSongsPlayed)
        defaults.set(selectedSongIndex, forKey: kSelectedSong)
        defaults.set(selectedCharacterIndex, forKey: kSelectedChar)
        defaults.set(selectedDifficulty.rawValue, forKey: kSelectedDiff)
        defaults.set(Array(unlockedCharacterIds), forKey: kUnlockedChars)
        defaults.set(musicVolume, forKey: kMusicVolume)
        defaults.set(sfxVolume, forKey: kSFXVolume)
        defaults.set(isHapticsEnabled, forKey: kHaptics)
    }
    
    public func load() {
        let defaults = UserDefaults.standard
        bestScore = defaults.integer(forKey: kBestScore)
        coinsTotal = defaults.integer(forKey: kCoinsTotal)
        totalNotesHit = defaults.integer(forKey: kNotesHit)
        totalNotesMissed = defaults.integer(forKey: kNotesMissed)
        totalSongsPlayed = defaults.integer(forKey: kSongsPlayed)
        selectedSongIndex = defaults.integer(forKey: kSelectedSong)
        selectedCharacterIndex = defaults.integer(forKey: kSelectedChar)
        
        if defaults.object(forKey: kMusicVolume) != nil {
            musicVolume = defaults.float(forKey: kMusicVolume)
        }
        if defaults.object(forKey: kSFXVolume) != nil {
            sfxVolume = defaults.float(forKey: kSFXVolume)
        }
        if defaults.object(forKey: kHaptics) != nil {
            isHapticsEnabled = defaults.bool(forKey: kHaptics)
        }
        if let custom = defaults.string(forKey: kCustomName) {
            customPlayerName = custom
        }
        
        if let diffRaw = defaults.string(forKey: kSelectedDiff), let diff = GameDifficulty(rawValue: diffRaw) {
            selectedDifficulty = diff
        }
        if let unlocked = defaults.stringArray(forKey: kUnlockedChars) {
            unlockedCharacterIds = Set(unlocked)
        }
        if let appleId = defaults.string(forKey: "Apple_UserId") {
            self.appleUserId = appleId
            self.appleDisplayName = defaults.string(forKey: "Apple_DisplayName")
            self.isAppleAuthenticated = true
        }
        if let gcName = defaults.string(forKey: "GameCenter_PlayerName") {
            self.gameCenterPlayerName = gcName
            self.isGameCenterAuthenticated = true
        }
    }
    
    // MARK: - Legal Documentation Content
    
    public static let termsOfService: [(title: String, body: String)] = [
        ("1. ACCEPTANCE", "By playing Groove Games, you agree to these Terms. If you do not agree, discontinue use immediately. Groove Games is intended for entertainment purposes."),
        ("2. INTELLECTUAL PROPERTY", "All 3D character assets, musical compositions, sound recordings, animations, and visual UI are owned by Boogie Down Games / Rai Enterprise or licensed under agreement. Unauthorized redistribution is prohibited."),
        ("3. VIRTUAL ITEMS & COINS", "Groove Coins and character unlocks are virtual game tokens earned solely via rhythm gameplay. They carry no real-world monetary value and cannot be exchanged for currency."),
        ("4. FAIR PLAY & ACCOUNTS", "Players agree to engage in fair rhythm competition. Exploits, reverse-engineering, or automated bots are prohibited. Apple ID and Game Center sessions are managed securely per Apple Guidelines."),
        ("5. TERMINATION & UPDATES", "We reserve the right to modify gameplay mechanics, catalog tracks, or features to improve performance and user experience.")
    ]
    
    public static let privacyPolicy: [(title: String, body: String)] = [
        ("1. DATA WE COLLECT", "Groove Games is privacy-first. We do NOT collect, sell, or transmit personal data or advertising identifiers to third parties."),
        ("2. APPLE & GAME CENTER", "Sign in with Apple uses Apple's private credential system. We receive an anonymous identifier solely to persist high scores and unlocks. Game Center interacts directly with Apple GameKit."),
        ("3. LOCAL STORAGE", "Game progress, coin totals, audio volume preferences, and unlocked dancers are stored locally on your device via iOS secure storage."),
        ("4. CHILD SAFETY & COPPA", "Groove Games strictly complies with Apple App Store safety rules and COPPA. We do not track children or employ behavioral ad cookies."),
        ("5. DATA PURGE / LOGOUT", "Tapping 'Log Out' immediately purges cached Apple authentication tokens and local player identities from your device.")
    ]
}
