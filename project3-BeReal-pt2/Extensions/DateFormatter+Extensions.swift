//
//  DateFormatter+Extensions.swift
//  project2-BeReal
//
//  Created by Sunny Chen on 9/14/24.
//

import Foundation

extension DateFormatter {
    static var postFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
}
