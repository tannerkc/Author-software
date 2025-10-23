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
}
