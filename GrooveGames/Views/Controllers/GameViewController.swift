//
//  GameViewController.swift
//  GrooveGames
//
//  Created by Aditya Rai on 08/10/26.
//

import UIKit
import SceneKit
import SpriteKit
import AuthenticationServices
import GameKit

class GameViewController: UIViewController {

    private var scnView: SCNView!
    private var hudScene: GameHUDScene!
    
    // Native Apple Login & Game Center UIControls (HIG Corner Radius 22)
    private var appleLoginButton: ASAuthorizationAppleIDButton?
    private var gameCenterButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSceneView()
        setupHUDOverlay()
        setupNativeSplashAuthButtons()
        setupGameCenterAuthHandler()
        
        // Setup 3D scene, character, and HUD (starts in Splash screen)
        DanceGameManager.shared.setupGame(in: scnView, hud: hudScene)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let hud = hudScene, hud.size != scnView.bounds.size {
            hud.size = scnView.bounds.size
        }
        layoutSplashAuthButtons()
    }
    
    // MARK: - Native Splash Auth Buttons (Corner Radius 22)
    
    private func setupNativeSplashAuthButtons() {
        appleLoginButton?.removeFromSuperview()
        gameCenterButton?.removeFromSuperview()
        
        // 1. Native Sign in with Apple Button with Corner Radius 22
        let appleBtn = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .white)
        appleBtn.cornerRadius = 22
        appleBtn.accessibilityIdentifier = "splashAppleLoginBtn"
        appleBtn.addTarget(self, action: #selector(handleAppleLogin), for: .touchUpInside)
        view.addSubview(appleBtn)
        self.appleLoginButton = appleBtn
        
        // 2. Native Apple Game Center Button with Corner Radius 22
        let gcBtn = UIButton(type: .system)
        gcBtn.layer.cornerRadius = 22
        gcBtn.layer.masksToBounds = true
        gcBtn.accessibilityIdentifier = "splashGameCenterBtn"
        gcBtn.backgroundColor = UIColor(white: 0.12, alpha: 0.94)
        gcBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
        gcBtn.layer.borderWidth = 1.0
        gcBtn.tintColor = .white
        
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let gcIcon = UIImage(systemName: "gamecontroller.fill", withConfiguration: config)
        gcBtn.setImage(gcIcon, for: .normal)
        gcBtn.setTitle("  Game Center", for: .normal)
        gcBtn.setTitleColor(.white, for: .normal)
        gcBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        gcBtn.addTarget(self, action: #selector(handleGameCenter), for: .touchUpInside)
        view.addSubview(gcBtn)
        self.gameCenterButton = gcBtn
        
        // Connect HUD scene transition callback
        hudScene.onScreenStateChanged = { [weak self] state in
            self?.updateSplashButtonsVisibility(for: state)
        }
        hudScene.onAppleLoginRequested = { [weak self] in
            self?.handleAppleLogin()
        }
        hudScene.onGameCenterRequested = { [weak self] in
            self?.handleGameCenter()
        }
        
        updateSplashButtonsVisibility(for: hudScene.currentScreenState)
    }
    
    private func layoutSplashAuthButtons() {
        guard let appleBtn = appleLoginButton, let gcBtn = gameCenterButton else { return }
        
        let screenW = view.bounds.width
        let screenH = view.bounds.height
        guard screenW > 0, screenH > 0 else { return }
        
        let safeBottom = view.safeAreaInsets.bottom
        let bottomMargin: CGFloat = max(safeBottom + 12, 24)
        let btnHeight: CGFloat = 44
        
        if screenW >= screenH {
            // Landscape layout: side-by-side with 16pt gap
            let maxBtnWidth: CGFloat = 215
            let availableW = screenW - view.safeAreaInsets.left - view.safeAreaInsets.right - 40
            let btnWidth = min(maxBtnWidth, (availableW - 16) / 2)
            let spacing: CGFloat = 16
            let centerX = screenW / 2
            let yPos = screenH - bottomMargin - btnHeight
            
            appleBtn.frame = CGRect(x: centerX - btnWidth - spacing / 2, y: yPos, width: btnWidth, height: btnHeight)
            gcBtn.frame = CGRect(x: centerX + spacing / 2, y: yPos, width: btnWidth, height: btnHeight)
        } else {
            // Portrait fallback: stacked vertically
            let btnWidth = min(240, screenW - 60)
            let centerX = screenW / 2
            let yGc = screenH - bottomMargin - btnHeight
            let yApple = yGc - btnHeight - 12
            
            appleBtn.frame = CGRect(x: centerX - btnWidth / 2, y: yApple, width: btnWidth, height: btnHeight)
            gcBtn.frame = CGRect(x: centerX - btnWidth / 2, y: yGc, width: btnWidth, height: btnHeight)
        }
    }
    
    private var gameCenterAuthViewController: UIViewController?
    private var lastAuthenticatedPlayerID: String?
    
    private func setupGameCenterAuthHandler() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] vc, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let vc = vc {
                    self.gameCenterAuthViewController = vc
                } else if localPlayer.isAuthenticated {
                    if PlayerProfile.shared.isGameCenterAuthenticated && PlayerProfile.shared.gameCenterPlayerName == localPlayer.displayName {
                        return
                    }
                    PlayerProfile.shared.setGameCenterAuthenticated(name: localPlayer.displayName)
                    print("[GameCenter] Authenticated as \(localPlayer.displayName)")
                    self.hudScene?.updateSplashAuthState()
                    self.updateSplashButtonsVisibility(for: self.hudScene?.currentScreenState ?? .splash)
                } else if let error = error {
                    print("[GameCenter] Authentication error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateSplashButtonsVisibility(for state: GameScreenState) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.updateSplashButtonsVisibility(for: state)
            }
            return
        }
        let profile = PlayerProfile.shared
        let isLoggedIn = profile.isAppleLoggedIn || profile.isGameCenterLoggedIn
        let showButtons = (state == .splash && !isLoggedIn)
        
        appleLoginButton?.isHidden = !showButtons
        gameCenterButton?.isHidden = !showButtons
        if showButtons {
            if let appleBtn = appleLoginButton { view.bringSubviewToFront(appleBtn) }
            if let gcBtn = gameCenterButton { view.bringSubviewToFront(gcBtn) }
        }
    }
    
    // MARK: - Sign in with Apple Action
    
    @objc private func handleAppleLogin() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - Apple Game Center Action
    
    @objc private func handleGameCenter() {
        let localPlayer = GKLocalPlayer.local
        if localPlayer.isAuthenticated {
            PlayerProfile.shared.setGameCenterAuthenticated(name: localPlayer.displayName)
            self.hudScene?.updateSplashAuthState()
            self.hudScene?.showJudgment(text: GameConstants.Judgments.gameCenterPlayer(localPlayer.displayName), scoreEarned: 0, color: GameConstants.Palette.gameCenterCyan)
            self.hudScene?.setScreenState(.mainMenu)
        } else if let vc = gameCenterAuthViewController {
            present(vc, animated: true)
        } else {
            self.hudScene?.showLoginRequiredPrompt()
        }
    }
    
    // MARK: - SceneKit Setup
    
    private func setupSceneView() {
        if let existing = self.view as? SCNView {
            self.scnView = existing
        } else {
            let scn = SCNView(frame: self.view.bounds)
            scn.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(scn)
            self.scnView = scn
        }
        
        scnView.backgroundColor = UIColor(red: 0.05, green: 0.04, blue: 0.08, alpha: 1.0)
        scnView.preferredFramesPerSecond = 60
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false
        scnView.showsStatistics = false
        scnView.isMultipleTouchEnabled = true
    }
    
    private func setupHUDOverlay() {
        let hud = GameHUDScene(size: scnView.bounds.size)
        self.hudScene = hud
        scnView.overlaySKScene = hud
    }
    


    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

// MARK: - ASAuthorizationControllerDelegate & Presentation

extension GameViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window ?? UIWindow()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            let givenName = fullName?.givenName ?? "Dancer"
            print("[AppleAuth] Success! User: \(userIdentifier), Name: \(givenName), Email: \(email ?? "")")
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                PlayerProfile.shared.setAppleAuthenticated(userId: userIdentifier, name: givenName)
                self.hudScene?.showJudgment(text: GameConstants.Judgments.welcomePlayer(givenName), scoreEarned: 0, color: GameConstants.Palette.successGreenColor)
                self.hudScene?.setScreenState(.mainMenu)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            print("[AppleAuth] Apple Sign In Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameViewController: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
