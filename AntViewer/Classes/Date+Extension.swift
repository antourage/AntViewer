//
//  Date+Extension.swift
//  AntViewer
//
//  Created by Maryan Luchko on 30.05.2020.
//

import Foundation

extension Date {
func timeAgo(chatFlow: Bool = false) -> String {
    guard let seconds = Calendar.current.dateComponents([.second], from: self, to: Date()).second,
    let minutes = Calendar.current.dateComponents([.minute], from: self, to: Date()).minute,
      let hours = Calendar.current.dateComponents([.hour], from: self, to: Date()).hour,
      let days = Calendar.current.dateComponents([.day], from: self, to: Date()).day,
      let weeks = Calendar.current.dateComponents([.weekOfMonth], from: self, to: Date()).weekOfMonth,
      let months = Calendar.current.dateComponents([.month], from: self, to: Date()).month,
      let years = Calendar.current.dateComponents([.year], from: self, to: Date()).year else { return "" }

    var unit = ""
    var value = 0
    switch (minutes, hours, days, weeks, months, years) {
    case let (minutes, _, _ ,_ ,_, _) where minutes < 1:
        let text = (!chatFlow || seconds <= 10) ?
        LocalizedStrings.justNow.localized :
        LocalizedStrings.recent.localized
      return text
    case let (minutes, hours, _, _, _, _) where hours < 1:
      unit = "Minutes"
      value = minutes
    case let (_, hours, day, _, _, _) where day < 1:
      unit = "Hours"
      value = hours
    case let (_, _, days, weeks, _, _) where weeks < 1:
      unit = "Days"
      value = days
    case let (_, _, _, weeks, months, _) where months < 1:
      unit = "Weeks"
      value = weeks
    case let (_, _, _, _, months, years) where years < 1:
      unit = "Months"
      value = months
    default:
      unit = "Years"
      value = years
    }
    return String.localizedStringWithFormat(unit.localized(), value)
  }
}
