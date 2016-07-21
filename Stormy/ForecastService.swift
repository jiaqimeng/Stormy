//
//  forecastService.swift
//  Stormy
//
//  Created by Meng Jiaqi on 6/20/16.
//  Copyright © 2016 Meng Jiaqi. All rights reserved.
//

import Foundation


struct ForecastService {
    
    let forecastAPIKey: String
    let forecastBaseURL: NSURL?
    
    init(APIKey: String) {
        forecastAPIKey = APIKey
        forecastBaseURL = NSURL(string: "https://api.forecast.io/forecast/\(forecastAPIKey)/")
        
    }
    
    func getForecast(lat: Double, long: Double, completion: CurrentWeather? -> Void) {
        if let forecastURL = NSURL(string: "\(lat),\(long)", relativeToURL: forecastBaseURL) {
            
            let networkOperation = NetworkOperation(url: forecastURL)
            
            networkOperation.downloadJSONFromURL {
                (let JSONDictionary) in
                let currentWeather = self.currentWeatherFromJSON(JSONDictionary)
                completion(currentWeather)
            }
        } else {
            print("Cound not construct a valid URL")
        }
    }
    
    func currentWeatherFromJSON(jsonDictionary: [String: AnyObject]?) -> CurrentWeather? {
        if var currentWeatherDictionary = jsonDictionary?["currently"] as? [String: AnyObject] {
            if let hourlyWeather = jsonDictionary?["hourly"] as? [String : AnyObject] {
                currentWeatherDictionary["hourly"] = hourlyWeather
                if let dailyWeather = jsonDictionary?["daily"] as? [String : AnyObject] {
                    currentWeatherDictionary["daily"] = dailyWeather
                }
            }
            return CurrentWeather(weatherDictionary: currentWeatherDictionary)
        } else {
            print("JSON dictionary returned nil for 'currently' key")
            return nil
        }
    }
}

