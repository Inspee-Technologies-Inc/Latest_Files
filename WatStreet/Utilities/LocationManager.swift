//
//  LocationManager.swift
//  WatStreet
//
//  Created by Developer on 12/4/17.
//  Copyright © 2017 Developer. All rights reserved.
//

import UIKit
import MapKit

class LocationManager: NSObject {
    static let shared = LocationManager()
    var manager: CLLocationManager!
}
