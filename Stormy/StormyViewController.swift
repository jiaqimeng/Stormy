//
//  ViewController.swift
//  Stormy
//
//  Created by Meng Jiaqi on 6/20/16.
//  Copyright © 2016 Meng Jiaqi. All rights reserved.
//

import UIKit
import MapKit
import Foundation
import SideMenu
import ChameleonFramework
import ElasticTransition
import TimeZoneLocate
import ASValueTrackingSlider
import Charts

class StormyViewController: UIViewController, CLLocationManagerDelegate, GoogleACViewControllerDelegate, LTMorphingLabelDelegate, ElasticMenuTransitionDelegate, ASValueTrackingSliderDataSource, ChartViewDelegate {
    
    // MARK: IBOutlet
    @IBOutlet weak var currentTemperatureLabel: LTMorphingLabel?
    @IBOutlet weak var currentHumidityLabel: LTMorphingLabel?
    @IBOutlet weak var currentPrecipitationLabel: LTMorphingLabel?
    @IBOutlet weak var currentWeatherIcon: UIImageView?
    @IBOutlet var stormyView: UIView!
    @IBOutlet weak var unitIndicator: UISegmentedControl!
    @IBOutlet weak var currentLocation: LTMorphingLabel!
    @IBOutlet weak var currentWeatherSummary: LTMorphingLabel!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var currentTime: LTMorphingLabel!
    @IBOutlet weak var gpsIndicator: UIImageView!
    @IBOutlet weak var timeStampSlider: ASValueTrackingSlider!
    @IBOutlet weak var temperatureLineChart: LineChartView!
    @IBOutlet weak var precipLineChart: LineChartView!
    @IBOutlet weak var dailyHigh: LTMorphingLabel!
    @IBOutlet weak var dailyLow: LTMorphingLabel!
    // MARK: IBAction
    @IBAction func pullMenu(sender: AnyObject) {
        transition.edge = .Left
        transition.startingPoint = sender.center
        performSegueWithIdentifier("LeftMenuShowSegue", sender: self)
        
    }
    @IBAction func refreshWeather() {
        toggleRefreshAnimation(true)
        loadCitiesData()
        if isCurrentLocation {
            updateGPSLocation()
        } else {
            retrieveWeatherForecastAtLocation(coordinate.lat, long: coordinate.long)
        }
        UIView.animateWithDuration(1) { 
            self.timeStampSlider.setValue(-2.0, animated: true)
            self.handleSlide(-2.0)
        }
        
        
    }
    @IBAction func changeTime(sender: UISlider) {
        handleSlide(sender.value)
    }
    @IBAction func changeTempUnit(sender: UISegmentedControl) {
        unit = sender.selectedSegmentIndex == 1 ? true : false
    }

    
    let locationManager = CLLocationManager()
    
    // MARK: CONSTANTS
    struct TemperatureUnit {
        static let Faren = true
        static let Celcius = false
    }
    
    struct ID {
        static let LeftMenuShowSegue = "LeftMenuShowSegue"
        static let SearchPlaceSegue = "SearchPlaceSegue"
    }
    
    // MARK: APIKEY
    private let forcastAPIKey = "37b820eed9f692c73058a673b94a2a75" // needs to be encrypted
    private let googleImageAPIKey = "AIzaSyAdbDColYfCzrDWiNtc7VqcqIjVQqWF0dc" // needs to be encrypted
    
    private var gradientLayer: CAGradientLayer = CAGradientLayer()
    private var lastTemperature: Int = 0
    private var animationDuration: Double = 1.0
    private var typingEffect = 0
    var cities = [CityInfo]()
    var isCurrentLocation = true
    
    private var timer = NSTimer()
    private var dateFormatter = NSDateFormatter()
    
