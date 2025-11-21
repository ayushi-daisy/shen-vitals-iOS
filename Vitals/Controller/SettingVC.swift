//
//  SettingVC.swift
//  Vitals
//
//  Created by Ayushi on 2025-10-07.
//

import UIKit
import ShenaiSDK

class SettingVC: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var languageSegment: UISegmentedControl!
    @IBOutlet weak var tableview: UITableView!

    
    // MARK: Properties
    
    private enum MenuItem: String, CaseIterable {
        case history = "History"
        case about = "About us"
    }
    
    private let items = MenuItem.allCases

    
    // MARK: Init / Deinit
    deinit {  }
    
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
    }
    
    
    // MARK: setup
    
    
    

    // MARK: UI Setup
    
    private func setupUI() {
        
        self.view.backgroundColor = .systemBackground
        self.title = localize(settings_)
        
        // Tableview setup
        self.tableview.delegate = self
        self.tableview.dataSource = self
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell") // <-- add this
        self.tableview.reloadData()
        
        // UISegmentBar setup
        let current = LanguageManager.shared.current
        languageSegment.setTitle(localize(english_), forSegmentAt: 0)
        languageSegment.setTitle(localize(arabic_), forSegmentAt: 1)
        languageSegment.selectedSegmentIndex = (current == .en ? 0 : 1)

        // Swipe left to open
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
    }
    

    // MARK: ObjC Selectors
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left {
            let transition = CATransition()
            transition.duration = 0.35
            transition.type = .push
            transition.subtype = .fromRight
            view.window?.layer.add(transition, forKey: kCATransition)
            self.dismiss(animated: false)
        }
    }
    

    // MARK: Actions
    
    @IBAction func languageChanged(_ sender: UISegmentedControl) {
        let newLang: AppLanguage = (sender.selectedSegmentIndex == 0) ? .en : .ar
        LanguageManager.shared.apply(newLang)
    }
    
}

extension SettingVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let item = items[indexPath.row]
        cell.textLabel?.text = localize(item.rawValue)
        
        cell.textLabel?.font = .systemFont(ofSize: 20, weight: .regular)
        cell.textLabel?.textColor = .label  // Uses dark/light mode color automatically
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)

        switch item {
        case .history:
            let history = HistoryVC()
            self.navigationController?.pushViewController(history, animated: true)

        default:
            break
        }
    }
    
}
