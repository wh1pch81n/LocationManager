//
//  LocationManager.swift
//
//
//  Created by Jimmy Jose on 14/08/14.
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import UIKit
import CoreLocation
import MapKit


public typealias LMReverseGeocodeCompletionHandler = ((reverseGecodeInfo:NSDictionary?,placemark:CLPlacemark?, error:String?)->Void)?
public typealias LMGeocodeCompletionHandler = ((gecodeInfo:NSDictionary?,placemark:CLPlacemark?, error:String?)->Void)?
public typealias LMLocationCompletionHandler = ((latitude:Double, longitude:Double, status:String, verboseMessage:String, error:String?)->())?

// Todo: Keep completion handler differerent for all services, otherwise only one will work
public enum GeoCodingType{
    
    case Geocoding
    case ReverseGeocoding
}

public class LocationManager: NSObject, CLLocationManagerDelegate {
    
    /* Private variables */
    private var completionHandler: LMLocationCompletionHandler
    
    private var reverseGeocodingCompletionHandler: LMReverseGeocodeCompletionHandler
    private var geocodingCompletionHandler: LMGeocodeCompletionHandler
    
    private var locationStatus: String = "Calibrating"// to pass in handler
    private var locationManager: CLLocationManager!
    private var verboseMessage = "Calibrating"
    
    private let verboseMessageDictionary = [CLAuthorizationStatus.NotDetermined:"You have not yet made a choice with regards to this application.",
        CLAuthorizationStatus.Restricted:"This application is not authorized to use location services. Due to active restrictions on location services, the user cannot change this status, and may not have personally denied authorization.",
        CLAuthorizationStatus.Denied:"You have explicitly denied authorization for this application, or location services are disabled in Settings.",
        CLAuthorizationStatus.AuthorizedAlways:"App is Authorized to use location services.",
        CLAuthorizationStatus.AuthorizedWhenInUse:"You have granted authorization to use your location only when the app is visible to you."]
    
    public var latitude: Double = 0.0
    public var longitude: Double = 0.0
    
    public var latitudeAsString: String = ""
    public var longitudeAsString: String = ""
    
    
    public var lastKnownLatitude: Double = 0.0
    public var lastKnownLongitude: Double = 0.0
    
    public var lastKnownLatitudeAsString: String = ""
    public var lastKnownLongitudeAsString: String = ""
    
    public var keepLastKnownLocation: Bool = true
    public var hasLastKnownLocation: Bool = true
    
    public var autoUpdate: Bool = false
    
    public var showVerboseMessage = false
    
    public var isRunning = false
    
    public var locationFound: ((latitude: Double, longitude: Double) -> ())! // You are required to set this
    public var locationFoundGetAsString: ((latitude: String, longitude: String) -> ())?
    public var locationManagerStatus: ((status: String) -> ())?
    public var locationManagerReceivedError: ((error: String) -> ())?
    public var locationManagerVerboseMessage: ((message:NSString) -> ())?
    
    public static let sharedInstance = LocationManager()

    private override init() {
        super.init()
        
        if autoUpdate == false {
            autoUpdate = !CLLocationManager.significantLocationChangeMonitoringAvailable()
        }
    }
    
    private func resetLatLon() {
        latitude = 0.0
        longitude = 0.0
        
        latitudeAsString = ""
        longitudeAsString = ""
    }
    
    private func resetLastKnownLatLon() {
        hasLastKnownLocation = false
        
        lastKnownLatitude = 0.0
        lastKnownLongitude = 0.0
        
        lastKnownLatitudeAsString = ""
        lastKnownLongitudeAsString = ""
    }
    
    public func startUpdatingLocationWithCompletionHandler(completionHandler:((latitude:Double, longitude:Double, status:String, verboseMessage:String, error:String?)->())? = nil) {
        
        self.completionHandler = completionHandler
        initLocationManager()
    }
    
    public func startUpdatingLocation() {
        initLocationManager()
    }
    
    public func stopUpdatingLocation() {
        if autoUpdate {
            locationManager.stopUpdatingLocation()
        } else {
            locationManager.stopMonitoringSignificantLocationChanges()
        }
        
        resetLatLon()
        if keepLastKnownLocation == false {
            resetLastKnownLatLon()
        }
    }
    
    private func initLocationManager() {
        // App might be unreliable if someone changes autoupdate status in between and stops it
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        // locationManager.locationServicesEnabled
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestWhenInUseAuthorization() // add in plist NSLocationWhenInUseUsageDescription
        
        startLocationManger()
    }
    
