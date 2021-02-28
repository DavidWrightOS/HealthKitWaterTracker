//
//  UIColor+Extension.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/23/21.
//

import UIKit

// MARK: - Custom Colors

extension UIColor {
    private static var customBlue = #colorLiteral(red: 0.2117647059, green: 0.2431372549, blue: 0.337254902, alpha: 1)
    private static var customBlueSecondary = #colorLiteral(red: 0.2901960784, green: 0.3176470588, blue: 0.4039215686, alpha: 1)
    private static var customTeal = #colorLiteral(red: 0.1411764706, green: 0.5411764706, blue: 0.6196078431, alpha: 1)
    private static var customWhite = #colorLiteral(red: 0.8470588235, green: 0.8470588235, blue: 0.8470588235, alpha: 1)
    private static var customWhiteSecondary = #colorLiteral(red: 0.5571184754, green: 0.5771605372, blue: 0.619569242, alpha: 1)
    
    static var defaultTableViewHeaderFooterTextColor: UIColor {
        guard #available(iOS 13.0, *) else { return #colorLiteral(red: 0.3838575184, green: 0.4084955156, blue: 0.4210632443, alpha: 1) }
        return UIColor { traits -> UIColor in
            return traits.userInterfaceStyle == .light ? #colorLiteral(red: 0.3838575184, green: 0.4084955156, blue: 0.4210632443, alpha: 1) : #colorLiteral(red: 0.3907751143, green: 0.4204127789, blue: 0.4328970909, alpha: 1)
        }
    }
}


// MARK: - Dynamic Colors

extension UIColor {
    static var waterColorScheme: Bool { AppSettings.shared.blueColorThemeIsEnabled }
    
    static var tabBarItemColor: UIColor { waterColorScheme ? .detailTextColor : .systemGray }
    static var tabBarSelectedItemColor: UIColor { .actionColor }
    static var tabBarTintColor: UIColor? { waterColorScheme ? .secondaryBackgroundColor : nil }
    static var barBackgroundColor: UIColor { waterColorScheme ? .customBlue : .secondarySystemGroupedBackground }
    
    static var backgroundColor: UIColor { waterColorScheme ? .customBlue : .systemGroupedBackground }
    static var secondaryBackgroundColor: UIColor { waterColorScheme ? .customBlueSecondary : .secondarySystemGroupedBackground }
    static var textColor: UIColor { waterColorScheme ? .customWhite : .label }
    static var detailTextColor: UIColor { waterColorScheme ? .customWhiteSecondary : .secondaryLabel }
    static var actionColor: UIColor { waterColorScheme ? .customTeal : .systemBlue }
    static var switchOnTintColor: UIColor { waterColorScheme ? .customTeal : .systemGreen }
    static var switchThumbColor: UIColor { waterColorScheme ? customWhite : .white }
    static var tableViewHeaderFooterTextColor: UIColor { waterColorScheme ? .customWhiteSecondary : .defaultTableViewHeaderFooterTextColor }
}


// MARK: - UIBarStyle Theme Configuration

extension UIBarStyle {
    static var currentTheme: UIBarStyle { UIColor.waterColorScheme ? .black : .default }
}


// MARK: - UIViewController Theme Configuration

extension UIViewController {
    @objc func configureColorScheme() {
        view.backgroundColor = .backgroundColor
        
        navigationController?.navigationBar.barStyle = UIBarStyle.currentTheme
        navigationController?.navigationBar.tintColor = .actionColor
        navigationController?.navigationBar.barTintColor = .barBackgroundColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.textColor]
        navigationController?.navigationBar.largeTitleTextAttributes = textAttributes
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
}
