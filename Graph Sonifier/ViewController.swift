//
//  ViewController.swift
//  Graph Sonifier V1
//
//  Created by Felicia Alfieri on 6/15/16.
//  Copyright © 2016 Felicia Alfieri. All rights reserved.
//

import UIKit
import AudioKit
import AVFoundation
//import Charts

//initialize oscillator for sound synthesis, classes, and display size
var oscillator = AKSquareWaveOscillator()
var sonifyGraph = SonifyGraph()
var speechSynthesizer = AVSpeechSynthesizer()
let screenSize: CGRect = UIScreen.mainScreen().bounds

class ViewController: UIViewController {
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var currentPrice: UILabel!
    @IBOutlet weak var percentChange: UILabel!
    @IBOutlet weak var domain: UILabel!
    @IBOutlet weak var highPrice: UILabel!
    @IBOutlet weak var lowPrice: UILabel!
    
    //Array of structs of date and price for each data point
    // These can eventually be dynamically taken from an API
    var lineData = [point(time: "May 23rd", price: 50.03), point(time: "May 24th", price: 51.59), point(time: "May 25th", price: 52.12), point(time: "May 26th", price: 51.89), point(time: "May 27th", price: 52.32), point(time: "May 31st", price: 53.00), point(time: "June 1st", price: 52.85), point(time: "June 2nd",  price: 52.48), point(time: "June 3rd",  price: 51.79), point(time: "June 6th", price: 52.13), point(time: "June 7th", price: 52.10), point(time: "June 8th", price: 52.04), point(time: "June 9th", price: 51.62), point(time: "June 10th", price: 51.48), point(time: "June 13th", price: 50.14), point(time: "June 14th", price: 49.83), point(time: "June 15th",  price: 49.69), point(time: "June 16th",  price: 50.39), point(time: "June 17th", price: 50.13), point(time: "June 20th", price: 50.07), point(time: "June 21st", price: 51.19), point(time: "June 22nd", price: 51.21)]
    
    // Dictionary of words / values to be read aloud
    var textStrings: [String: String] = [
        "title" : "Microsoft Stock Price",
        "price_range" :  "",
        "time_span" : "",
        "current_price" : "",
        "start_price" : "",
        "high_price" : "",
        "low_price" : ""
    ]
    
    var percentChangeValue: Double {
        if (lineData.count-1) >= 0 {
            let lastPrice = lineData.last?.price
            let secondToLastPrice = lineData[lineData.count-2].price
            let changeDifference = lastPrice! - secondToLastPrice
            let changePercent = (changeDifference/secondToLastPrice)*100
            return round(100 * changePercent) / 100
        }
        else {
            return 0
        }
    }
    
    var speakText: String = ""
    var xLocation: Double = 0
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view, typically from a nib.
        super.viewDidLoad()
        buildStringsDict()
        oscillator.amplitude = 0.5
        AudioKit.output = oscillator
        AudioKit.start()
        
        self.view.multipleTouchEnabled = true
        self.view.userInteractionEnabled = true
        
        
        
        //Detects pan gesture to allow user to "scrub" through line sound
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ViewController.detectPan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = false;
        self.view.addGestureRecognizer(pan)
        
//        //Detects swipes left and right
//        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.detectSwipe(_:)))
//        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.detectSwipe(_:)))
//        leftSwipe.direction = .Left
//        rightSwipe.direction = .Right
//        self.view.addGestureRecognizer(leftSwipe)
//        self.view.addGestureRecognizer(rightSwipe)
        
        //Detects single and double taps
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.detectSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(singleTap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.detectDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTap)
        
        singleTap.requireGestureRecognizerToFail(doubleTap)
        
