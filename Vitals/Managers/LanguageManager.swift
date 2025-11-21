
//
//  LanguageManager.swift.swift
//  Vitals
//
//  Created by Ayushi on 2025-10-15.
//

import UIKit
import AVFoundation
import ShenaiSDK


enum AppLanguage: String {
    case en = "en"
    case ar = "ar"
    
    var isRTL: Bool { self == .ar }
}


final class LanguageManager {
    
    static let shared = LanguageManager()
    private init() {}

    private let key = "AppLanguage"

    var current: AppLanguage {
        get { AppLanguage(rawValue: UserDefaults.standard.string(forKey: key) ?? "en") ?? .en }
        set {
            guard newValue != current else { return }
            UserDefaults.standard.setValue(newValue.rawValue, forKey: key)
            UserDefaults.standard.synchronize()
            apply(newValue)
        }
    }

    var bundle: Bundle {
        let path = Bundle.main.path(forResource: current.rawValue, ofType: "lproj")!
        return Bundle(path: path)!
    }

    func localizedString(for key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    func apply(_ lang: AppLanguage) {
        
        // 1) AppleLanguages (helps NSLocalizedString pick table immediately on cold starts)
        UserDefaults.standard.setValue(lang.rawValue, forKey: key)
        UserDefaults.standard.synchronize()
        
        // 2) Tell Shen’s SDK
        ShenaiSDK.setLanguage(lang.rawValue)

        // 3) Iterate through all active scenes (iPad/Mac Catalyst, multiple windows)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            guard let window = appDelegate.window else { return }
            appDelegate.setScreenWithLayout(current, to: window)
        } else {
            print("Could not cast UIApplication.shared.delegate to AppDelegate.")
        }
    }
}
