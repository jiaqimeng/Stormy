//
//  BackgroundColorSelector.swift
//  Stormy
//
//  Created by Meng Jiaqi on 6/21/16.
//  Copyright © 2016 Meng Jiaqi. All rights reserved.
//

import Foundation
import ChameleonFramework

struct BackgroundColorSelector {
    var frameToChangeColor: CGRect
    var currentWeatherInfo: String
    var currentTemperature: Int
    
    
    init(frame: CGRect, currentWeather: String, currentTemp: Int, tempUnit: Bool) {
        // if tempUnit is true, it is faren unit
        frameToChangeColor = frame
        currentTemperature = currentTemp
        currentWeatherInfo = currentWeather
        if tempUnit {
            // if not celcius, turn it into celcius
            currentTemperature = farenToCelcius(currentTemperature)
        }
    }
    
    func selectColorByWeather() -> UIColor {
        switch currentWeatherInfo {
        case "clear-day": return FlatSkyBlue()
        case "clear-night": return FlatNavyBlue()
        case "rain": return FlatBlue()
        case "snow": return FlatWhite()
        case "sleet": return FlatPowderBlue()
        case "wind": return FlatSkyBlueDark()
        case "fog": return FlatWhiteDark()
        case "cloudy": return FlatGray()
        case "partly-cloudy-day": return FlatSkyBlue()
        case "partly-cloudy-night": return FlatNavyBlue()
        default: return FlatSkyBlue()
        }
    }
    
    func seletColorByTemerature() -> UIColor {
        switch  currentTemperature {
        case let x where x <= 0:
            let absVal = abs(x)
            if absVal >= TEMPERATURE_COLORS.belowZero.count {
                return UIColor(rgba: TEMPERATURE_COLORS.belowZero[14])
            }
            return UIColor(rgba: TEMPERATURE_COLORS.belowZero[absVal])
        case let x where x < 10:
            return UIColor(rgba: TEMPERATURE_COLORS.zeroToTen[x])
        case let x where x < 20:
            return UIColor(rgba: TEMPERATURE_COLORS.ElevenToTwenty[x%10])
        case let x where x < 30:
            return UIColor(rgba: TEMPERATURE_COLORS.TwentyOneToThirty[x%20])
        case let x where x < 40:
            return UIColor(rgba: TEMPERATURE_COLORS.ThirtyOneToFourty[x%30])
        case let x where x < 50:
            return UIColor(rgba: TEMPERATURE_COLORS.FourtyOneToFifty[x%40])
        default:
            return UIColor(rgba: TEMPERATURE_COLORS.TwentyOneToThirty[4])
        }
    }
    
    func colorMix(gradientStyle: UIGradientStyle, colors: [UIColor]) -> UIColor {
        return GradientColor(gradientStyle, frame: frameToChangeColor, colors: colors)
    }
}