    private var unit = TemperatureUnit.Faren {
        didSet {
            if let currentTemperatureString = currentTemperatureLabel?.text?.substringToIndex(currentTemperatureLabel!.text!.endIndex.predecessor()) {
                if var currentTemperatureInt = Int(currentTemperatureString) {
                    if unit == TemperatureUnit.Faren {
                        currentTemperatureInt = celciusToFaren(currentTemperatureInt)
                        
                    } else {
                        currentTemperatureInt = farenToCelcius(currentTemperatureInt)
                    }
                currentTemperatureLabel?.text = "\(currentTemperatureInt)º"
                }
            }
            if let currentDailyHighString = dailyHigh?.text?.substringToIndex(dailyHigh.text.endIndex.predecessor()), let currentDailyLowString =  dailyLow?.text?.substringToIndex(dailyLow.text.endIndex.predecessor()) {
                if var dailyHighInt = Int(currentDailyHighString), var dailyLowInt = Int(currentDailyLowString) {
                    if unit == TemperatureUnit.Faren {
                        dailyHighInt = celciusToFaren(dailyHighInt)
                        dailyLowInt = celciusToFaren(dailyLowInt)
                        
                    } else {
                        dailyHighInt = farenToCelcius(dailyHighInt)
                        dailyLowInt = farenToCelcius(dailyLowInt)
                    }
                    dailyLow.text = "\(dailyLowInt)º"
                    dailyHigh.text = "\(dailyHighInt)º"

                }
            }
        }
    }
    
    // temporaryWeather is used as a carrier to deliver hourly data
    private var temporaryWeather: CurrentWeather?
    
    var coordinate: (lat: Double, long: Double) = (37.8267, -122.423) {
        didSet {
            
            self.retrieveWeatherForecastAtLocation(coordinate.lat, long: coordinate.long)
            setupTimer()
            setDataForChart()
            UIView.animateWithDuration(1.0) { 
                self.timeStampSlider.setValue(-2.0, animated: true)
                self.temporaryWeather = nil
            }
        }
    }
    
    var transition = ElasticTransition()
    var lgr = UIScreenEdgePanGestureRecognizer()
    
    var cityInfo: CityInfo?
    
    func setUnit(unit: Bool) {
        self.unit = unit
    }
    
    func updateParticularWeatherInfoUI(currentWeather: CurrentWeather) {
        dispatch_async(dispatch_get_main_queue()) {
            if var temperature = currentWeather.temperature {
                if !self.unit {
                    temperature = farenToCelcius(temperature)
                }
                self.currentTemperatureLabel?.text = "\(temperature)º"
            }
            if let humidity = currentWeather.humidity {
                self.currentHumidityLabel?.text = "\(humidity)%"
            }
            if let precip = currentWeather.precipProbability {
                self.currentPrecipitationLabel?.text = "\(precip)%"
            }
            if let icon = currentWeather.icon {
                self.currentWeatherIcon?.image = icon
            }
            if let summary = currentWeather.summary {
                self.currentWeatherSummary?.text = summary
                
                
            }
            if let temperature = currentWeather.temperature, let summary = currentWeather.iconDescription {
                let newBackgroundColor = self.getBackgroundColor(summary, currentTemp: temperature, tempUnit: true)
                if self.gradientLayer.animationForKey("animateGradient") == nil {
                    self.animateBackground(newBackgroundColor)
                }
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(self.animationDuration*Double(NSEC_PER_SEC))), dispatch_get_main_queue(), { 
//                    
//                })
                
            }
            self.setHighLowToday()
            self.setDataForChart()
            self.toggleRefreshAnimation(false)
        }
    }
    
