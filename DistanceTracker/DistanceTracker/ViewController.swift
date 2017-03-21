//
//  ViewController.swift
//  DistanceTracker
//
//  Created by mac on 21/03/17.
//  Copyright © 2017 mac. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import CoreMotion
import HealthKit
import HealthKitUI


class ViewController: UIViewController,CLLocationManagerDelegate {

    
    var locationManager = CLLocationManager()
    
    let pedoMeter = CMPedometer()
    
    var fromDate = Date()
    
    let latDelta : CLLocationDegrees = 0.005
    
    let longDelta : CLLocationDegrees = 0.005
    
    var span = MKCoordinateSpan()
    
    var isStarted = Bool()
    
    var isPaused = Bool()
    
    var totalNoOfSteps = NSNumber()
    
    var totalDistance = NSNumber()
    
    
    
    @IBOutlet weak var addressOutlet: UILabel!
    
    @IBOutlet weak var distanceOutlet: UILabel!
    
    @IBOutlet weak var stepsOutlet: UILabel!
    
    @IBOutlet weak var mapOutlet: MKMapView!
    
    @IBOutlet weak var startOutlet: UIButton!
    
    @IBOutlet weak var pauseOutlet: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        DispatchQueue.main.async
        {
            //starts updating current user location
            self.locationManager.startUpdatingLocation()
        }
        
        span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        
        isStarted = true
        
        isPaused = false
        
        pauseOutlet.isHidden = true
        
        getHealthKitPermission()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func getHealthKitPermission() {
        
        // Seek authorization in HealthKitManager.swift.
        self.authorizeHealthKit { (authorized,  error) -> Void in
            if authorized {
                print("Got the permissions")
            } else {
                if error != nil {
                    print(error!)
                }
                print("Permission denied")
            }
        }
    }
    
    
    
    let healthKitStore: HKHealthStore = HKHealthStore()
    
    func authorizeHealthKit(completion: ((_ success: Bool, _ error: NSError?) -> Void)!) {
        
        // Health data type(s) we want to write from HealthKit.
        let healthDataToWrite = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!)
        
        // Handle the case if this app is accessed on iPad
        if !HKHealthStore.isHealthDataAvailable() {
            print("Can't access HealthKit.")
        }
        
        // Request authorization to read and/or write the specific data.
        healthKitStore.requestAuthorization(toShare: healthDataToWrite, read: nil) { (success, error) -> Void in
            
        }
    }

    
    //CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        print(locations)
        
        let userLocation : CLLocation = locations[0]
    
    
        let latitude = userLocation.coordinate.latitude
        
        let longitude = userLocation.coordinate.longitude
        
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapOutlet.setRegion(region, animated: true)
        
        mapOutlet.removeAnnotations(mapOutlet.annotations)
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = location
        
        annotation.title = "Your Location"
        
        mapOutlet.addAnnotation(annotation)
        
        CLGeocoder().reverseGeocodeLocation(userLocation)
        {
            (placemarks, error) in
            
            if error != nil
            {
                print(error!)
            }
            else
            {
                
            }
        }
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print(error)
    }
    
    //Button actions

    
    // Action to record start or stop the updations of pedometer
    @IBAction func startAction(_ sender: Any) {
        
        
        if isStarted{
            
            // If user starts the recording
            
            fromDate = Date()
            
            startOutlet.setTitle("Stop", for: UIControlState.normal)
            
            isStarted = false
            
            pauseOutlet.isHidden = false
            
            stepsOutlet.text = "0"
            
            distanceOutlet.text = "0"
            
            
        }else{
            
            // If user stops the recording
            
            startOutlet.setTitle("Start", for: UIControlState.normal)
            
            pauseOutlet.isHidden = true
            
            isPaused = false
            
            // Stop updating the pedometer data
            pedoMeter.stopUpdates()
            
            // Query to get the pedometer data
            pedoMeter.queryPedometerData(from: fromDate, to: Date()) { (pedometerData, error) in
                
                print("pedometerData")
                print(pedometerData!)
                
                
                DispatchQueue.main.async {
                    
                    if let ns = pedometerData?.numberOfSteps{
                        
                        // Update the no of steps
                        print(ns)
                        self.totalNoOfSteps = NSNumber(value: self.totalNoOfSteps.floatValue+ns.floatValue)
                        self.stepsOutlet.text = "\(self.totalNoOfSteps)"
                        
                    }
                    
                    if let ds = pedometerData?.distance{
                        
                        // Update the distance value
                        print(ds)
                        self.totalDistance = NSNumber(value: self.totalDistance.intValue+ds.intValue)
                        self.distanceOutlet.text = "\(self.totalDistance)"
                        
                    }
                    
                    self.totalNoOfSteps = NSNumber(value: 0)
                    
                    self.totalDistance = NSNumber(value: 0)
                    
                }
                
            }
            
            isStarted = true
            
        }
        
    }
    
    
    // Action to pause or resume update of the pedometer
    @IBAction func pauseAction(_ sender: Any) {
        
        if isPaused{
            
            // If user resumes the recording
            
            pauseOutlet.setTitle("Pause", for: UIControlState.normal)
            
            fromDate = Date()
            
            isPaused = false
            
        }else{
            
            // If user pauses the recording
            
            pedoMeter.stopUpdates()
            
            // Query to get the pedometer data
            pedoMeter.queryPedometerData(from: fromDate, to: Date()) { (pedometerData, error) in
                
                print("pedometerData")
                print(pedometerData!)
                
                
                DispatchQueue.main.async {
                    
                    if let ns = pedometerData?.numberOfSteps{
                        
                        // Update the no of steps
                        print(ns)
                        self.totalNoOfSteps = NSNumber(value: self.totalNoOfSteps.floatValue+ns.floatValue)
                        self.stepsOutlet.text = "\(self.totalNoOfSteps)"
                        
                    }
                    
                    if let ds = pedometerData?.distance{
                        
                        // Update the distance value
                        print(ds)
                        self.totalDistance = NSNumber(value: self.totalDistance.intValue+ds.intValue)
                        self.distanceOutlet.text = "\(self.totalDistance)"
                        
                    }
                    
                }
                
            }

            
            pauseOutlet.setTitle("Resume", for: UIControlState.normal)
            
            isPaused  = true
            
        }
        
    }
    
    //Action to share data onto HealthKit
    @IBAction func shareAction(_ sender: Any) {
        
        self.saveDistance(distanceRecorded: totalDistance.doubleValue, date: NSDate())
        
    }
    
    
    // Method to save distance data
    func saveDistance(distanceRecorded: Double, date: NSDate ) {
        
        // Set the quantity type to the running/walking distance.
        let distanceType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
        
        // Set the unit of measurement to miles.
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distanceRecorded)
        
        // Set the official Quantity Sample.
        let distance = HKQuantitySample(type: distanceType!, quantity: distanceQuantity, start: date as Date, end: date as Date)
        
        // Save the distance quantity sample to the HealthKit Store.
        healthKitStore.save(distance, withCompletion: { (success, error) -> Void in
            if( error != nil ) {
                print(error!)
            } else {
                print("The distance has been recorded!")
            }
        })
    }
    
    
}