        // Detects multi-touch taps
        let threeFingerTap = UITapGestureRecognizer(target: self, action:#selector(ViewController.detectThreeFingerTap(_:)))
        threeFingerTap.numberOfTouchesRequired = 3
        self.view.addGestureRecognizer(threeFingerTap)
        
        // Detects long press
        let longPress = UILongPressGestureRecognizer(target: self, action:#selector(ViewController.detectLongPress(_:)))
        self.view.addGestureRecognizer(longPress)
        
//        // Get API data
//        let stocksAPI = StocksAPI()
//        stocksAPI.openURLSession()
        
        titleLabel.text = "MSFT"
        titleLabel.accessibilityLabel = "Microsoft Stock"
        currentPrice.accessibilityLabel = "$" + String(round(100 * lineData.last!.price) / 100) + ", current price"
        percentChange.accessibilityLabel = String(percentChangeValue) + "% change"
        domain.accessibilityLabel = String(lineData.first!.time) + " to " + String(lineData.last!.time)
        highPrice.accessibilityLabel = String(sonifyGraph.getMax(lineData)) + ", high price"
        lowPrice.accessibilityLabel = String(sonifyGraph.getMin(lineData)) + ", low price"
        
//        self.view.isAccessibilityElement = true
    }

    
    func detectPan(sender: UIPanGestureRecognizer) {
        // Takes x value from pan and converts it to the frequnecy associated with the data's y value
        let location = sender.locationInView(self.view)
        let xValue = Double(location.x)
        let xPos = (xValue / Double(screenSize.width)) // Convert to 0-1 scale
        oscillator.start()
        oscillator.frequency = sonifyGraph.scrubLine(lineData, scrubX: Double(xPos))!
        NSThread.sleepForTimeInterval(0.05)
        oscillator.stop()
        print(xValue);
    
//        if (sender.state == UIGestureRecognizerState.Began || sender.state == UIGestureRecognizerState.Changed) {
//            xLocation = xValue
//            self.performSelector(#selector(ViewController.speakValues), withObject: nil, afterDelay: 1)
//        }
    }

    func speakValues() {
        let location = xLocation
        let xValue = location / Double(screenSize.width)
        let ptSize = Double(1)/lineData.count
        let iVal = (xValue / ptSize)
        let i = Int(round(100 * iVal)/100)
        speakText = "$" + String(lineData[i].price) + " on " + String(lineData[i].time)
        TextToSpeech().speakText(speakText)
    }
    
    
    func detectSwipe(sender: UISwipeGestureRecognizer) {
        if(sender.direction == .Left){
            // Plays data sound from most recent to oldest time
            let reverseData: [point] = lineData.reverse()
            sonifyGraph.playLine(reverseData)
        }
        if(sender.direction == .Right){
            // Plays data from oldest to most recent time
            sonifyGraph.playLine(lineData)
        }
    }
    
    func detectSingleTap(sender: UITapGestureRecognizer) {
        // Read out price at point
        if(sender.state == .Ended) {
            let location = sender.locationInView(self.view)
            let xValue = (Double(location.x)) / Double(screenSize.width)
            let ptSize = Double(1)/lineData.count
            let iVal = (xValue / ptSize)
            let i = Int(round(100 * iVal)/100)
            speakText = "$" + String(lineData[i].price) + " on " + String(lineData[i].time)
            TextToSpeech().speakText(speakText)
        }
    }
    

    
    func detectLongPress(sender: UILongPressGestureRecognizer){
        if(sender.state == .Began) {
            let location = sender.locationInView(self.view)
            let xValue = (Double(location.x)) / Double(screenSize.width)
            let ptSize = Double(1)/lineData.count
            let iVal = (xValue / ptSize)
            let i = Int(round(100 * iVal)/100)
            speakText = "$" + String(lineData[i].price)
            TextToSpeech().speakText(speakText)
        }
    }
    
    //divides screen into a 3x3 grid and determines where tap location occurred in the grid
    func detectDoubleTap(sender: UITapGestureRecognizer) {
        let screenSize = view.frame.size
        //grabs tap location
        let location = sender.locationInView(self.view)
        
        //if tap location is in horizontal middle of the screen
        if(location.y > (screenSize.height)/3 && location.y < (screenSize.height)*(2/3)){
            //if tap location is in the left part of the horizontal middle
            if(location.x < (screenSize.width)/3){
                speakText = "Starting Price: $" + String(lineData[0].price)
                TextToSpeech().speakText(speakText)
                
            }
                //if tap location is the right part of the horizontal middle
            else if(location.x > (screenSize.width)*(2/3)){
                speakText = "Current Price: $" + String(lineData.last!.price)
                TextToSpeech().speakText(speakText)
            }
            
        }
            //if tap location is the vertical middle of the screen
        else if(location.x > (screenSize.width)/3 && location.x < (screenSize.width)*(2/3)){
            //if tap location is top part of the vertical middle
            if(location.y < (screenSize.height)/3){
                speakText = "High Price: $" + String(sonifyGraph.getMax(lineData))
                TextToSpeech().speakText(speakText)
            }
                //if tap location is bottom part of the vertical middle
            else if(location.y > (screenSize.height)*(2/3)){
                speakText = "Low Price: $" + String(sonifyGraph.getMin(lineData))
                TextToSpeech().speakText(speakText)
            }
        }
    }
    
    func detectThreeFingerTap(sender:UITapGestureRecognizer) {
        if(sender.state == .Ended) {
            speakText = "Microsoft Stock " + textStrings["time_span"]! + ". Price range " + textStrings["price_range"]!
            TextToSpeech().speakText(speakText)
        }
    }
    
    
    func buildStringsDict() {
        //Gets strings of data for speech dictionary
        textStrings["price_range"] = "$" + String(floor(sonifyGraph.getMin(lineData))) + " to $" + String(ceil(sonifyGraph.getMax(lineData)))
        textStrings["time_span"] = String(lineData.first!.time) + " through " + String(lineData.last!.time)
        textStrings["current_price"] = "$" + String(lineData.last!.price)
        textStrings["start_price"] = "$" + String(lineData[0].price)
        textStrings["high_price"] = "$" + String(sonifyGraph.getMax(lineData))
        textStrings["low_price"] = "$" + String(sonifyGraph.getMin(lineData))
    }
    
    
    @IBAction func changeFrequency(sender: UISlider) {
//        oscillator.frequency = 100 + (Double (sender.value * 880.0))
//        print (Double (sender.value))
        oscillator.start()
        let frequency = sonifyGraph.scrubLine(lineData, scrubX: Double(sender.value))!
        print(frequency)
        oscillator.frequency = frequency
        NSThread.sleepForTimeInterval(0.05)
        oscillator.stop()
    }
    
    
    @IBAction func playButton(sender: UIButton) {
        sonifyGraph.playLine(lineData)
    }
    
    
    @IBAction func speechButton(sender: UIButton) {
        speakText = "Line graph of " + textStrings["title"]! + " for " + textStrings["time_span"]! + ". Price range " + textStrings["price_range"]!
        //speakText = textStrings["title"]!
        //speakText = textStrings["price_range"]!
        //speakText = textStrings["time_span"]!
        //speakText = textStrings["current_price"]!
        //speakText = textStrings["start_price"]!
        //speakText = textStrings["high_price"]!
        //speakText = textStrings["low_price"]!
        //speakText = "Testing"
        TextToSpeech().speakText(speakText)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}



struct point {
    // Struct to create time and price data points
    var time: String
    var price: Double
    
    init(time: String, price: Double) {
        self.time = time
        self.price = price
    }
}


class SonifyGraph: NSObject {
    
    // Frequency range we chose as best for hearing
    var freqMin = 261.63
    var freqMax = 1046.5
    var playRate: useconds_t = 300000
    
    func SonifyGraph() {
    }
    
    func getFreq(lineData: [point], y: Double) -> Double {
        // Maps line y position to frequency range we set
        let dataMin = getMin(lineData)
        let graphMin = floor(dataMin)
        let graphMax = ceil(getMax(lineData))
        let graphRange = graphMax - graphMin
        let toneRange = freqMax - freqMin
        let proportion = (y - dataMin) / graphRange
        return (proportion * toneRange) + freqMin
    }
    
    func playLine(lineData: [point]) {
        // Plays the entire line sound trend at playRate we set
        oscillator.start()
        for p in lineData {
            let pointFreq = getFreq(lineData, y: p.price)
            playTone(pointFreq)
            usleep(playRate)
        }
        oscillator.stop()
    }
    
    
    func scrubLine(lineData: [point], scrubX: Double) -> Double? {
        // Plays tone for y value of line based on finger position (x)
        if (scrubX > 0 && scrubX < 1) {
            let ptSize = Double(1)/lineData.count
            let iVal = (scrubX / ptSize)
            let i = Int(round(100 * iVal)/100)
            let x1 = i * ptSize; let x2 = x1 + ptSize
            if (i < (lineData.count-1)) {
                // Uses y=mx+b to find slope and then y value, which is mapped to appropriate frequency
                let y1 = lineData[i].price; let y2 = lineData[i+1].price
                let m = (y2 - y1) / (x2 - x1)
                let scrubY = (m * (scrubX - x1)) + y1
                let pointFreq = getFreq(lineData, y: scrubY)
                return pointFreq
            }
        }
        return 0.0
    }
    
    func getMin(lineData: [point]) -> Double {
        // Finds the minimum point in linData struct
        var minPoint = lineData[0].price
        for i in 1...(lineData.count-1) {
            if (lineData[i].price < minPoint) {
                minPoint = lineData[i].price
            }
        }
        return minPoint
    }
    
    func getMax(lineData: [point]) -> Double {
        // Finds the maximum point in linData struct
        var maxPoint = lineData[0].price
        for i in 1...(lineData.count-1) {
            if (lineData[i].price > maxPoint) {
                maxPoint = lineData[i].price
            }
        }
        return maxPoint
    }
    
    func playTone(pointFreq: Double) {
        // Changes oscillator output based on frequency
        oscillator.frequency = pointFreq
    }
    
    
}


class TextToSpeech: NSObject {
    
    // Speaks aloud a given string
    
    var speechSynthesizer = AVSpeechSynthesizer()
    var speechRate: Float = 0.5
    
    func TextToSpeech() {
    }
    
    func speakText(nextSpeech: String) {
        // Reads nextSpeech value out loud
        let nextSpeech:AVSpeechUtterance = AVSpeechUtterance(string:nextSpeech)
        nextSpeech.rate = speechRate
        speechSynthesizer.speakUtterance(nextSpeech)
        print ("Speaking")
    }
    
}