    private func startLocationManger() {
        if autoUpdate {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.startMonitoringSignificantLocationChanges()
        }
        
        isRunning = true
    }
    
    private func stopLocationManger() {
        if autoUpdate {
            locationManager.stopUpdatingLocation()
        } else {
            locationManager.stopMonitoringSignificantLocationChanges()
        }
        
        isRunning = false
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        stopLocationManger()
        resetLatLon()
        
        if keepLastKnownLocation == false {
            resetLastKnownLatLon()
        }
        
        var verbose = ""
        if showVerboseMessage {
            verbose = verboseMessage
        }
        completionHandler?(latitude: 0.0, longitude: 0.0, status: locationStatus as String, verboseMessage:verbose,error: error.localizedDescription)
        
        locationManagerReceivedError?(error: error.localizedDescription)
    }
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let arrayOfLocation = locations as NSArray
        let location = arrayOfLocation.lastObject as! CLLocation
        let coordLatLon = location.coordinate
        
        latitude  = coordLatLon.latitude
        longitude = coordLatLon.longitude
        
        latitudeAsString  = coordLatLon.latitude.description
        longitudeAsString = coordLatLon.longitude.description
        
        var verbose = ""
        
        if showVerboseMessage {
            verbose = verboseMessage
        }
        
        completionHandler?(latitude: latitude, longitude: longitude, status: locationStatus as String,verboseMessage:verbose, error: nil)
        
        
        lastKnownLatitude = coordLatLon.latitude
        lastKnownLongitude = coordLatLon.longitude
        
        lastKnownLatitudeAsString = coordLatLon.latitude.description
        lastKnownLongitudeAsString = coordLatLon.longitude.description
        
        hasLastKnownLocation = true
        
