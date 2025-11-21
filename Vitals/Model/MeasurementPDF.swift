//
//  MeasurementPDF.swift
//  Vitals
//
//  Created by Ayushi on 2025-10-22.
//

import UIKit
import Foundation

struct MeasurementPDF: Codable, Identifiable {
    let id: UUID
    let title: String
    let createdAt: Date
    let fileName: String  // e.g. "<uuid>.pdf"

    var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
}