    // MARK: UPDATE UI
    func updateWeatherInfoUI() {
        
        if let cityInfo = self.cityInfo {
            gpsIndicator.hidden = !isCurrentLocation
            if let cityName = cityInfo.getCityName(), let cityProvince = cityInfo.getCityProvince() {
                self.currentLocation.text = "\(cityName), \(cityProvince)"
            }
            if let currentWeather = cityInfo.getWeatherInfo() {
                dispatch_async(dispatch_get_main_queue()) {
                    if var temperature = currentWeather.temperature {
                        if !self.unit {
                            temperature = farenToCelcius(temperature)
                        }
                        /* below is the counting animation implementation
                        
                        ----------DO NOT DELETE!!!!----------
 
                        let lastTemperatureString = self.currentTemperatureLabel!.text?.substringToIndex(self.currentTemperatureLabel!.text!.endIndex.predecessor())
                        let lastTemperatureInt = Int(lastTemperatureString!) ?? 0
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                            let diff = abs(lastTemperatureInt - temperature)
                            if diff != 0 {
                                for i in 0...diff {
                                    let normalizeDiff = Double(i)/Double(diff)
                                    usleep(UInt32(120000*normalizeDiff))
                                    //                                if abs(lastTemperatureInt - temperature) - i <= 10 {
                                    //                                    usleep(UInt32(i*20000))
                                    //                                }
                                    //                                else {usleep(20000) } // sleep in microseconds
                                    dispatch_async(dispatch_get_main_queue(), {
                                        if lastTemperatureInt < temperature {
                                            self.currentTemperatureLabel?.text = "\(lastTemperatureInt + i)º"
                                        } else {
                                            self.currentTemperatureLabel?.text = "\(lastTemperatureInt - i)º"
                                        }
                                    });
                                }
                            }
                        });
                         
                        */
                        
                        self.currentTemperatureLabel?.text = "\(temperature)º"
                        
                        
                    }
                    if let humidity = currentWeather.humidity {
                        self.currentHumidityLabel?.text = "\(humidity)%"
                    }
                    if let precip = currentWeather.precipProbability {
                        self.currentPrecipitationLabel?.text = "\(precip)%"
                    }
                    if let icon = currentWeather.icon {
                        self.currentWeatherIcon?.image = icon
                    }
                    if let summary = currentWeather.summary {
                        self.currentWeatherSummary?.text = summary
                        
                        
                    }
                    if let temperature = currentWeather.temperature, let summary = currentWeather.iconDescription {
                        let newBackgroundColor = self.getBackgroundColor(summary, currentTemp: temperature, tempUnit: true)
                        self.animateBackground(newBackgroundColor)
                    }
                    self.setHighLowToday()
                    self.setDataForChart()
                    self.toggleRefreshAnimation(false)
                    
                }
            }
        }
        
    }
    
    
    

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: SYSTEM CALL
    override func viewDidLoad() {
        super.viewDidLoad()

        loadCitiesData()
        loadTempUnitData()
        unitIndicator.selectedSegmentIndex = unit == true ? 1 : 0
        setupSideBarMenu()
//        setupBlurEffect()
        addBackgroundAnimationLayer()
        if isCurrentLocation {
            // In this case, we intentionally did not pass cityInfo. We update our gps location again, which changes coordinate and hence calls retrieveWeatherForecastAtLocation() AND updateWeatherInfoUI(). Also, it sets the cityInfo to current location
            updateWeatherInfoUI()
            updateGPSLocation()
            
        } else {
            // In this case, we intentionally passed cityInfo, so the following method will always be called correctly
            coordinate = (cityInfo?.getCoordinateInfo())!
            updateWeatherInfoUI()

        }
        
        setupTimer()
        self.timeStampSlider.dataSource = self
        setupSlider()
        setupTemperatureLineChart(temperatureLineChart)
        setupTemperatureLineChart(precipLineChart)
        temperatureLineChart.legend.position = .AboveChartLeft
        precipLineChart.legend.position = .AboveChartCenter
        precipLineChart.leftAxis.axisMaxValue = 100
        setDataForChart()
        // setupTimer() must be called at last because only in this state the coordinate has been settled
        

        // Do any additional setup after loading the view, typically from a nib.
        /* 
         JUST FOR UNDERSTANDING THE CONCEPT OF PLIST
         
        if let plistPath = NSBundle.mainBundle().pathForResource("CurrentWeather", ofType: "plist"),
            let weatherDictionary = NSDictionary(contentsOfFile: plistPath),
        let currentWeatherDictionary = weatherDictionary["currently"] as? [String: AnyObject] {
            
            let currentWeather = CurrentWeather(weatherDictionary: currentWeatherDictionary)
            
            currentTemperatureLabel?.text = "\(currentWeather.temperature)º"
            currentHumidityLabel?.text = "\(currentWeather.humidity)%"
            currentPrecipitationLabel?.text = "\(currentWeather.precipProbability)%"
            }
         
         */
//        retrieveWeatherForecast()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // FIXED: we comment out the following line because when we delete a city in left menu and tap on another city, this view will disappear and automatically call this function. The modification to the cities in left menu: such as delete, will be overwritten. In order to prevent this case, we comment out this line
//        saveCitiesData(cities)
        saveTempUnitData(unit)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: PREPARE FOR SEGUE
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        loadCitiesData() // We have to load data here before any further implementation because the following method may trigger saveCitiesData which may overwrite what we have done in SideMenu
        if segue.identifier == ID.LeftMenuShowSegue {
            
            /* use SideMenu
            if let sideMenuNavVC = segue.destinationViewController as? UISideMenuNavigationController {
                if let sideMenuTableViewVC = sideMenuNavVC.topViewController as? UISideMenuTableViewController {
                    // FIXME:
                    sideMenuTableViewVC.cities = cities
                    sideMenuTableViewVC.tempUnitFaren = self.unit
                    sideMenuTableViewVC.tableView.reloadData()
                    
                    saveTempUnitData(unit)
                    stopUpdateGPSLocation()
                    
                }
            }
             */
            if let sideMenuTableViewVC = segue.destinationViewController as? UISideMenuTableViewController {
                
                    sideMenuTableViewVC.transitioningDelegate = transition
                    sideMenuTableViewVC.modalPresentationStyle = .Custom
                    sideMenuTableViewVC.cities = cities
                    sideMenuTableViewVC.tempUnitFaren = self.unit
                    sideMenuTableViewVC.tableView.reloadData()
                    
                    saveTempUnitData(unit)
                    stopUpdateGPSLocation()
            }
            
            
        }
        if segue.identifier == ID.SearchPlaceSegue {
            if let searchPlaceNavVC = segue.destinationViewController as? UINavigationController {
                if let googleACVC = searchPlaceNavVC.topViewController as? GoogleACViewController {
                    stopUpdateGPSLocation()
                    googleACVC.delegate = self
                }
                
            }
        }
    }
    
