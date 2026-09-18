//
//  Color+Theme.swift
//  PETROiD-Rock-ID
//

import SwiftUI

extension Color {
    init(hex: String) {
        var hexValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&hexValue)
        let r = Double((hexValue & 0xFF0000) >> 16) / 255
        let g = Double((hexValue & 0x00FF00) >> 8) / 255
        let b = Double(hexValue & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static let rockBackground = Color(hex: "09100c")
    static let rockSurface = Color(hex: "0d1511")
    static let rockSurfaceVariant = Color(hex: "1e2822")
    static let rockPrimary = Color(hex: "34D399")
    static let rockPrimaryDim = Color(hex: "19be64")
    static let rockOnSurface = Color(hex: "f7fef7")
    static let rockOnSurfaceVariant = Color(hex: "a5ada6")
    static let rockOutlineVariant = Color(hex: "424a45")
}

/// Formats a Mohs hardness range the way the field-guide UI expects: "6-7" or a single "3".
func formatHardness(min: Double, max: Double) -> String {
    func trim(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
    return min == max ? trim(min) : "\(trim(min))-\(trim(max))"
}
