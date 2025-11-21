//
//  ShenDashBoardVC.swift
//  Vitals
//
//  Created by Ayushi on 2025-10-13.
//

import UIKit
import AVFoundation
import ShenaiSDK

class ShenDashBoardVC: UIViewController {
    
    // MARK: Outlets
    
    
    // MARK: Properties
    private var didInitSDK = false

    // MARK: Init / Deinit
    deinit { }
    
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        self.title = localize(dashboard)
        
        self.setupGestures()
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // You must have camera permission before initializing the SDK.
        self.requestCameraAccessThenInitialize()
    }
    
    
    // MARK: UI Setup
    private func setupGestures() {
        // Swipe left to open
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .right
        view.addGestureRecognizer(swipeLeft)
    }
    
    
    // MARK: Show & hide Indicator

    private func showHUD(_ text: String) {
        HUDOverlay.show(text)
    }
    
    private func hideHUD() {
        HUDOverlay.hide()
    }

    
    
    // MARK: Actions
    
    
    
    // MARK: ObjC Selectors
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .right { openMenu() }
    }
    
    private func openMenu() {
        if let setting = mainStoryboard.instantiateViewController(withIdentifier: "SettingVC") as? SettingVC {
            let nav = UINavigationController(rootViewController: setting)
            nav.modalPresentationStyle = .overFullScreen
            
            // Slide-in animation (left-to-right presentation)
            let transition = CATransition()
            transition.duration = 0.35
            transition.type = .push
            transition.subtype = .fromLeft
            view.window?.layer.add(transition, forKey: kCATransition)
            self.present(nav, animated: false)
        }
        
    }
    

    // MARK: - Permissions + SDK init
    
    private func requestCameraAccessThenInitialize() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            initializeShenAISDKIfNeeded()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.initializeShenAISDKIfNeeded() } else {
                        print("Camera permission denied — cannot initialize Shen.AI.")
                    }
                }
            }
        case .denied, .restricted:
            print("Camera permission not available — cannot initialize Shen.AI.")
        @unknown default:
            print("Unknown camera authorization status.")
        }
    }
    
    
    
    // MARK: - ShenaiSDK Integration
    
    private func initializeShenAISDKIfNeeded() {
        guard !didInitSDK else { return }
        didInitSDK = true
        
        let settings = InitializationSettings()
        settings.showSignalTile = false
        
        settings.eventCallback = { [weak self] event in
            guard let self = self else { return }
            switch event {
                
            case .screenChanged:
                print("screenChanged")
                
            case .measurementFinished:
                print("measurementFinished")
                
            case .userFlowFinished:
                print("userFlowFinished")
                self.handleUserFlowFinished()
                
            default:
                break
            }
        }
        
        let result = ShenaiSDK.initialize(ShenManager.shared.API_KEY, userID: ShenManager.shared.USER_ID, settings: settings)
        
        guard result == .success else {
            assertionFailure("Shen init failed: \(result)")
            return
        }
        
        // Embed Shen UI
        let sdkVC = ShenaiView()
        addChild(sdkVC)
        view.addSubview(sdkVC.view)
        sdkVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sdkVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sdkVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sdkVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sdkVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        sdkVC.didMove(toParent: self)
        
        // Theme + Language
        var theme = CustomColorTheme()
        theme.themeColor = "#727BEB"
        ShenaiSDK.setCustomColorTheme(theme)
        
        if let lang = UserDefaults.standard.string(forKey: "AppLanguage") {
            ShenaiSDK.setLanguage(lang)
        } else {
            ShenaiSDK.setLanguage("en")
        }
    }
    
    
    // MARK: - Called when Shen SDK finishes user flow
    private func handleUserFlowFinished() {

        // Kick off server-side PDF prep (non-blocking)
        ShenaiSDK.requestMeasurementResultsPdfUrl()

        let title = "Vital Result – " + DateFormatter.localizedString(from: Date(), dateStyle: .medium,timeStyle: .short)

        Task { @MainActor in
            showHUD(localize(preparePDF))

            do {
                if let saved = try await saveMeasurementPDF(title: title) {
                    hideHUD()
                    NotificationCenter.default.post(name: .pdfHistoryDidChange, object: nil)
                    let viewer = PDFViewerVC(fileURL: saved.fileURL, title: saved.title)
                    self.navigationController?.pushViewController(viewer, animated: true)
                } else {
                    hideHUD()
                    presentErrorAlert(message: localize(pdfErrorMsg))
                }
            } catch {
                hideHUD()
                presentErrorAlert(message: "Couldn’t save the PDF.\n\(error.localizedDescription)")
            }
        }
    }

    // MARK: - Save logic (bytes first, else URL → download)
    private func saveMeasurementPDF(title: String) async throws -> StoredPDF? {
        // 1) Fast path: bytes from SDK
        if let data = ShenaiSDK.getMeasurementResultsPdfBytes(), !data.isEmpty {
            return try PDFStore.shared.addPDF(data: data, title: title)
        }

        // 2) Poll for a sharable URL, then download with ephemeral session
        guard let url = await pollForPDFURL(maxAttempts: 20, initialDelay: 0.3, backoff: 1.25) else {
            return nil
        }

        let temp = try await downloadPDF(from: url)
        return try PDFStore.shared.addPDF(from: temp, title: title)
    }

    // MARK: - Networking (ephemeral to avoid CFNetwork cache noise)
    private func downloadPDF(from url: URL) async throws -> URL {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: cfg)
        let (tempURL, _) = try await session.download(from: url)
        return tempURL
    }

    // MARK: - Helpers you already had (keep if not present)
    private func currentPdfURL() -> URL? {
        if let u = ShenaiSDK.getMeasurementResultsPdfUrl() as? URL { return u }
        if let s = ShenaiSDK.getMeasurementResultsPdfUrl() as? String, let u = URL(string: s) { return u }
        return nil
    }

    private func pollForPDFURL(
        maxAttempts: Int = 20,
        initialDelay: Double = 0.3,
        backoff: Double = 1.25
    ) async -> URL? {
        if let url = currentPdfURL() { return url }
        var delay = initialDelay
        for _ in 0..<maxAttempts {
            let ns = UInt64(max(0, delay) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)
            if let url = currentPdfURL() { return url }
            delay *= backoff
        }
        return nil
    }

    @MainActor
    private func presentErrorAlert(title: String = "PDF Error", message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
    }
    
}