        locationFoundGetAsString?(latitude: latitudeAsString,longitude:longitudeAsString)
        locationFound(latitude: latitude,longitude: longitude)
    }
    
    public func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
            var hasAuthorised = false
            let verboseKey = status
            switch status {
            case CLAuthorizationStatus.Restricted:
                locationStatus = "Restricted Access"
            case CLAuthorizationStatus.Denied:
                locationStatus = "Denied access"
            case CLAuthorizationStatus.NotDetermined:
                locationStatus = "Not determined"
            default:
                locationStatus = "Allowed access"
                hasAuthorised = true
            }
            
            verboseMessage = verboseMessageDictionary[verboseKey]!
            
            if hasAuthorised == true {
                startLocationManger()
            } else {
                resetLatLon()
                if locationStatus != "Denied access" {
                    var verbose = ""
                    if showVerboseMessage {
                        verbose = verboseMessage
                        locationManagerVerboseMessage?(message: verbose)
                    }
                    
                    if(completionHandler != nil){
                        completionHandler?(latitude: latitude, longitude: longitude, status: locationStatus as String, verboseMessage:verbose,error: nil)
                    }
                }
                
                locationManagerStatus?(status: locationStatus)
                
            }
            
    }
    
    
    public func reverseGeocodeLocationWithLatLon(latitude latitude:Double, longitude: Double,onReverseGeocodingCompletionHandler:LMReverseGeocodeCompletionHandler){
        
        let location:CLLocation = CLLocation(latitude:latitude, longitude: longitude)
        
        reverseGeocodeLocationWithCoordinates(location,onReverseGeocodingCompletionHandler: onReverseGeocodingCompletionHandler)
        
    }
    
    public func reverseGeocodeLocationWithCoordinates(coord:CLLocation, onReverseGeocodingCompletionHandler:LMReverseGeocodeCompletionHandler){
        
        self.reverseGeocodingCompletionHandler = onReverseGeocodingCompletionHandler
        
        reverseGocode(coord)
    }
    
    private func reverseGocode(location:CLLocation){
        
        let geocoder: CLGeocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                self.reverseGeocodingCompletionHandler!(reverseGecodeInfo:nil,placemark:nil, error: error!.localizedDescription)
                
            }
            else{
                
                if let placemark = placemarks?.first {
                    var address = AddressParser()
                    address.parseAppleLocationData(placemark)
                    let addressDict = address.getAddressDictionary()
                    self.reverseGeocodingCompletionHandler!(reverseGecodeInfo: addressDict,placemark:placemark,error: nil)
                }
                else {
                    self.reverseGeocodingCompletionHandler!(reverseGecodeInfo: nil,placemark:nil,error: "No Placemarks Found!")
                    return
                }
            }
            
        })
        
        
    }
    
    
    
    public func geocodeAddressString(address address:NSString, onGeocodingCompletionHandler:LMGeocodeCompletionHandler){
        
        self.geocodingCompletionHandler = onGeocodingCompletionHandler
        
        geoCodeAddress(address)
        
    }
    
    
    private func geoCodeAddress(address:NSString){
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address as String, completionHandler: {(placemarks: [CLPlacemark]?, error: NSError?) -> Void in
            
            if (error != nil) {
                
                self.geocodingCompletionHandler!(gecodeInfo:nil,placemark:nil,error: error!.localizedDescription)
                
            }
            else{
                
                if let placemark = placemarks?.first {
                    
                    var address = AddressParser()
                    address.parseAppleLocationData(placemark)
                    let addressDict = address.getAddressDictionary()
                    self.geocodingCompletionHandler!(gecodeInfo: addressDict,placemark:placemark,error: nil)
                }
                else {
                    
                    self.geocodingCompletionHandler!(gecodeInfo: nil,placemark:nil,error: "invalid address: \(address)")
                    
                }
            }
            
        })
        
        
    }
    
    
    public func geocodeUsingGoogleAddressString(address address:NSString, onGeocodingCompletionHandler:LMGeocodeCompletionHandler){
        
        self.geocodingCompletionHandler = onGeocodingCompletionHandler
        
        geoCodeUsignGoogleAddress(address)
    }
    
    
    private func geoCodeUsignGoogleAddress(address:NSString){
        
        var urlString = "http://maps.googleapis.com/maps/api/geocode/json?address=\(address)&sensor=true" as NSString
        
        urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        performOperationForURL(urlString, type: GeoCodingType.Geocoding)
        
    }
    
    public func reverseGeocodeLocationUsingGoogleWithLatLon(latitude latitude:Double, longitude: Double,onReverseGeocodingCompletionHandler:LMReverseGeocodeCompletionHandler){
        
        self.reverseGeocodingCompletionHandler = onReverseGeocodingCompletionHandler
        
        reverseGocodeUsingGoogle(latitude: latitude, longitude: longitude)
        
    }
    
    public func reverseGeocodeLocationUsingGoogleWithCoordinates(coord:CLLocation, onReverseGeocodingCompletionHandler:LMReverseGeocodeCompletionHandler){
        
        reverseGeocodeLocationUsingGoogleWithLatLon(latitude: coord.coordinate.latitude, longitude: coord.coordinate.longitude, onReverseGeocodingCompletionHandler: onReverseGeocodingCompletionHandler)
        
    }
    
    private func reverseGocodeUsingGoogle(latitude latitude:Double, longitude: Double){
        
        var urlString = "http://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&sensor=true" as NSString
        
        urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        performOperationForURL(urlString, type: GeoCodingType.ReverseGeocoding)
        
    }
    
    private func performOperationForURL(urlString:NSString,type:GeoCodingType){
        
        let url:NSURL? = NSURL(string:urlString as String)
        
        let request:NSURLRequest = NSURLRequest(URL:url!)
        
        let queue:NSOperationQueue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request,queue:queue,completionHandler:{response,data,error in
            
            if(error != nil){
                
                self.setCompletionHandler(responseInfo:nil, placemark:nil, error:error!.localizedDescription, type:type)
                
            }else{
                
                let kStatus = "status"
                let kOK = "ok"
                let kZeroResults = "ZERO_RESULTS"
                let kAPILimit = "OVER_QUERY_LIMIT"
                let kRequestDenied = "REQUEST_DENIED"
                let kInvalidRequest = "INVALID_REQUEST"
                let kInvalidInput =  "Invalid Input"
                
                //let dataAsString: NSString? = NSString(data: data!, encoding: NSUTF8StringEncoding)
                
                
                let jsonResult: NSDictionary = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)) as! NSDictionary
                
                var status = jsonResult.valueForKey(kStatus) as! NSString
                status = status.lowercaseString
                
                if(status.isEqualToString(kOK)){
                    
                    var address = AddressParser()
                    
                    address.parseGoogleLocationData(jsonResult)
                    
                    let addressDict = address.getAddressDictionary()
                    let placemark:CLPlacemark = address.getPlacemark()
                    
                    self.setCompletionHandler(responseInfo:addressDict, placemark:placemark, error: nil, type:type)
                    
                }else if(!status.isEqualToString(kZeroResults) && !status.isEqualToString(kAPILimit) && !status.isEqualToString(kRequestDenied) && !status.isEqualToString(kInvalidRequest)){
                    
                    self.setCompletionHandler(responseInfo:nil, placemark:nil, error:kInvalidInput, type:type)
                    
                }
                    
                else{
                    
                    //status = (status.componentsSeparatedByString("_") as NSArray).componentsJoinedByString(" ").capitalizedString
                    self.setCompletionHandler(responseInfo:nil, placemark:nil, error:status as String, type:type)
                    
                }
                
            }
            
            }
        )
        
    }
    
    private func setCompletionHandler(responseInfo responseInfo:NSDictionary?,placemark:CLPlacemark?, error:String?,type:GeoCodingType){
        
        if(type == GeoCodingType.Geocoding){
            
            self.geocodingCompletionHandler!(gecodeInfo:responseInfo,placemark:placemark,error:error)
            
        }else{
            
            self.reverseGeocodingCompletionHandler!(reverseGecodeInfo:responseInfo,placemark:placemark,error:error)
        }
    }
}

