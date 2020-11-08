//
//  CLDeviceLocationManager.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 17/09/2020.
//

import Foundation
import CoreLocation

public class DeviceLocationManager: NSObject, LocationManagerProtocol, CLLocationManagerDelegate {
    
    // MARK: - Private Properties
    
    /// Parent locator manager.
    private weak var locator: Locator?
    
    /// Internal device comunication object.
    private var manager: CLLocationManager
    
    /// Stored callbacks for authorizations.
    private var authorizationCallbacks = [AuthorizationCallback]()
    
    /// Delegate of events.
    public weak var delegate: LocationManagerDelegate?
    
    // MARK: - Public Properties

    /// The status of the authorization manager.
    public var authorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return manager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    // MARK: - Initialization
    
    required public init(locator: Locator) throws {
        self.locator = locator
        self.manager = CLLocationManager()
        super.init()

        self.manager.delegate = self
        // We want to activate background capabilities only if we found the key in Info.plist of the hosting app.
        self.manager.allowsBackgroundLocationUpdates = CLLocationManager.hasBackgroundCapabilities()
    }
    
    public var monitoredRegions: Set<CLRegion> {
        manager.monitoredRegions
    }
    
    public func requestAuthorization(_ mode: AuthorizationMode, _ callback: @escaping AuthorizationCallback) {
        guard authorizationStatus.isAuthorized == false else {
            callback(authorizationStatus)
            return
        }
     
        authorizationCallbacks.append(callback)
        manager.requestAuthorization(mode)
    }
    
    public func updateSettings(_ newSettings: LocationManagerSettings) {
        manager.setSettings(newSettings)
    }
    
    public func geofenceRegions(_ requests: [GeofencingRequest]) {
        // If region monitoring is not supported for this device just cancel all monitoring by dispatching `.notSupported`.
        let isMonitoringSupported = CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
        if !isMonitoringSupported {
            delegate?.locationManager(geofenceError: .notSupported, region: nil)
            return
        }
        
        let requestMonitorIds = Set<String>(requests.map({ $0.uuid }))
        let regionToStopMonitoring = manager.monitoredRegions.filter {
            requestMonitorIds.contains($0.identifier) == false
        }
        
        regionToStopMonitoring.forEach { [weak self] in
            LocatorLogger.log("Stop monitoring region: \($0)")
            self?.manager.stopMonitoring(for: $0)
        }
        
        requests.forEach { [weak self] in
            LocatorLogger.log("Start monitoring region: \($0.monitoredRegion)")
            self?.manager.startMonitoring(for: $0.monitoredRegion)
        }
    }
    
    // MARK: - Private Functions
    
    private func didChangeAuthorizationStatus(_ newStatus: CLAuthorizationStatus) {
        guard newStatus != .notDetermined else {
            return
        }
        
        let callbacks = authorizationCallbacks
        callbacks.forEach( { $0(authorizationStatus) })
        authorizationCallbacks.removeAll()
    }
    
    // MARK: - CLLocationManagerDelegate (Location GPS)
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // This method is called only on iOS 13 or lower, for iOS14 we are using `locationManagerDidChangeAuthorization` below.
        
        LocatorLogger.log("Authorization is set to = \(status)")
        didChangeAuthorizationStatus(status)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        LocatorLogger.log("Failed to receive new locations: \(error.localizedDescription)")

        delegate?.locationManager(didFailWithError: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        LocatorLogger.log("Received new locations: \(locations)")
        
        delegate?.locationManager(didReceiveLocations: locations)
    }
    
    // MARK: - CLLocationManagerDelegate (Geofencing)
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        LocatorLogger.log("Did enter in region: \(region.identifier)")

        delegate?.locationManager(geofenceEvent: .didEnteredRegion(region))
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        LocatorLogger.log("Did exit from region: \(region.identifier)")

        delegate?.locationManager(geofenceEvent: .didExitedRegion(region))
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        LocatorLogger.log("Did fail to monitoring region: \(region?.identifier ?? "all"). \(error.localizedDescription)")

        delegate?.locationManager(geofenceError: .generic(error), region: region)
    }
    
    public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        LocatorLogger.log("Did fail to monitoring visit: \(visit.description)")

        delegate?.locationManager(didVisits: visit)
    }
    
}
