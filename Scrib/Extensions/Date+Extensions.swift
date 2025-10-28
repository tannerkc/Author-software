//
//  Date+Extensions.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation

extension Date {
    /// Format the date as a relative time string (e.g., "2 hours ago")
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Format the date as a short date string (e.g., "Jan 23, 2025")
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Format the date with time (e.g., "Jan 23, 2025 at 3:45 PM")
    var fullFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Check if the date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if the date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Check if the date is within the last week
    var isWithinLastWeek: Bool {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return self > weekAgo
    }

    /// Smart formatting based on recency
    var smartFormatted: String {
        if isToday {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: self))"
        } else if isYesterday {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Yesterday at \(formatter.string(from: self))"
        } else if isWithinLastWeek {
            return relativeFormatted
        } else {
            return shortFormatted
        }
    }

    /// Simple static formatting: time if today, date otherwise
    var simpleFormatted: String {
        if isToday {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: self)
        }
    }

    /// Apple Notes-style relative formatting for chapter list metadata
    /// Returns: "Now" | "2 min ago" | "2 hours ago" | "Yesterday" | "Oct 28"
    var appleNotesStyleFormatted: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        // Within 5 seconds: "Now"
        if interval < 5 {
            return "Now"
        }

        // Within minute: show seconds
        if interval < 60 {
            let seconds = Int(interval)
            return seconds == 1 ? "1 second ago" : "\(seconds) seconds ago"
        }

        // Within hour: show minutes
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return minutes == 1 ? "1 min ago" : "\(minutes) min ago"
        }

        // Within today: show hours
        if Calendar.current.isDateInToday(self) {
            let hours = Int(interval / 3600)
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }

        // Yesterday
        if Calendar.current.isDateInYesterday(self) {
            return "Yesterday"
        }

        // Within the past week: show day name
        if interval < 604800 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Full day name
            return formatter.string(from: self)
        }

        // Within current year: "Oct 28"
        let calendar = Calendar.current
        if calendar.component(.year, from: self) == calendar.component(.year, from: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        }

        // Older: "Oct 28, 2024"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }
}
