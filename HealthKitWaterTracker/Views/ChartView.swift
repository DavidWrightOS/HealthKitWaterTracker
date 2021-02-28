//
//  ChartView.swift
//  HealthKitWaterTracker
//
//  Created by David Wright on 2/23/21.
//

import UIKit
import CareKitUI

protocol ChartViewDataSource: class {
    var chartValues: [CGFloat] { get }
}

protocol ChartViewDelegate: class {
    var chartTitle: String? { get }
    var chartSubtitle: String? { get }
    var chartUnitTitle: String? { get }
    var chartHorizontalAxisMarkers: [String]? { get }
}

extension ChartViewDelegate {
    var chartTitle: String? { nil }
    var chartSubtitle: String? { nil }
    var chartUnitTitle: String? { nil }
    var chartHorizontalAxisMarkers: [String]? { nil }
}

class ChartView: UIView {
    
    // MARK: - Properties
    
    weak var dataSource: ChartViewDataSource?
    weak var delegate: ChartViewDelegate?
    
    private var title: String? { delegate?.chartTitle }
    private var subtitle: String? { delegate?.chartSubtitle }
    private var unitDisplayName: String? { delegate?.chartUnitTitle }
    private var horizontalAxisMarkers: [String]? { delegate?.chartHorizontalAxisMarkers }
    
    private var chartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .bar)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tintColor = .actionColor
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        addSubview(chartView)
        
        let leading = chartView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let top = chartView.topAnchor.constraint(equalTo: topAnchor)
        let trailing = chartView.trailingAnchor.constraint(equalTo: trailingAnchor)
        let bottom = chartView.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        trailing.priority -= 1
        bottom.priority -= 1
        
        NSLayoutConstraint.activate([leading, top, trailing, bottom])
    }
    
    // MARK: - Update UI
    
    func reloadChart() {
        let values = dataSource?.chartValues ?? []
        
        // Update headerView
        chartView.headerView.titleLabel.text = delegate?.chartTitle
        chartView.headerView.detailLabel.text = delegate?.chartSubtitle
        
        // Update graphView
        let horizontalAxisMarkers = delegate?.chartHorizontalAxisMarkers ?? Array(repeating: "", count: values.count)
        chartView.graphView.horizontalAxisMarkers = horizontalAxisMarkers
        applyCurrentColorScheme()
        
        // Update graphView dataSeries
        let unitTitle = delegate?.chartUnitTitle ?? ""
        let ockDataSeries = OCKDataSeries(values: values, title: unitTitle)
        chartView.graphView.dataSeries = [ockDataSeries]
    }
    
    // MARK: - Formatters
    
    private let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        return numberFormatter
    }()
}


// MARK: - Chart View Style

extension ChartView {
    func applyCurrentColorScheme() {
        if AppSettings.shared.blueColorThemeIsEnabled {
            applyAlternateColorStyle()
        } else {
            applyDefaultConfiguration()
        }
    }
    
    /// Apply standard graph configuration to set axes and style in a default configuration.
    private func applyDefaultConfiguration() {
        chartView.customStyle = nil
        chartView.tintColor = tintColor
        chartView.headerView.detailLabel.textColor = .detailTextColor
        chartView.graphView.numberFormatter = numberFormatter
        chartView.graphView.yMinimum = 0
    }
    
    /// Apply alternate color configuration to set axes and style in a custom configuration.
    private func applyAlternateColorStyle() {
        chartView.customStyle = CustomStyle()
        chartView.tintColor = tintColor
        chartView.headerView.detailLabel.textColor = .detailTextColor
        chartView.graphView.numberFormatter = numberFormatter
        chartView.graphView.yMinimum = 0
    }
    
    /// Apply standard configuration to set axes and style for use as a header with an `.insetGrouped` tableView.
    private func applyHeaderStyle() {
        chartView.headerView.detailLabel.textColor = .secondaryLabel
        chartView.customStyle = ChartHeaderStyle()
    }
}


// MARK: - Custom Header Style

extension ChartView {
    /// A styler for using the chart as a header with an `.insetGrouped` tableView.
    struct ChartHeaderStyle: OCKStyler {
        var appearance: OCKAppearanceStyler {
            NoShadowAppearanceStyle()
        }
    }
    
    struct NoShadowAppearanceStyle: OCKAppearanceStyler {
        var shadowOpacity1: Float = 0
        var shadowRadius1: CGFloat = 0
        var shadowOffset1: CGSize = .zero
    }
}


// MARK: - Custom Color Style

extension ChartView {
    /// A styler using a custom color configuration
    struct CustomStyle: OCKStyler {
        var color: OCKColorStyler { CustomColors() }
        var appearance: OCKAppearanceStyler { NoShadowAppearanceStyle() }
    }
    
    struct CustomColors: OCKColorStyler {
        var secondaryCustomGroupedBackground: UIColor { .backgroundColor } // chart background color
        var label: UIColor { .textColor } // chart title and horizontal axis label color
    }
}