    @objc func tick() {
        self.currentTime.text = dateFormatter.stringFromDate(NSDate())
    }
    
    func setupBlurEffect() {
        let extraLightBlur = UIBlurEffect(style: .ExtraLight)
        let extraLightBlurView = UIVisualEffectView(effect: extraLightBlur)
        self.view.addSubview(extraLightBlurView)
    }
    func setHighLowToday() {
        if let dailyMax = cityInfo?.getWeatherInfo()?.temperatureDailyMax, let dailyMin = cityInfo?.getWeatherInfo()?.temperatureDailyMin {
            if !unit {
                self.dailyHigh.text = "\(farenToCelcius(dailyMax))º"
                self.dailyLow.text = "\(farenToCelcius(dailyMin))º"
            } else {
                self.dailyHigh.text = "\(dailyMax)º"
                self.dailyLow.text = "\(dailyMin)º"
            }
        }
        
    }
    func setupSlider() {
        self.timeStampSlider.popUpViewCornerRadius = 3.0;
        self.timeStampSlider.popUpViewColor = UIColor.clearColor()
        self.timeStampSlider.font = UIFont(name: "Helvetica Neue", size: 15)
        self.timeStampSlider.textColor = FlatWhite()
        self.timeStampSlider.autoAdjustTrackColor = false
        self.timeStampSlider.setThumbImage(UIImage(named: "time"), forState: .Normal)
        self.timeStampSlider.popUpViewHeightPaddingFactor = 0.6
    }
    
    func slider(slider: ASValueTrackingSlider!, stringForValue value: Float) -> String! {
        let hour = Int(value)
        var result = ""
        if self.currentTime.text == "" {
            return ""
        }
        if self.currentTime.text[self.currentTime.text.endIndex.predecessor()] == "M" {
            if var hh = self.currentTime?.text.substringToIndex(self.currentTime.text.startIndex.advancedBy(2)), var ap = self.currentTime?.text.substringFromIndex(self.currentTime.text.endIndex.advancedBy(-2)) {
                if hh[hh.startIndex.advancedBy(1)] == ":" {
                    hh.removeAtIndex(hh.startIndex.advancedBy(1))
                }
                if hour < 0 {
                    result = "\(hh):00 \(ap)"
                }
                else {
                    if let tempHour = Int(hh) {
                        let morning = ap == "AM"
                        let newHour = tempHour % 12 + hour + 1
                        let changeAp = newHour >= 12
                        if morning {
                            if changeAp  {
                                ap = "PM"
                            }
                        } else {
                            if changeAp {
                                ap = "AM"
                            }
                        }
                        let modHour = newHour % 12
                        var newHourString = "\(modHour)"
                        if ap == "PM" && modHour == 0 {
                            newHourString = "12"
                        }
                        result = "\(newHourString):00 \(ap)"
                    }
                }
                
            }
        } else {
            if let hh = self.currentTime?.text.substringToIndex(self.currentTime.text.startIndex.advancedBy(2)) {
                if hour < 0 {
                    result = "\(hh):00"
                } else {
                    let tempHour = Int(hh)
                    let newHour = (tempHour! + hour + 1) % 24
                    result = "\(newHour):00"
                }
            }
        }
        return result
    }
    