private struct AddressParser: DictionaryLiteralConvertible {
    
    private var latitude = ""
    private var longitude  = ""
    private var streetNumber = ""
    private var route = ""
    private var locality = ""
    private var subLocality = ""
    private var formattedAddress = ""
    private var administrativeArea = ""
    private var administrativeAreaCode = ""
    private var subAdministrativeArea = ""
    private var postalCode = ""
    private var country = ""
    private var subThoroughfare = ""
    private var thoroughfare = ""
    private var ISOcountryCode = ""
    private var state = ""
    
    typealias KeyType = String
    typealias ValueType = String
    
    init(dictionaryLiteral elements: (KeyType, ValueType)...) {
        for (key, value) in elements {
            switch key {
            case "latitude": latitude = value
            case "longitude": longitude = value
            case "streetNumber": streetNumber = value
            case "route": route = value
            case "locality": locality = value
            case "subLocality": subLocality = value
            case "formattedAddress": formattedAddress = value
            case "administrativeArea": administrativeArea = value
            case "administrativeAreaCode": administrativeAreaCode = value
            case "subAdministrativeArea": subAdministrativeArea = value
            case "postalCode": postalCode = value
            case "country": country = value
            case "subThoroughfare": subThoroughfare = value
            case "thoroughfare": thoroughfare = value
            case "ISOcountryCode": ISOcountryCode = value
            case "state": state = value
            default: ()
            }
        }
    }
    
    private func getAddressDictionary() -> Dictionary<String, String> {
        
        let addressDict = NSMutableDictionary()
        
        addressDict.setValue(latitude, forKey: "latitude")
        addressDict.setValue(longitude, forKey: "longitude")
        addressDict.setValue(streetNumber, forKey: "streetNumber")
        addressDict.setValue(locality, forKey: "locality")
        addressDict.setValue(subLocality, forKey: "subLocality")
        addressDict.setValue(administrativeArea, forKey: "administrativeArea")
        addressDict.setValue(postalCode, forKey: "postalCode")
        addressDict.setValue(country, forKey: "country")
        addressDict.setValue(formattedAddress, forKey: "formattedAddress")
        
        return [
            "latitude": latitude,
            "longitude": longitude,
            "streetNumber": streetNumber,
            "locality": locality,
            "subLocality": subLocality,
            "administrativeArea": administrativeArea,
            "postalCode": postalCode,
            "country": country,
            "formattedAddress": formattedAddress,
        ]
    }
    
