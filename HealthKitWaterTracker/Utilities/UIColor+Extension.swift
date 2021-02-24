//
//  UIColor+Extension.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/23/21.
//

import UIKit

extension UIColor {
    
    static let waterColorScheme: Bool = false
    
    static var tabBarItemColor: UIColor { waterColorScheme ? .detailTextColor : .systemGray }
    static var tabBarSelectedItemColor: UIColor { .actionColor }
    static var tabBarTintColor: UIColor? { waterColorScheme ? .groupedBackgroundColor : nil }
    static var tabBarBackgroundColor: UIColor { waterColorScheme ? #colorLiteral(red: 0.2117647059, green: 0.2431372549, blue: 0.337254902, alpha: 1) : .secondarySystemGroupedBackground }
    
    static var backgroundColor: UIColor { waterColorScheme ? #colorLiteral(red: 0.2117647059, green: 0.2431372549, blue: 0.337254902, alpha: 1) : .systemGroupedBackground }
    static var groupedBackgroundColor: UIColor { waterColorScheme ? #colorLiteral(red: 0.2738786042, green: 0.3016990721, blue: 0.3874301314, alpha: 1) : .secondarySystemGroupedBackground }
    static var textColor: UIColor { waterColorScheme ? #colorLiteral(red: 0.8470588235, green: 0.8470588235, blue: 0.8470588235, alpha: 1) : .label }
    static var detailTextColor: UIColor { waterColorScheme ? #colorLiteral(red: 0.5571184754, green: 0.5771605372, blue: 0.619569242, alpha: 1) : .secondaryLabel }
    static var actionColor: UIColor { waterColorScheme ? #colorLiteral(red: 0.1411764706, green: 0.5411764706, blue: 0.6196078431, alpha: 1) : .systemBlue }
    static var switchOnTintColor: UIColor { waterColorScheme ? #colorLiteral(red: 0.1411764706, green: 0.5411764706, blue: 0.6196078431, alpha: 1) : .systemGreen }
}
