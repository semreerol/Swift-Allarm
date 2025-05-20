//
//  Alarm.swift
//  Allarrm
//
//  Created by Selman Emre Erol on 7.05.2025.
//
import Foundation

struct Alarm {
    var saat: Date
    var etiket: String
    var gunler: [String]
    var erteleme: Bool
    var aktif: Bool = true // Varsayılan olarak aktif
    var sesAdi: String = "Varsayılan"
}
