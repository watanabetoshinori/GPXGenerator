/*
    PlaygroundApp - GPX Generator
 */

import UIKit
import MapKit
import PlaygroundSupport

// MARK: - App Configuration

let from = "東京駅"

let to = "東京スカイツリー"

let speed: Double = 40.0 /* 40km/h */


// MARK: - Playground App Template

class LiveViewController: UIViewController {

    let kContentSize = CGSize(width: 320, height: 568)

    var console = Console()

    // MARK: - Loading

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .black
        self.view = view
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let contentView = UIView()
        contentView.frame = CGRect(origin: .zero, size: kContentSize)
        contentView.backgroundColor = .black
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true
        view.addSubview(contentView)

        loadContent(contentView)

        if isEnableConsole() {
            let outputView = UIView()
            outputView.backgroundColor = .darkGray
            outputView.frame = CGRect(x: kContentSize.width + 1, y: 0, width: kContentSize.width - 1, height: kContentSize.height)
            view.addSubview(outputView)

            console.textColor = .white
            console.font = UIFont.systemFont(ofSize: 15)
            console.backgroundColor = .darkGray
            console.frame = CGRect(x: 20, y: 20, width: kContentSize.width - 1 - 20 * 2, height: kContentSize.height - 20 * 2)
            outputView.addSubview(console)
        }
    }

    // MARK: - Setup Content

    func loadContent(_ view: UIView) {
        // Override this
    }

    func isEnableConsole() -> Bool {
        return false
    }

    // MARK: - Live view size

    func liveViewSize() -> CGSize {
        if isEnableConsole() {
            return CGSize(width: kContentSize.width * 2, height: kContentSize.height)
        }
        return kContentSize
    }

}

class Console: UITextView {

    func log(_ text: String, terminator: String = "\n") {
        print(text)

        if superview != nil {
            self.text = self.text + "\(text)\(terminator)"
        }
    }

}

extension UIViewController {

    // MARK: - Alert

    func alert(_ message: String) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

}

// MARK: - GPX Generator App

class GPXGeneratorViewController: LiveViewController, MKMapViewDelegate {

    enum Result<T: Any> {
        case success(T)
        case failure(Error)
    }

    let mainColor = UIColor(displayP3Red: 26 / 255, green: 197 / 255, blue: 186 / 255, alpha: 1)

    var mapView: MKMapView!

    var fromField: UITextField!

    var toField: UITextField!

    var searchButton: UIButton!

    var printButton: UIButton!

    var routes = [MKRoute]()