    private mutating func parseAppleLocationData(placemark: CLPlacemark) {
        
        let addressLines = placemark.addressDictionary!["FormattedAddressLines"] as! NSArray
        
        //self.streetNumber = placemark.subThoroughfare ? placemark.subThoroughfare : ""
        self.streetNumber = (placemark.thoroughfare != nil ? placemark.thoroughfare : "")!
        self.locality = (placemark.locality != nil ? placemark.locality : "")!
        self.postalCode = (placemark.postalCode != nil ? placemark.postalCode : "")!
        self.subLocality = (placemark.subLocality != nil ? placemark.subLocality : "")!
        self.administrativeArea = (placemark.administrativeArea != nil ? placemark.administrativeArea : "")!
        self.country = (placemark.country != nil ?  placemark.country : "")!
        self.longitude = placemark.location!.coordinate.longitude.description;
        self.latitude = placemark.location!.coordinate.latitude.description
        if(addressLines.count>0){
            self.formattedAddress = addressLines.componentsJoinedByString(", ")}
        else{
            self.formattedAddress = ""
        }
    }
    
    
    private mutating func parseGoogleLocationData(resultDict: NSDictionary) {
        
        let locationDict = (resultDict.valueForKey("results") as! NSArray).firstObject as! NSDictionary
        let formattedAddrs = locationDict.objectForKey("formatted_address") as! String
        
        let geometry = locationDict.objectForKey("geometry") as! NSDictionary
        let location = geometry.objectForKey("location") as! NSDictionary
        let lat = location.objectForKey("lat") as! Double
        let lng = location.objectForKey("lng") as! Double
        
        self.latitude = lat.description
        self.longitude = lng.description
        
        let addressComponents = locationDict.objectForKey("address_components") as! NSArray
        
        self.subThoroughfare = component("street_number", inArray: addressComponents, ofType: "long_name")
        self.thoroughfare = component("route", inArray: addressComponents, ofType: "long_name")
        self.streetNumber = self.subThoroughfare
        self.locality = component("locality", inArray: addressComponents, ofType: "long_name")
        self.postalCode = component("postal_code", inArray: addressComponents, ofType: "long_name")
        self.route = component("route", inArray: addressComponents, ofType: "long_name")
        self.subLocality = component("subLocality", inArray: addressComponents, ofType: "long_name")
        self.administrativeArea = component("administrative_area_level_1", inArray: addressComponents, ofType: "long_name")
        self.administrativeAreaCode = component("administrative_area_level_1", inArray: addressComponents, ofType: "short_name")
        self.subAdministrativeArea = component("administrative_area_level_2", inArray: addressComponents, ofType: "long_name")
        self.country =  component("country", inArray: addressComponents, ofType: "long_name")
        self.ISOcountryCode =  component("country", inArray: addressComponents, ofType: "short_name")
        self.formattedAddress = formattedAddrs;
        
    }
    
    private func component(component: String, inArray: NSArray, ofType: String) -> String {
        let index:NSInteger = inArray.indexOfObjectPassingTest { (obj, idx, stop) -> Bool in
            
            let objDict:NSDictionary = obj as! NSDictionary
            let types:NSArray = objDict.objectForKey("types") as! NSArray
            let type = types.firstObject as! String
            return type == component
            
        }
        
        if (index == NSNotFound){
            
            return ""
        }
        
        if (index >= inArray.count){
            return ""
        }
        
        let type = ((inArray.objectAtIndex(index) as! NSDictionary).valueForKey(ofType as String)!) as! String
        
        if (type.characters.count > 0){
            return type
        }
        return ""
    }
    
    private func getPlacemark() -> CLPlacemark {
        
        var addressDict = [String : AnyObject]()
        
        let formattedAddressArray = self.formattedAddress.componentsSeparatedByString(", ") as Array
        
        let kSubAdministrativeArea = "SubAdministrativeArea"
        let kSubLocality           = "SubLocality"
        let kState                 = "State"
        let kStreet                = "Street"
        let kThoroughfare          = "Thoroughfare"
        let kFormattedAddressLines = "FormattedAddressLines"
        let kSubThoroughfare       = "SubThoroughfare"
        let kPostCodeExtension     = "PostCodeExtension"
        let kCity                  = "City"
        let kZIP                   = "ZIP"
        let kCountry               = "Country"
        let kCountryCode           = "CountryCode"
        
        addressDict[kSubAdministrativeArea] = self.subAdministrativeArea
        addressDict[kSubLocality] = self.subLocality as NSString
        addressDict[kState] = self.administrativeAreaCode
        
        addressDict[kStreet] = formattedAddressArray.first! as NSString
        addressDict[kThoroughfare] = self.thoroughfare
        addressDict[kFormattedAddressLines] = formattedAddressArray
        addressDict[kSubThoroughfare] = self.subThoroughfare
        addressDict[kPostCodeExtension] = ""
        addressDict[kCity] = self.locality
        
        addressDict[kZIP] = self.postalCode
        addressDict[kCountry] = self.country
        addressDict[kCountryCode] = self.ISOcountryCode
        
        let lat = Double(self.latitude)!
        let lng = Double(self.longitude)!
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict as [String : AnyObject]?)
        
        return (placemark as CLPlacemark)
    }
}

