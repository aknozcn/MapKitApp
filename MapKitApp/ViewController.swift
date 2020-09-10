//
//  ViewController.swift
//  MapKitApp
//
//  Created by sh3ll on 10.09.2020.
//  Copyright © 2020 sh3ll. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var btnGoTo: UIButton!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    let bolgeBuyukluk: Double = 12000
    var oncekiKonum: CLLocation?
    var _routes: [MKDirections] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        locationServiceControl()

        btnGoTo.layer.cornerRadius = 20
    }

    func locationServiceControl() {
        if CLLocationManager.locationServicesEnabled() {
            setLocationMAnager()
            permissionControl()
        } else {

        }
    }

    func setLocationMAnager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func permissionControl() {

        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            userTrack()
            break
        case .denied:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            break
        default:
            break

        }
    }

    func userTrack() {
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        locationFocus()
        oncekiKonum = getCenterCoordinate(mapView: mapView)
    }

    func locationFocus() {
        if let _location = locationManager.location?.coordinate {
            let _area = MKCoordinateRegion.init(center: _location, latitudinalMeters: bolgeBuyukluk, longitudinalMeters: bolgeBuyukluk)
            mapView.setRegion(_area, animated: true)
        }
    }

    func getCenterCoordinate(mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    @IBAction func btnGoToClicked(_ sender: Any) {
        setRoute()
    }

    func setRoute() {

        guard let beginCoordinate = locationManager.location?.coordinate else { return }

        let _request = createRequest(beginCoordinate: beginCoordinate)
        let _routes = MKDirections(request: _request)
        clearMapView(newRoute: _routes)
        _routes.calculate { (reply, error) in

            guard let reply = reply else { return }
            for _route in reply.routes {
                self.mapView.addOverlay(_route.polyline)
                self.mapView.setVisibleMapRect(_route.polyline.boundingMapRect, animated: true)
            }

        }
    }

    func createRequest(beginCoordinate: CLLocationCoordinate2D) -> MKDirections.Request {

        let targetCoordinate = getCenterCoordinate(mapView: mapView).coordinate
        let beginPoint = MKPlacemark(coordinate: beginCoordinate)
        let targetPoint = MKPlacemark(coordinate: targetCoordinate)
        let _request = MKDirections.Request()

        _request.source = MKMapItem(placemark: beginPoint)
        _request.destination = MKMapItem(placemark: targetPoint)
        _request.transportType = .automobile
        _request.requestsAlternateRoutes = true

        return _request

    }

    func clearMapView(newRoute: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        _routes.append(newRoute)
        let _ = _routes.map { $0.cancel() }

    }
}


extension ViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let _location = locations.last else { return }
        let center = CLLocationCoordinate2D(latitude: _location.coordinate.latitude, longitude: _location.coordinate.longitude)
        let _area = MKCoordinateRegion.init(center: center, latitudinalMeters: bolgeBuyukluk, longitudinalMeters: bolgeBuyukluk)
        mapView.setRegion(_area, animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        permissionControl()
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterCoordinate(mapView: mapView)

        guard let oncekiKonum = self.oncekiKonum else { return }
        if center.distance(from: oncekiKonum) < 50 {
            return
        }

        self.oncekiKonum = center

        let geoCoder = CLGeocoder()
        geoCoder.cancelGeocode()
        geoCoder.reverseGeocodeLocation(center) { (yerIsaretleri, error) in
            if let _ = error {
                print("Hata meydana geldi")
                return
            }
            guard let point = yerIsaretleri?.first else {
                return
            }

            let sokakNo = point.subThoroughfare ?? "Yok"
            let sokakAdi = point.thoroughfare ?? "Yok"
            let ulkeAdi = point.country ?? "Yok"
            let ilAdi = point.administrativeArea ?? "Yok"
            let ilceAdi = point.locality ?? "Yok"


            DispatchQueue.main.async {
                self.lblAddress.text = "\(ilceAdi) / \(ilAdi) / \(ulkeAdi)"
                print("Sokak No: \(sokakNo)")
                print("Sokak Adı \(sokakAdi)")
            }
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .black
        renderer.lineWidth = 8
        renderer.lineCap = .square
        return renderer
    }
}

