//
//  Utility.swift
//  Stormy
//
//  Created by Meng Jiaqi on 6/21/16.
//  Copyright © 2016 Meng Jiaqi. All rights reserved.
//

import Foundation
import MapKit

func celciusToFaren(temperature: Int) -> Int {
    return Int(round(Double(temperature)*9/5)) + 32
}

func farenToCelcius(temperature: Int) -> Int {
    return Int(round(Double(temperature-32)*5/9))
}

public func initializeCityInfo(coordinate: (lat: Double, long: Double), weatherInfo: CurrentWeather, completion: (cityInfo: CityInfo?) -> Void) {
    let geoCoder = CLGeocoder()
    var returnCityInfo: CityInfo?
    geoCoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.lat, longitude: coordinate.long)) { (placemarks, error) in
        var placeMark: CLPlacemark!
        placeMark = placemarks?[0]
        if let city = placeMark.locality, let state = placeMark.administrativeArea, let countryCode = placeMark.ISOcountryCode {
            returnCityInfo = CityInfo(currentWeather: weatherInfo, cityCoordinate: coordinate, cityName: city, cityProvince: state, cityOfCountry: countryCode)
            
        }
        else {
            returnCityInfo = CityInfo(currentWeather: weatherInfo, cityCoordinate: coordinate, cityName: "N/A", cityProvince: "N/A", cityOfCountry: "N/A")
            
        }
        completion(cityInfo: returnCityInfo)
    }
    
}

func saveCitiesData(cities: [CityInfo]) {
    let prefs = NSUserDefaults.standardUserDefaults()
    let citiesData = NSKeyedArchiver.archivedDataWithRootObject(cities)
    prefs.setObject(citiesData, forKey: "cities")
    
}

func saveTempUnitData(unit: Bool) {
    let prefs = NSUserDefaults.standardUserDefaults()
    prefs.setValue(unit, forKey: "unit")
}

public struct TEMPERATURE_COLORS {
    static let belowZero = ["#54F8F1", "#54ECF8","#54DAF8","#54D3F8","#54C7F8","#54B7F8","#54A9F8","#54A1F8","#5491F8","#548DF8","#5484F8","#547EF8","#5471F8","#546AF8","#5463F8","#545DF8","#454FF7","#3B46F7","#3541F8","#2F3CF9"]
    static let zeroToTen = ["#54F8E2", "#54F8D3", "#54F8C1", "#54F8B6", "#54F8AA", "#54F8A1", "#54F897", "#54F88F", "#54F886", "#54F877"]
    static let ElevenToTwenty = ["#54F86A","#54F862","#54F859","#54F855","#5BF854","#6EF854","#81F854","#85F854","#8EF854","#97F854"]
    static let TwentyOneToThirty = ["#9BF854","#9EF854","#A4F854","#AAF854","#AFF854","#B3F854","#B6F854","#BEF854","#C3F854","#CEF854"]
    static let ThirtyOneToFourty = ["#D5F854","#E0F854","#E5F854","#EAF854","#EFF854","#F5F854","#F8F654","#F8F054","#F8EA54","#F8E254"]
    static let FourtyOneToFifty = ["#F8DB54","#F8D254","#F8CA54","#F8C354","#F8BD54","#F8B554","#F8AE54","#F8A754","#F8A154","#F89854"]
}

extension NSLocale {
    class func locales1(countryName1 : String) -> String {
        let locales : String = ""
        for localeCode in NSLocale.ISOCountryCodes() {
            let countryName = NSLocale.systemLocale().displayNameForKey(NSLocaleCountryCode, value: localeCode)!
            if countryName1.lowercaseString == countryName.lowercaseString {
                return localeCode
            }
        }
        return locales
    }
    
    
}