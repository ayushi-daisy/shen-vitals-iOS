//
//  PDFViewerVC.swift
//  Vitals
//
//  Created by Ayushi on 2025-10-22.
//

import UIKit
import PDFKit

final class PDFViewerVC: UIViewController {
    
    private let fileURL: URL
    private let docTitle: String

    init(fileURL: URL, title: String) {
        self.fileURL = fileURL
        self.docTitle = title
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = docTitle
        view.backgroundColor = .systemBackground

        let pdfView = PDFView(frame: view.bounds)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        view.addSubview(pdfView)

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        pdfView.document = PDFDocument(url: fileURL)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(share)
        )
    }

    @objc private func share() {
        let vc = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        present(vc, animated: true)
    }
}
