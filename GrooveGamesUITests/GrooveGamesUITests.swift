//
//  GrooveGamesUITests.swift
//  GrooveGamesUITests
//
//  Created by Aditya Rai on 08/10/26.
//

import XCTest

final class GrooveGamesUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testGameplayNoteSpawningAndScoring() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for splash screen to settle
        sleep(2)
        
        // 1. Enter Main Menu (tap splash screen when authenticated, or tap Game Center if not)
        let splashCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
        splashCoordinate.tap()
        sleep(2)
        if app.buttons["splashGameCenterBtn"].isHittable {
            app.buttons["splashGameCenterBtn"].tap()
            sleep(2)
        }
        
        // 2. Tap Play button on Main Menu (top-right card: dx: 0.80, dy: 0.30)
        let playCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.30))
        playCoordinate.tap()
        
        // 3. Wait for notes to spawn and travel down towards scoring zone
        sleep(3)
        
        // Capture screenshot of note in flight
        let noteFlightScreenshot = XCUIScreen.main.screenshot()
        let noteFlightPath = "/Users/adityarai/.gemini/antigravity-ide/brain/18d17fe5-7b48-4bd6-9cb2-2fe24f0f0fdf/scratch/gameplay_note_flight.png"
        try? noteFlightScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: noteFlightPath))
        print("[UITest] Wrote note flight screenshot to: \(noteFlightPath)")
        
        // 4. Tap playfield across the scoring zone to hit incoming notes
        for _ in 0..<8 {
            let leftTap = app.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.50))
            leftTap.tap()
            usleep(250000)
            let rightTap = app.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.50))
            rightTap.tap()
            usleep(250000)
        }
        
        sleep(1)
        
        // Capture screenshot after tapping
        let scoredScreenshot = XCUIScreen.main.screenshot()
        let scoredPath = "/Users/adityarai/.gemini/antigravity-ide/brain/18d17fe5-7b48-4bd6-9cb2-2fe24f0f0fdf/scratch/gameplay_scored.png"
        try? scoredScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: scoredPath))
        print("[UITest] Wrote gameplay scored screenshot to: \(scoredPath)")
    }
    
    @MainActor
    func testPlayerProfileAndSettingsFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        sleep(2)
        
        // 1. Splash Screen: Tap to enter Main Menu
        let splashCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
        splashCoordinate.tap()
        sleep(2)
        if app.buttons["splashGameCenterBtn"].isHittable {
            app.buttons["splashGameCenterBtn"].tap()
            sleep(2)
        }
        
        // Capture Main Menu screenshot with new Profile & Settings buttons
        let menuScreenshot = XCUIScreen.main.screenshot()
        let menuPath = "/Users/adityarai/.gemini/antigravity-ide/brain/18d17fe5-7b48-4bd6-9cb2-2fe24f0f0fdf/scratch/ui_main_menu_settings.png"
        try? menuScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: menuPath))
        print("[UITest] Main Menu screenshot saved to: \(menuPath)")
        
        // 2. Open Profile Screen (dx: 0.73, dy: 0.60)
        let profileBtnCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.73, dy: 0.60))
        profileBtnCoord.tap()
        sleep(1)
        
        let profileScreenshot = XCUIScreen.main.screenshot()
        let profilePath = "/Users/adityarai/.gemini/antigravity-ide/brain/18d17fe5-7b48-4bd6-9cb2-2fe24f0f0fdf/scratch/ui_profile_screen.png"
        try? profileScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: profilePath))
        print("[UITest] Profile screen screenshot saved to: \(profilePath)")
        
        // 3. Open Settings Screen directly from Profile header button (dx: 0.92, dy: 0.10)
        let settingsBtnCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.10))
        settingsBtnCoord.tap()
        sleep(1)
        
        // Cycle Music Volume (dx: 0.36, dy: 0.28)
        let musicBtnCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.28))
        musicBtnCoord.tap()
        usleep(300000)
        
        // Cycle SFX Volume (dx: 0.64, dy: 0.28)
        let sfxBtnCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.64, dy: 0.28))
        sfxBtnCoord.tap()
        usleep(300000)
        
        // Toggle Haptics (dx: 0.36, dy: 0.42)
        let hapticBtnCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.42))
        hapticBtnCoord.tap()
        usleep(300000)
        
        let settingsScreenshot = XCUIScreen.main.screenshot()
        let settingsPath = "/Users/adityarai/.gemini/antigravity-ide/brain/18d17fe5-7b48-4bd6-9cb2-2fe24f0f0fdf/scratch/ui_settings_screen.png"
        try? settingsScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: settingsPath))
        print("[UITest] Settings screen screenshot saved to: \(settingsPath)")
        
        // 4. Open Terms of Service Modal (dx: 0.73, dy: 0.36)
        let termsBtnCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.73, dy: 0.36))
        termsBtnCoord.tap()
        sleep(1)
        
        let termsScreenshot = XCUIScreen.main.screenshot()
        let termsPath = "/Users/adityarai/.gemini/antigravity-ide/brain/18d17fe5-7b48-4bd6-9cb2-2fe24f0f0fdf/scratch/ui_terms_modal.png"
        try? termsScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: termsPath))
        print("[UITest] Terms modal screenshot saved to: \(termsPath)")
        
        // Close Terms Modal (dx: 0.50, dy: 0.86)
        let termsCloseCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.86))
        termsCloseCoord.tap()
        sleep(1)
        
        // 5. Open Privacy Policy Modal (dx: 0.73, dy: 0.47)
        let privacyBtnCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.73, dy: 0.47))
        privacyBtnCoord.tap()
        sleep(1)
        
        let privacyScreenshot = XCUIScreen.main.screenshot()
        let privacyPath = "/Users/adityarai/.gemini/antigravity-ide/brain/18d17fe5-7b48-4bd6-9cb2-2fe24f0f0fdf/scratch/ui_privacy_modal.png"
        try? privacyScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: privacyPath))
        print("[UITest] Privacy modal screenshot saved to: \(privacyPath)")
        
        // Close Privacy Modal (dx: 0.50, dy: 0.86)
        let privacyCloseCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.86))
        privacyCloseCoord.tap()
        sleep(1)
        
        // 6. Test Logout (dx: 0.73, dy: 0.59)
        let logoutBtnCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.73, dy: 0.59))
        logoutBtnCoord.tap()
        sleep(2)
        
        let splashAfterLogoutScreenshot = XCUIScreen.main.screenshot()
        let splashLogoutPath = "/Users/adityarai/.gemini/antigravity-ide/brain/18d17fe5-7b48-4bd6-9cb2-2fe24f0f0fdf/scratch/ui_splash_after_logout.png"
        try? splashAfterLogoutScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: splashLogoutPath))
        print("[UITest] Splash after logout screenshot saved to: \(splashLogoutPath)")
        
        // 7. Verify tapping background after logout triggers warning and does NOT enter the game
        splashCoordinate.tap()
        sleep(1)
        
        let loginPromptScreenshot = XCUIScreen.main.screenshot()
        let promptPath = "/Users/adityarai/.gemini/antigravity-ide/brain/18d17fe5-7b48-4bd6-9cb2-2fe24f0f0fdf/scratch/ui_login_required_toast.png"
        try? loginPromptScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: promptPath))
        print("[UITest] Login required toast screenshot saved to: \(promptPath)")
    }
}
