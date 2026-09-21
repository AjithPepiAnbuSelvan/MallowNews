//
//  AppTheme.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import UIKit

enum AppTheme {
    // MARK: - Dynamic Palette

    static let brand = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.73, green: 0.60, blue: 1, alpha: 1)
            : UIColor(red: 0.33, green: 0.18, blue: 0.55, alpha: 1)
    }

    static let background = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.065, blue: 0.12, alpha: 1)
            : UIColor(red: 0.955, green: 0.94, blue: 0.99, alpha: 1)
    }
}
