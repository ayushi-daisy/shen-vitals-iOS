//
//  PreviousResultsVC.swift
//  Vitals
//
//  Created by Ayushi on 2025-10-07.
//

import UIKit
import Foundation

final class HistoryVC: UITableViewController {

    // MARK: Properties

    private var items: [StoredPDF] = []
    
    private lazy var emptyLabel: UILabel = {
            let label = UILabel()
            label.text = localize(noScanFound)
            label.textColor = UIColor(hex: "#727BEB")
            label.font = .systemFont(ofSize: 18, weight: .medium)
            label.textAlignment = .center
            label.numberOfLines = 0
            return label
        }()
    
    // MARK: Init / Deinit
    deinit {
        NotificationCenter.default.removeObserver(self, name: .pdfHistoryDidChange, object: nil)
    }


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = localize(history)
        view.backgroundColor = .systemBackground
        
        // Optional styling
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.allowsSelectionDuringEditing = false

        reloadData()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadData),
            name: .pdfHistoryDidChange,
            object: nil
        )
    }

    // MARK: - Data
    @objc private func reloadData() {
        
        if PDFStore.shared.isEmpty {
            tableView.backgroundView = emptyLabel
            tableView.separatorStyle = .none
        } else {
            items = PDFStore.shared.all()
            DispatchQueue.main.async {
                self.tableView.backgroundView = nil
                self.tableView.separatorStyle = .singleLine
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - TableView DataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var cfg = cell.defaultContentConfiguration()
        cfg.text = item.title
        cfg.secondaryText = DateFormatter.localizedString(
            from: item.createdAt,
            dateStyle: .medium,
            timeStyle: .short
        )
        cell.contentConfiguration = cfg
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        let viewer = PDFViewerVC(fileURL: item.fileURL, title: item.title)
        navigationController?.pushViewController(viewer, animated: true)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Delete") { _,_,done in
            PDFStore.shared.delete(self.items[indexPath.row])
            self.reloadData()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}
