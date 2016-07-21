//
//  CurrentWeather.swift
//  Stormy
//
//  Created by Meng Jiaqi on 6/20/16.
//  Copyright © 2016 Meng Jiaqi. All rights reserved.
//

import Foundation
import UIKit

enum Icon: String {
    case ClearDay = "clear-day"
    case ClearNight = "clear-night"
    case Rain = "rain"
    case Snow = "snow"
    case Sleet = "sleet"
    case Wind = "wind"
    case Fog = "fog"
    case Cloudy = "cloudy"
    case PartlyCloudyDay = "partly-cloudy-day"
    case PartlyCloudyNight = "partly-cloudy-night"
    
    func toImage() -> UIImage? {
        var imageName: String
        

        switch self {
        case .ClearDay:
            imageName = "clear-day.png"
            
        case .ClearNight:
            imageName = "clear-night.png"
        case .Rain:
            imageName = "rain.png"
        case .Snow:
            imageName = "snow.png"
        case .Sleet:
            imageName = "sleet.png"
        case .Wind:
            imageName = "wind.png"
        case .Fog:
            imageName = "fog.png"
        case .Cloudy:
            imageName = "cloudy.png"
        case .PartlyCloudyDay:
            imageName = "cloudy-day.png"
        case .PartlyCloudyNight:
            imageName = "cloudy-night.png"
        }
        return UIImage(named: imageName)
    }
}


public class CurrentWeather: NSObject, NSCoding {
    
    var temperature: Int?
    var humidity: Int?
    var precipProbability: Int?
    var summary: String?
    var icon: UIImage? = UIImage(named: "default.png")
    var iconDescription: String?
    var temperatureDailyMax: Int?
    var temperatureDailyMin: Int?
    var sunriseGMTTime: NSDate?
    var sunsetGMTTime: NSDate?
    var windSpeed: Int?
    var hourlyForecast: [CurrentWeather] = []
    
    init(weatherDictionary: [String: AnyObject]) {
        temperature = weatherDictionary["temperature"] as? Int
        if let humidityFloat = weatherDictionary["humidity"] as? Double {
            humidity = Int(humidityFloat * 100)
        } else {
            humidity = nil
        }
        if let precipProbabilyFloat = weatherDictionary["precipProbability"] as? Double {
            precipProbability = Int(precipProbabilyFloat * 100)
        } else {
            precipProbability = nil
        }
        summary = weatherDictionary["summary"] as? String
        
        if let iconString = weatherDictionary["icon"] as? String, let weatherIcon: Icon = Icon(rawValue: iconString) {
            iconDescription = iconString
            icon = weatherIcon.toImage()
        }
        windSpeed = weatherDictionary["windSpeed"] as? Int
        
        if let hourly = weatherDictionary["hourly"] as? [String: AnyObject] {
            if let hourlyData = hourly["data"] as? [[String: AnyObject]] {

                for hour in 1...24 {
                    if hour < hourlyData.count {
                        // FIXME: Index may error
                        let cw = CurrentWeather(weatherDictionary: hourlyData[hour-1])
                        hourlyForecast.append(cw)
                    }
                    
                }
            }
        }
        if let daily = weatherDictionary["daily"] as? [String: AnyObject] {
            if let dailyData = daily["data"] as? [[String: AnyObject]] {
                let today = dailyData[0]
                if let tempMax = today["temperatureMax"] as? Int {
                    temperatureDailyMax = tempMax
                }
                if let tempMin = today["temperatureMin"] as? Int {
                    temperatureDailyMin = tempMin
                }
                if let sunrise = today["sunriseTime"] as? Double {
                    sunriseGMTTime = NSDate(timeIntervalSince1970: sunrise)
                }
                if let sunset = today["sunsetTime"] as? Double {
                    sunsetGMTTime = NSDate(timeIntervalSince1970: sunset)
                }
                
            }
        }
        
        
    }
    
    override init() {
        temperature = 0
        humidity = 0
        precipProbability = 0
        summary = "N/A"
        iconDescription = "N/A"
    }
    
    required public convenience init(coder decoder: NSCoder) {
        self.init()
        temperature = decoder.decodeObjectForKey("temperature") as? Int
        humidity = decoder.decodeObjectForKey("humidity") as? Int
        precipProbability = decoder.decodeObjectForKey("precipProbability") as? Int
        summary = decoder.decodeObjectForKey("summary") as? String
        iconDescription = decoder.decodeObjectForKey("iconDescription") as? String
        icon = decoder.decodeObjectForKey("image") as? UIImage
        temperatureDailyMin = decoder.decodeObjectForKey("dailyMin") as? Int
        temperatureDailyMax = decoder.decodeObjectForKey("dailyMax") as? Int
        sunriseGMTTime = decoder.decodeObjectForKey("sunrise") as? NSDate
        sunsetGMTTime = decoder.decodeObjectForKey("sunset") as? NSDate
        windSpeed = decoder.decodeObjectForKey("windSpeed") as? Int
        hourlyForecast = (decoder.decodeObjectForKey("hourlyForecast") as? [CurrentWeather])!
        
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        if let temperature = temperature {
            coder.encodeObject(temperature, forKey: "temperature")
        }
        if let humidity = humidity {
            coder.encodeObject(humidity, forKey: "humidity")
        }
        if let precipProbability = precipProbability {
            coder.encodeObject(precipProbability, forKey: "precipProbability")
        }
        if let summary = summary {
            coder.encodeObject(summary, forKey: "summary")
        }
        if let iconDescription = iconDescription {
            coder.encodeObject(iconDescription, forKey: "iconDescription")
        }
        if let icon = icon {
            coder.encodeObject(icon, forKey: "image")
        }
        if let temperatureDailyMin = temperatureDailyMin {
            coder.encodeObject(temperatureDailyMin, forKey: "dailyMin")
        }
        if let temperatureDailyMax = temperatureDailyMax {
            coder.encodeObject(temperatureDailyMax, forKey: "dailyMax")
        }
        if let sunriseGMTTime = sunriseGMTTime {
            coder.encodeObject(sunriseGMTTime, forKey: "sunrise")
        }
        if let sunsetGMTTime = sunsetGMTTime {
            coder.encodeObject(sunsetGMTTime, forKey: "sunset")
        }
        if let windSpeed = windSpeed {
            coder.encodeObject(windSpeed, forKey: "windSpeed")
        }
        coder.encodeObject(hourlyForecast, forKey: "hourlyForecast")
    }
    
    
}

