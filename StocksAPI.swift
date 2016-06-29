//
//  ForecastAPI.swift
//  Forecaster
//
//  Created by Jacob Jorgensen on 10/26/15.
//  Copyright © 2015 Jacob Jorgensen. All rights reserved.
//

import Foundation

class StocksAPI {
    
    
    
    let kibotAPIURL = "http://api.kibot.com/?action=history&symbol=MSFT&interval=Daily&period=365"
    let kibotLogInURL = "http://api.kibot.com/?action=login&user=guest&password=guest"
    var dictionary: Dictionary<String, AnyObject>!
    
    var symbol = "MSFT"
    var period = 365
    var interval = "Daily"
    
    func createURL(urlString: String) -> NSURL {
//        let forecastURLString = "\(kibotAPIURL)\(forecastAPIKey)/\(self.latitude),\(self.longitude)"
        return NSURL(string: kibotAPIURL)!
    }
    
    func openURLSession() {
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(createURL(kibotLogInURL), completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            print("Log In Successful!")
            self.getData()
        })
        task.resume()
        
    }
    
    @objc func getData() {
        print("Method called!")
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(createURL(kibotAPIURL), completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) in

            let stringVersion = String(data: data!, encoding: NSUTF8StringEncoding)

            var pricesArray = [String]()
            if let unwrapped = stringVersion {
                let daysTempArray = unwrapped.componentsSeparatedByString("\r\n")
                var daysArray = [String]()
                
                let endIndex = daysTempArray.count-2
                for i in 0 ..< endIndex {
                    daysArray.append(daysTempArray[i])
                }
                
                for string in daysArray {
                    var pricesTempArray = string.componentsSeparatedByString(",")
                    pricesArray.append(pricesTempArray[1])
                }
            }
            print(pricesArray)
            
        })
        task.resume()
    }
    
}
