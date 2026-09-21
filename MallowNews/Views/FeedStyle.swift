//
//  FeedStyle.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//


import UIKit

enum FeedStyle {
    // MARK: - Metrics

    static let outerMargin: CGFloat = 20
    static let contentInset: CGFloat = 16
    static let rowSpacing: CGFloat = 14

    // MARK: - Typography

    static func trackedSource(_ name: String, color: UIColor) -> NSAttributedString {
        NSAttributedString(
            string: name.uppercased(),
            attributes: [
                .kern: 0.6,
                .foregroundColor: color,
                .font: UIFont.systemFont(ofSize: 11, weight: .bold)
            ]
        )
    }
}
