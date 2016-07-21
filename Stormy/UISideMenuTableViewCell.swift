//
//  UISideMenuTableViewCell.swift
//  Stormy
//
//  Created by Meng Jiaqi on 6/21/16.
//  Copyright © 2016 Meng Jiaqi. All rights reserved.
//

import UIKit
import SideMenu

class UISideMenuTableViewCell: MGSwipeTableCell {

    
    @IBOutlet weak var weatherIconView: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var cityTemperature: UILabel!
    
    @IBOutlet weak var gpsIndicator: UIImageView!
    
    var city: CityInfo? {
        didSet {
            updateUI()
        }
    }
    
    var isCurrentLocation = false {
        didSet {
            gpsIndicator.hidden = false
        }
    }
    
    var tempUnitFaren = true
    
    func updateUI() {
        
        if let temperature = city?.getWeatherInfo()?.temperature {
            if !tempUnitFaren {
                cityTemperature.text = "\(farenToCelcius(temperature))º"
            } else {
                cityTemperature.text = "\(temperature)º"
            }
            
        }
        if let icon = city?.getWeatherInfo()?.icon	 {
            
            
            weatherIconView.image = icon
        }
        if let cityName = city?.getCityName() {
            cityLabel.text = cityName
        }
        if let iconDescription = city?.getWeatherInfo()?.iconDescription, let temperature = city?.getWeatherInfo()?.temperature {
            let bgSelector = BackgroundColorSelector(frame: self.frame, currentWeather: iconDescription, currentTemp: temperature, tempUnit: true)
            self.backgroundColor = bgSelector.colorMix(.LeftToRight, colors: [bgSelector.seletColorByTemerature(), bgSelector.selectColorByWeather()])
            self.backgroundColor = self.backgroundColor?.colorWithAlphaComponent(0.5)
        }
    }
    
    
}
