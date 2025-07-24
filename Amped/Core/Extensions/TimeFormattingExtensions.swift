//
//  TimeFormattingExtensions.swift
//  Amped
//
//  Extensions for consistent time formatting throughout the app
//

import Foundation

extension Double {
    /// Formats minutes into a human-readable time string
    /// - Returns: Formatted string like "1 hour 19 minutes", "2.5 days", etc.
    func formattedAsTime() -> String {
        let absMinutes = abs(self)
        
        // Handle days (24+ hours)
        if absMinutes >= 1440 { // 24 hours = 1440 minutes
            let days = absMinutes / 1440
            if days.truncatingRemainder(dividingBy: 1.0) == 0 {
                // Whole days
                return "\(Int(days))\u{00A0}day\(Int(days) == 1 ? "" : "s")"
            } else {
                // Decimal days
                return String(format: "%.1f\u{00A0}days", days)
            }
        }
        
        // Handle hours and minutes (60+ minutes)
        if absMinutes >= 60 {
            let hours = Int(absMinutes / 60)
            let minutes = Int(absMinutes.truncatingRemainder(dividingBy: 60))
            
            if minutes == 0 {
                return "\(hours)\u{00A0}hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours)\u{00A0}hour\(hours == 1 ? "" : "s")\u{00A0}\(minutes)\u{00A0}minute\(minutes == 1 ? "" : "s")"
            }
        }
        
        // Handle just minutes
        let roundedMinutes = Int(absMinutes.rounded())
        return "\(roundedMinutes)\u{00A0}minute\(roundedMinutes == 1 ? "" : "s")"
    }
    
    /// Formats minutes into a shorter time string for compact display
    /// - Returns: Formatted string like "1h 19m", "2.5d", etc.
    func formattedAsTimeShort() -> String {
        let absMinutes = abs(self)
        
        // Handle days (24+ hours)
        if absMinutes >= 1440 { // 24 hours = 1440 minutes
            let days = absMinutes / 1440
            return String(format: "%.1f\u{00A0}d", days)
        }
        
        // Handle hours and minutes (60+ minutes)
        if absMinutes >= 60 {
            let hours = Int(absMinutes / 60)
            let minutes = Int(absMinutes.truncatingRemainder(dividingBy: 60))
            
            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h\u{00A0}\(minutes)m"
            }
        }
        
        // Handle just minutes
        let roundedMinutes = Int(absMinutes.rounded())
        return "\(roundedMinutes)m"
    }
}

extension Int {
    /// Formats integer minutes into a human-readable time string
    /// - Returns: Formatted string like "1 hour 19 minutes", "2 days", etc.
    func formattedAsTime() -> String {
        return Double(self).formattedAsTime()
    }
    
    /// Formats integer minutes into a shorter time string for compact display
    /// - Returns: Formatted string like "1h 19m", "2d", etc.
    func formattedAsTimeShort() -> String {
        return Double(self).formattedAsTimeShort()
    }
} 