    override func loadContent(_ view: UIView) {
        // Initialize controls
        mapView = MKMapView()
        mapView.delegate = self
        mapView.frame = CGRect(x: 0, y: 0, width: kContentSize.width, height: kContentSize.height / 2)
        view.addSubview(mapView)

        let controlView = UIView()
        controlView.backgroundColor = .white
        controlView.frame = CGRect(x: 0, y: kContentSize.height / 2, width: kContentSize.width, height: kContentSize.height / 2)
        view.addSubview(controlView)

        var yPosition: CGFloat = 30

        fromField = UITextField()
        fromField.placeholder = "From"
        fromField.font = UIFont.systemFont(ofSize: 17)
        fromField.clearButtonMode = .whileEditing
        fromField.text = from
        fromField.frame = CGRect(x: 40, y: yPosition, width: kContentSize.width - 40 * 2, height: 33)
        controlView.addSubview(fromField)

        yPosition += 33

        let fromBottomSeparator = UIView()
        fromBottomSeparator.backgroundColor = mainColor
        fromBottomSeparator.frame = CGRect(x: 40, y: yPosition, width: kContentSize.width - 40 * 2, height: 1)
        controlView.addSubview(fromBottomSeparator)

        yPosition += 20

        toField = UITextField()
        toField.placeholder = "To"
        toField.font = UIFont.systemFont(ofSize: 17)
        toField.clearButtonMode = .whileEditing
        toField.text = to
        toField.frame = CGRect(x: 40, y: yPosition, width: kContentSize.width - 40 * 2, height: 33)
        controlView.addSubview(toField)

        yPosition += 33

        let toBottomSeparator = UIView()
        toBottomSeparator.backgroundColor = mainColor
        toBottomSeparator.frame = CGRect(x: 40, y: yPosition, width: kContentSize.width - 40 * 2, height: 1)
        controlView.addSubview(toBottomSeparator)

        yPosition += 30

        searchButton = UIButton()
        searchButton.setTitle("Search Directions", for: .normal)
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.backgroundColor = mainColor
        searchButton.addTarget(self, action: #selector(searchDidTapped(_:)), for: .touchUpInside)
        searchButton.frame = CGRect(x: 40, y: yPosition, width: kContentSize.width - 40 * 2, height: 33)
        controlView.addSubview(searchButton)

        printButton = UIButton()
        printButton.setTitle("Print GPX", for: .normal)
        printButton.setTitleColor(.white, for: .normal)
        printButton.setTitleColor(.lightGray, for: .disabled)
        printButton.backgroundColor = mainColor
        printButton.addTarget(self, action: #selector(printDidTapped(_:)), for: .touchUpInside)
        printButton.isEnabled = false
        printButton.frame = CGRect(x: 40, y: controlView.frame.size.height - 33 - 20, width: kContentSize.width - 40 * 2, height: 33)
        controlView.addSubview(printButton)
    }

    override func isEnableConsole() -> Bool {
        return true
    }

    // MARK: - Map view delegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 3
            renderer.strokeColor = .blue
            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    // MARK: - Actions

    @IBAction func searchDidTapped(_ sender: Any) {
        guard let from = fromField.text, from.isEmpty == false else {
            alert("From location is required.")
            return
        }

        guard let to = toField.text, to.isEmpty == false else {
            alert("To location is required.")
            return
        }

        searchPlacemarks(from: from, to: to)
    }

    @IBAction func printDidTapped(_ sender: Any) {
        let coordinates = adjustCoordinates(from: routes)
        let gpx = generateGPX(from: coordinates)

        console.log(gpx)
    }

    // MARK: - Search methods

    private func searchPlacemarks(from: String, to: String) {
        let addresses = [from, to]
        var placemarks = [CLPlacemark]()
        var errors = [Error]()

        // Search placemarks

        let placemarkGroup = DispatchGroup()

        addresses.forEach { (address) in
            placemarkGroup.enter()

            findPlacemark(from: address, completionHandler: { (result) in
                switch result {
                case .success(let placemark):
                    placemarks.append(placemark)
                case .failure(let error):
                    errors.append(error)
                }
                placemarkGroup.leave()
            })
        }

        placemarkGroup.notify(queue: .main) {
            if let error = errors.first {
                self.alert(error.localizedDescription)
                return
            }

            self.searchDirections(from: placemarks)
        }
    }

    private func searchDirections(from placemarks: [CLPlacemark]) {
        var routes = [MKRoute]()

        // Search directions

        let routeGroup = DispatchGroup()

        for i in 0..<placemarks.count - 1 {
            let sourcePlacemark = placemarks[i]
            let destinationPlacemark = placemarks[i + 1]

            routeGroup.enter()

            findRoutes(from: sourcePlacemark.location!.coordinate, to: destinationPlacemark.location!.coordinate, completionHandler: { (result) in
                switch result {
                case .success(let findedRoutes):
                    routes.append(contentsOf: findedRoutes)
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }

                routeGroup.leave()
            })
        }

        routeGroup.notify(queue: .main, execute: {
            self.showRoutes(routes)
            self.printButton.isEnabled = (routes.isEmpty == false)
        })
    }

    private func showRoutes(_ routes: [MKRoute]) {
        self.mapView.removeOverlays(self.mapView.overlays)

        self.routes = routes

        self.routes.forEach({ (route) in
            self.mapView.add(route.polyline)

            if self.mapView.overlays.count == 1 {
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                               edgePadding: UIEdgeInsetsMake(10, 10, 10, 10),
                                               animated: false)
            } else {
                let polylineBoundingRect =  MKMapRectUnion(self.mapView.visibleMapRect,
                                                           route.polyline.boundingMapRect)
                self.mapView.setVisibleMapRect(polylineBoundingRect,
                                               edgePadding: UIEdgeInsetsMake(10, 10, 10, 10),
                                               animated: false)
            }
        })
    }

    // MARK: - Geocoging and directions

    private func findPlacemark(from address: String, completionHandler: @escaping (Result<CLPlacemark>) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                completionHandler(.failure(error))
                return
            }

            guard let placemark = placemarks?.first else {
                let error = NSError(domain: "gpx", code: 0, userInfo: [NSLocalizedDescriptionKey: "Placemark not found for \(address)"])
                completionHandler(.failure(error))
                return
            }

            completionHandler(.success(placemark))
        }
    }

    private func findRoutes(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completionHandler: @escaping (Result<[MKRoute]>) -> Void) {
        let request = MKDirectionsRequest()
        request.transportType = .automobile
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))

        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if let error = error {
                completionHandler(.failure(error))
                return
            }

            guard let routes = response?.routes else {
                let error = NSError(domain: "gpx", code: 0, userInfo: [NSLocalizedDescriptionKey: "Route not found from {\(source.latitude), \(source.longitude)} to {\(destination.latitude), \(destination.longitude)}"])
                completionHandler(.failure(error))
                return
            }

            completionHandler(.success(routes))
        }
    }

    // MARK: - Generate GPX

    private func adjustCoordinates(from routes: [MKRoute]) -> [CLLocationCoordinate2D] {
        var output = [CLLocationCoordinate2D]()

        var lastCoordinate: CLLocationCoordinate2D?
        let movePerUpdate: Double = ((speed * 1000) / (60 * 60)) / 2 /* Moving meter per 0.5sec */

        routes.forEach { (route) in
            route.steps.forEach({ (step) in
                var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                                           count: step.polyline.pointCount)

                step.polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: step.polyline.pointCount))

                coordinates.forEach({ (coordinate) in
                    if let lastCoordinate = lastCoordinate {
                        let distance = calcDistance(from: lastCoordinate, to: coordinate)

                        let numberOfWaypoints = distance / movePerUpdate

                        let diffLat = (coordinate.latitude - lastCoordinate.latitude) / numberOfWaypoints
                        let diffLon = (coordinate.longitude - lastCoordinate.longitude) / numberOfWaypoints

                        for i in 0..<Int(numberOfWaypoints) {
                            let lat = lastCoordinate.latitude + (diffLat * Double(i))
                            let lng = lastCoordinate.longitude + (diffLon * Double(i))
                            output.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                        }

                    } else {
                        output.append(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))
                    }

                    lastCoordinate = coordinate
                })
            })
        }

        return output
    }

    private func generateGPX(from coordinates: [CLLocationCoordinate2D]) -> String {
        var gpx = """
              <?xml version="1.0" encoding="UTF-8" standalone="no"?>
              <gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd" version="1.1" >\n
              """

        coordinates.forEach { (coordinate) in
            gpx += """
            <wpt lat="\(coordinate.latitude)" lon="\(coordinate.longitude)" />\n
            """
        }

        gpx += "</gpx>"

        return gpx
    }

    // MARK: - Utility

    func calcDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let sourceLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let destinationLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return destinationLocation.distance(from: sourceLocation)
    }

}

// Launch the app
let viewController = GPXGeneratorViewController()
viewController.preferredContentSize = viewController.liveViewSize()
PlaygroundPage.current.liveView = viewController
