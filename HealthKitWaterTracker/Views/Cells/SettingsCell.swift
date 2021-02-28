//
//  SettingsCell.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/26/21.
//

import UIKit

class SettingsCell: UITableViewCell {
    
    static let reuseIdentifier = "SettingsCellReuseIdentifier"
    
    // MARK: - Properties
    
    var setting: SettingModel? {
        didSet {
            guard let setting = setting else { return }
            label.text = setting.displayName
            switchControl.isOn = setting.value
        }
    }
    
    let label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.addTarget(self, action: #selector(switchDidChange), for: .valueChanged)
        return switchControl
    }()
    
    // MARK: - Initializers
    
    convenience init() {
        self.init(style: .default, reuseIdentifier: SettingsCell.reuseIdentifier)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        registerForBlueColorThemeIsEnabledChanges()
        
        selectionStyle = .none
        
        contentView.addSubview(label)
        label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
        
        contentView.addSubview(switchControl)
        switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        switchControl.leftAnchor.constraint(equalTo: label.rightAnchor, constant: 8).isActive = true
        switchControl.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20).isActive = true
        
        configureColorScheme()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    private func configureColorScheme() {
        backgroundColor = .secondaryBackgroundColor
        label.textColor = .textColor
        detailTextLabel?.textColor = .detailTextColor
        
        switchControl.onTintColor = .switchOnTintColor
        switchControl.thumbTintColor = .switchThumbColor
    }
    
    // MARK: - Selectors
    
    @objc private func switchDidChange(sender: UISwitch) {
        setting?.value = sender.isOn
    }
}


// MARK: - SettingsTracking

extension SettingsCell: SettingsTracking {
    func healthIntegrationIsEnabledChanged() {}
    
    func blueColorThemeIsEnabledChanged() {
        configureColorScheme()
    }
}