    func setupTimer() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(StormyViewController.tick), userInfo: nil, repeats: true)
        let loc = CLLocation(latitude: coordinate.lat, longitude: coordinate.long)
        var timeZoneDiff = loc.timeZone.secondsFromGMT
        if (cityInfo?.getCountryCode() == "CN") {
            // Not sure why the timezones of some cities in China has been located in North Korea. I have to manually reset the seconds.
            timeZoneDiff = 8*3600
        }
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: timeZoneDiff)
//        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.dateFormat = "h:mm a"
    }
    
    // MARK: UI RELATED UTILITY
    func setupLeftEdgePanTransitionStyle() {
        transition.sticky = false
        transition.showShadow = false
        transition.stiffness = 0.6
        transition.damping = 0.6
        transition.radiusFactor = 0.1
        transition.useTranlation = false
    
        transition.panThreshold = 0.3
        transition.transformType = .Subtle

    }
    
    func addBackgroundAnimationLayer() {
        gradientLayer.frame = stormyView.bounds
        gradientLayer.colors = [UIColor.redColor().CGColor, UIColor.yellowColor().CGColor]
        stormyView.backgroundColor = UIColor.clearColor()
        stormyView.layer.insertSublayer(gradientLayer, atIndex: 0)
    }
    
    func handleSlide(value: Float) {
        let index = Int(value)
        if index < 0 {
            // if index < 0, or = -1, as which I set the min value, we set the current weather as the temporaryWeather
            temporaryWeather = cityInfo?.getWeatherInfo()

        } else {
        if let hrf = cityInfo?.getWeatherInfo()?.hourlyForecast {
            if index < hrf.count {
                temporaryWeather = hrf[index]
            }
        }
        }
        if temporaryWeather != nil {
            updateParticularWeatherInfoUI(temporaryWeather!)
        }
        
    }
    
    func handlePan(pan: UIPanGestureRecognizer) {
        if pan.state == .Began {
            transition.edge = .Left
            transition.startInteractiveTransition(self, segueIdentifier: ID.LeftMenuShowSegue, gestureRecognizer: pan)
        }
        else {
            transition.updateInteractiveTransition(gestureRecognizer: pan)
        }
    }
    
    func setupTemperatureLineChart(chart: LineChartView) {
        chart.delegate = self
        chart.descriptionText = ""
        chart.noDataTextDescription = "no data available"
        chart.drawBordersEnabled = false
        //        temperatureLineChart.leftAxis.enabled = false
        //        temperatureLineChart.rightAxis.drawZeroLineEnabled = false
        //        temperatureLineChart.rightAxis.drawGridLinesEnabled = false
        //        temperatureLineChart.xAxis.drawAxisLineEnabled = false
        //        temperatureLineChart.xAxis.drawGridLinesEnabled = false
        
//        chart.legend.enabled = false
        
        chart.xAxis.drawLabelsEnabled = true
        chart.xAxis.labelPosition = .Bottom
        chart.xAxis.enabled = false
        chart.leftAxis.enabled = false
        chart.rightAxis.enabled = false
        //        xAxis.axisMaxValue = 22
        
        chart.drawGridBackgroundEnabled = false
        chart.dragEnabled = true
        chart.setScaleEnabled(false)
        chart.pinchZoomEnabled = false
        chart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        
    }

    
    func setDataForChart() {
        var xValOfHour: [Int] = []
        for i in -3...23 {
            xValOfHour.append(i)
        }
        var yValOfTemp: [ChartDataEntry] = []
        var yValOfPrecip: [ChartDataEntry] = []
        if let city = self.cityInfo, let futureWeather = self.cityInfo?.getWeatherInfo()?.hourlyForecast {
            for i in 0...26 {
                if i < 3 {
                    if var temperature = city.getWeatherInfo()?.temperature {
                        if !unit {
                            temperature = farenToCelcius(temperature)
                        }
                        yValOfTemp.append(ChartDataEntry(value: Double(temperature), xIndex: i))
                        
                    }
                    if let precipPropability = city.getWeatherInfo()?.precipProbability {
                        yValOfPrecip.append(ChartDataEntry(value: Double(precipPropability), xIndex: i))
                    }
                    
                    
                } else {
                    if i < futureWeather.count+3 {
                        if var temperature = futureWeather[i-3].temperature {
                            if !unit {
                                temperature = farenToCelcius(temperature)
                            }
                            yValOfTemp.append(ChartDataEntry(value: Double(temperature), xIndex: i))
                        }
                        if let precipPropability = futureWeather[i-3].precipProbability {
                            yValOfPrecip.append(ChartDataEntry(value: Double(precipPropability), xIndex: i))
                        }
                    }
                }
                
            }
        }
        
        var temperatureLineDataSet: LineChartDataSet
        var precipLineDataSet: LineChartDataSet
        if precipLineChart.data?.dataSetCount > 0 {
            precipLineDataSet = precipLineChart.lineData?.getDataSetByIndex(0) as! LineChartDataSet
            precipLineDataSet.yVals = yValOfPrecip
            precipLineChart.data?.xValsObjc = xValOfHour
            precipLineChart.data?.notifyDataChanged()
            precipLineChart.notifyDataSetChanged()
            
        } else {
            precipLineDataSet = LineChartDataSet(yVals: yValOfPrecip, label: "Rain Propability")
            
            precipLineDataSet.mode = .CubicBezier
            precipLineDataSet.drawCirclesEnabled = false
            precipLineDataSet.lineWidth = 1.2
            precipLineDataSet.circleRadius = 4.0
            precipLineDataSet.setCircleColor(FlatWhite())
            precipLineDataSet.highlightColor = FlatWhite()
            precipLineDataSet.setColor(FlatBlue())
            let gradientColors: CFArrayRef = [FlatBlue().CGColor, FlatBlue().CGColor]
            let gradient = CGGradientCreateWithColors(nil, gradientColors, nil)
            precipLineDataSet.fillAlpha = 0.3
            precipLineDataSet.fill = ChartFill.fillWithLinearGradient(gradient!, angle: 90)
            precipLineDataSet.drawFilledEnabled = true
            
            var dataSets: [LineChartDataSet] = []
            dataSets.append(precipLineDataSet)
            precipLineChart.data = LineChartData(xVals: xValOfHour, dataSets: dataSets)
            precipLineChart.data?.highlightEnabled = false
            
            for i in (precipLineChart.data?.dataSets)! {
                i.drawValuesEnabled = false
            }
            
        }
        if temperatureLineChart.data?.dataSetCount > 0 {
            temperatureLineDataSet = temperatureLineChart.lineData?.getDataSetByIndex(0) as! LineChartDataSet
            temperatureLineDataSet.yVals = yValOfTemp
            temperatureLineChart.data?.xValsObjc = xValOfHour
            temperatureLineChart.data?.notifyDataChanged()
            temperatureLineChart.notifyDataSetChanged()
            
        } else {
            temperatureLineDataSet = LineChartDataSet(yVals: yValOfTemp, label: "Temperature")
            
            temperatureLineDataSet.mode = .CubicBezier
            temperatureLineDataSet.drawCirclesEnabled = false
            temperatureLineDataSet.lineWidth = 1.2
            temperatureLineDataSet.circleRadius = 4.0
            temperatureLineDataSet.setCircleColor(FlatWhite())
            temperatureLineDataSet.highlightColor = FlatWhite()
            temperatureLineDataSet.setColor(FlatGreen())
            let gradientColors: CFArrayRef = [FlatMint().CGColor, FlatMint().CGColor]
            let gradient = CGGradientCreateWithColors(nil, gradientColors, nil)
            temperatureLineDataSet.fillAlpha = 0.3
            temperatureLineDataSet.fill = ChartFill.fillWithLinearGradient(gradient!, angle: 90)
            temperatureLineDataSet.drawFilledEnabled = true
            
            var dataSets: [LineChartDataSet] = []
            dataSets.append(temperatureLineDataSet)
            temperatureLineChart.data = LineChartData(xVals: xValOfHour, dataSets: dataSets)
            temperatureLineChart.data?.highlightEnabled = false

            for i in (temperatureLineChart.data?.dataSets)! {
                i.drawValuesEnabled = false
            }
            
        }
        
    }
    
    
    func setupSideBarMenu() {
        self.navigationController?.navigationBarHidden = true
        setupLeftEdgePanTransitionStyle()
        lgr.addTarget(self, action: #selector(StormyViewController.handlePan(_:)))
        lgr.edges = .Left
        view.addGestureRecognizer(lgr)
    }
    
    func setupTextLabelDelegate() {
        self.currentHumidityLabel?.delegate = self
        self.currentHumidityLabel?.morphingEffect = LTMorphingEffect(rawValue: typingEffect)!
        self.currentTemperatureLabel?.delegate = self
        self.currentTemperatureLabel?.morphingEffect = LTMorphingEffect(rawValue: typingEffect)!
        self.currentPrecipitationLabel?.delegate = self
        self.currentPrecipitationLabel?.morphingEffect = LTMorphingEffect(rawValue: typingEffect)!
        self.currentLocation.delegate = self
        self.currentLocation.morphingEffect = LTMorphingEffect(rawValue: typingEffect)!
        self.currentWeatherSummary.delegate = self
        self.currentWeatherSummary.morphingEffect = LTMorphingEffect(rawValue: typingEffect)!
    }
    func updateGPSLocation() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.distanceFilter = 500
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopUpdateGPSLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocation = locations.last!
        if (locValue.horizontalAccuracy < 0) { return }
        let locationAge: NSTimeInterval = -locValue.timestamp.timeIntervalSinceNow
        if locationAge > 5.0 {
            return
        }
        // if this is not in the current weather page, we do not update the current coordinate
        if isCurrentLocation {
            coordinate = (locValue.coordinate.latitude, locValue.coordinate.longitude)
        }
        
//        let geoCoder = CLGeocoder()
//        geoCoder.reverseGeocodeLocation(CLLocation(latitude: locValue.coordinate.latitude, longitude: locValue.coordinate.longitude)) { (placemarks, error) in
//            var placeMark: CLPlacemark?
//            placeMark = placemarks?[0]
//            if let pM = placeMark {
//            if let city = pM.locality, let state = pM.administrativeArea {
//                self.currentLocation?.text = "\(city), \(state)"
//                }
//            }
//        }
    }
    
    func retrieveCurrentLocationWeatherForecast() {
        let forecastService = ForecastService(APIKey: forcastAPIKey)
        forecastService.getForecast(coordinate.lat, long: coordinate.long) {
            (let currently) in
            if let currentWeather = currently {
                initializeCityInfo(self.coordinate, weatherInfo: currentWeather) { cityInfo in
                    if cityInfo != nil {
                        if !self.replaceCityAtIndexZeroWith(cityInfo!) {
                            self.addCityToList(cityInfo!)
                        }
                        self.cityInfo = cityInfo
                        self.updateWeatherInfoUI()

                    }
                }
            }
        }
        
    }
    
    func retrieveWeatherForecastAtLocation(lat: Double, long: Double) {
        let forecastService = ForecastService(APIKey: forcastAPIKey)
        forecastService.getForecast(lat, long: long) {
            (let currently) in
            if let currentWeather = currently {
                // Update UI
                // mark Jul 11,
                if self.isCurrentLocation {
                    initializeCityInfo((lat,long), weatherInfo: currentWeather) { cityInfo in
                        if cityInfo != nil {
                            self.cityInfo = cityInfo
                            if !self.replaceCityAtIndexZeroWith(cityInfo!) {
                                self.addCityToList(cityInfo!)
                            }
                        }
                        self.updateWeatherInfoUI()
                    }
                } else {
                    // if it is not the current location, we just update the weather in this city without changing its city name.
                    self.cityInfo?.setWeatherInfo(currentWeather)
                    self.addCityToList(self.cityInfo!)
                    self.updateWeatherInfoUI()
                }
                
                // mark Jul 11
//                if self.cityInfo == nil {
//
//                    initializeCityInfo(self.coordinate, weatherInfo: currentWeather) { cityInfo in
//                        if cityInfo != nil {
//                            if !self.replaceCityAtIndexZeroWith(cityInfo!) {
//                                self.addCityToList(cityInfo!)
//                            }
//                        }
//                        self.cityInfo = cityInfo
//                        self.updateWeatherInfoUI()
//                    }
//                } else {
//                    // mark Jun 23, 2016; if cityInfo is not nil, just update the weather and replace the old city with the new one
//                    // mark Jun 24, 2016; we should not count on that, consider the case that we are in current location tab, if we want to manually update the location and show the new weather in new city, the following line will overwrite anything that we have got. Instead, a solution that I can come up with right now is to set a if state ment below
//                    if self.isCurrentLocation {
//                        initializeCityInfo((lat,long), weatherInfo: currentWeather) { cityInfo in
//                            if cityInfo != nil {
//                                self.cityInfo = cityInfo
//                                if !self.replaceCityAtIndexZeroWith(cityInfo!) {
//                                    self.addCityToList(cityInfo!)
//                                }
//                            }
//                            self.updateWeatherInfoUI()
//                        }
//                    } else {
//                        // if it is not the current location, we just update the weather in this city without changing its city name.
//                        self.cityInfo?.setWeatherInfo(currentWeather)
//                        self.addCityToList(self.cityInfo!)
//                        self.updateWeatherInfoUI()
//                    }
//                }
                
                
                
            }
        }
    }
    
    func initializeNA() {
        self.currentTemperatureLabel?.text = "N/A"
        self.currentHumidityLabel?.text = "N/A"
        self.currentPrecipitationLabel?.text = "N/A"
        self.currentWeatherSummary?.text = "N/A"
    }
    
    func toggleRefreshAnimation(on: Bool) {
        refreshButton.hidden = on
        if on {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    
    func getBackgroundColor(currentWeather: String, currentTemp: Int, tempUnit: Bool) -> [CGColor] {
        
        let colorSelector = BackgroundColorSelector(frame: self.stormyView.frame, currentWeather: currentWeather, currentTemp: currentTemp, tempUnit: tempUnit)
        let colorByWeather = colorSelector.selectColorByWeather()
        let colorByTemp = colorSelector.seletColorByTemerature()
        let toColors = [colorByWeather.CGColor, colorByTemp.CGColor]

        return toColors
    }
    
    func animateBackground(toColors: [CGColor]) {
        self.gradientLayer.removeAllAnimations()
        
        let fromColors = self.gradientLayer.colors
        self.gradientLayer.colors = toColors
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = fromColors
        animation.toValue = toColors
        animation.duration = self.animationDuration
        animation.fillMode = kCAFillModeForwards
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.delegate = self
        self.gradientLayer.addAnimation(animation, forKey: "animateGradient")
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if let animation = anim as? CABasicAnimation {
            if let colors = animation.toValue as? [CGColor] {
                if let tempWeather = temporaryWeather {
                let newColors = self.getBackgroundColor((tempWeather.iconDescription)!, currentTemp: (tempWeather.temperature)!, tempUnit: true)
                if !UIColor(CGColor: colors[0]).isEqual(UIColor(CGColor: newColors[0])) || !UIColor(CGColor: colors[1]).isEqual(UIColor(CGColor: newColors[1])) {
                    self.gradientLayer.colors = newColors
                    let newAnimation: CABasicAnimation = CABasicAnimation(keyPath: "colors")
                    newAnimation.fromValue = colors
                    newAnimation.toValue = newColors
                    newAnimation.duration = self.animationDuration
                    newAnimation.fillMode = kCAFillModeForwards
                    newAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                    newAnimation.delegate = self
                    self.gradientLayer.addAnimation(newAnimation, forKey: "animateGradient")
                    }
                }
                
            }
        }
    }

    func addCityToList(city: CityInfo) -> Bool {
        if cities.contains(city) {
            if let cityIndex = cities.indexOf(city) {
                cities[cityIndex] = city
                saveCitiesData(cities)
                return false
            }
        }
        cities.append(city)
        saveCitiesData(cities)
        return true
    }
    
    func replaceCityAtIndexZeroWith(city: CityInfo) -> Bool {
        if cities.count > 0 {
            cities[0] = city
            saveCitiesData(cities)
            return true
        }
        return false
    }
    
    func citySelected(cityCoordinate: (Double, Double)) {
        addSearchedCityToLeftMenu(cityCoordinate)
    }
    
    func addSearchedCityToLeftMenu(cd:(lat: Double, long: Double)) {
        let forecastService = ForecastService(APIKey: forcastAPIKey)
        
        forecastService.getForecast(cd.lat, long: cd.long) {
            (let currently) in
            
            if let currentWeather = currently {
                initializeCityInfo(cd, weatherInfo: currentWeather) { cityInfo in
                    
                    if cityInfo != nil {
                        
                        self.addCityToList(cityInfo!)
                        self.cityInfo = cityInfo
                        self.isCurrentLocation = false
                        self.coordinate = cd
                        
                        self.updateWeatherInfoUI()
                        

                        }
                    }
                }
            }
        }
    
    func loadTempUnitData() {
        let prefs = NSUserDefaults.standardUserDefaults()
        let unit = prefs.boolForKey("unit")
        self.unit = unit
    }
    
    func loadCitiesData() {
        let prefs = NSUserDefaults.standardUserDefaults()

        if let retrievedCities = prefs.dataForKey("cities") {
            if let loadingCitiesData = NSKeyedUnarchiver.unarchiveObjectWithData(retrievedCities) as? [CityInfo] {
                cities = loadingCitiesData
            }
        }
    }
}

