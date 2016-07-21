//
//  CityInfo.swift
//  Stormy
//
//  Created by Meng Jiaqi on 6/21/16.
//  Copyright © 2016 Meng Jiaqi. All rights reserved.
//

import Foundation
import MapKit
import TimeZoneLocate

public class CityInfo: NSObject, NSCoding {
    private var weatherInfo: CurrentWeather!
    private var coordinate: (Double, Double)!
    private var city: String!
    private var cityProvince: String!
    private var cityOfCountry: String!
//    private var time: String? // format is hh:mm, i.e 10:58
    
    required convenience public init(coder decoder: NSCoder) {
        self.init()
        self.city = decoder.decodeObjectForKey("name") as! String
        
        self.cityProvince = decoder.decodeObjectForKey("province") as! String
        let coordinateRawData = decoder.decodeObjectForKey("coordinate") as! [String: Double]
        self.coordinate = (coordinateRawData["lat"]!, coordinateRawData["long"]!)
        self.weatherInfo = decoder.decodeObjectForKey("weatherinfo") as! CurrentWeather
        self.cityOfCountry = decoder.decodeObjectForKey("country") as! String
    }
    
    override init() {
        weatherInfo = CurrentWeather()
        coordinate = (0.0, 0.0)
        city = "N/A"
        cityProvince = "N/A"
        cityOfCountry = "N/A"
        
    }
    init(currentWeather: CurrentWeather, cityCoordinate: (lat: Double, long: Double), cityName: String, cityProvince: String, cityOfCountry: String) {
        super.init()
        self.weatherInfo = currentWeather
        self.coordinate = cityCoordinate
        self.city = cityName
        self.cityProvince = cityProvince
        self.cityOfCountry = cityOfCountry
//        self.time = getPreciseDateOfLocation(cityCoordinate.lat, long: cityCoordinate.long)
        
        
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let rhs = object as? CityInfo {
            return self == rhs
        }
        return false
    }
    func getCityName() -> String? {
        return city
    }
    
//    func getCityTime() -> String? {
//        return time
//    }
    func getCountryCode() -> String {
        return cityOfCountry
    }
    func getPreciseDateOfLocation(lat: Double, long: Double) -> String {
        let loc = CLLocation(latitude: lat, longitude: long)
        let timeZoneAbbrev = loc.timeZone.abbreviation
        let currentDate = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(abbreviation: timeZoneAbbrev!)
        dateFormatter.dateFormat = "hh:mm"
        return dateFormatter.stringFromDate(currentDate)
    }
    
    // use to get sunrise and sunset hour
    func changeGMTDateToLocalHour(lat: Double, long: Double, GMTNSDate: NSDate) -> String {
        let loc = CLLocation(latitude: lat, longitude: long)
        var timeZoneDiff = loc.timeZone.secondsFromGMT
        if (getCountryCode() == "CN") {
            // Not sure why the timezones of some cities in China has been located in North Korea. I have to manually reset the seconds.
            timeZoneDiff = 8*3600
        }
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: timeZoneDiff)
        dateFormatter.dateFormat = "hh:00"
        return dateFormatter.stringFromDate(GMTNSDate)
    }
    
    func getWeatherInfo() -> CurrentWeather? {
        return weatherInfo
    }
    func getCoordinateInfo() -> (lat: Double, long: Double) {
        return coordinate
    }
    
    func getCityProvince() -> String? {
        return cityProvince
    }
    func setWeatherInfo(currentWeather: CurrentWeather) {
        self.weatherInfo = currentWeather
    }
    public func encodeWithCoder(coder: NSCoder) {
        if let city = city { coder.encodeObject(city, forKey: "name") }
        if let cityProvince = cityProvince { coder.encodeObject(cityProvince, forKey: "province") }
        if let cityOfCountry = cityOfCountry { coder.encodeObject(cityOfCountry, forKey: "country") }
        if let weatherInfo = weatherInfo { coder.encodeObject(weatherInfo, forKey: "weatherinfo") }
        if let coordinate = coordinate { coder.encodeObject(["lat": coordinate.0, "long": coordinate.1], forKey: "coordinate") }
        
        
    }
    
}

public func ==(lhs: CityInfo, rhs: CityInfo) -> Bool {
    return  lhs.city == rhs.city
}