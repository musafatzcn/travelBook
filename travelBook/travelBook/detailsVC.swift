//
//  detailsVC.swift
//  travelBook
//
//  Created by mustafa tezcan on 22.04.2023.



import UIKit
import MapKit
import CoreData

class detailsVC: UIViewController, MKMapViewDelegate , CLLocationManagerDelegate{

    
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var map: MKMapView!
    
    var saveButton : UIBarButtonItem!
    var chosenId : UUID?
    var locationManager = CLLocationManager() // kullanıcının konumuyla alakalı işlemler için.
    let annotation = MKPointAnnotation()
    
    var choosenLatitude = Double()
    var choosenLongtitude = Double()

    var annotationLatitude : Double!
    var annotationLongtitude : Double!
    
    var button : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        map.delegate = self
        locationManager.delegate = self
        
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest// frequency of locating location // chosing the best will increase battery usage.
        locationManager.requestWhenInUseAuthorization()//only update the location when in use.
        locationManager.startUpdatingLocation()

        saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem = saveButton
        
        if chosenId != nil {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
            
            let idString = chosenId?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@" , idString!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0  {
                    for result in results as! [NSManagedObject] {
                        if let name = result.value(forKey: "name") as? String{
                            nameField.text = name
                        }
                        if let comment = result.value(forKey: "comment") as? String{
                            commentField.text = comment
                        }
                        
                        if let savedLatitude = result.value(forKey: "latitude") as? Double {
                            if let savedLongtitude = result.value(forKey: "longtitude") as? Double {
                                //to save location of the choose row so we can use it in maps to go there.
                                annotationLatitude = savedLatitude
                                annotationLongtitude = savedLongtitude
                                
                                
                                let annotation = MKPointAnnotation()
                                //to show the choosen place from list.
                                let location = CLLocationCoordinate2D(latitude: savedLatitude, longitude: savedLongtitude)
                                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                let region = MKCoordinateRegion(center: location, span: span)
                                
                                annotation.coordinate = CLLocationCoordinate2D(latitude: savedLatitude, longitude: savedLongtitude)
                                annotation.title = nameField!.text
                                annotation.subtitle = commentField!.text

                                map.setRegion(region, animated: true)
                                map.addAnnotation(annotation)
                            }
                        }
                         
                        
                    }
                }
                
            }catch{
                print("error!")
            }
        }
        
        //hide keyboard when user click on the screen
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        
        //if user press the map for a second :
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 1
        map.addGestureRecognizer(longPressGesture)
        
    }
    
    //for actions to be taken as location is updated.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //if i click add button it will bring me to my current location.
        if chosenId == nil {
            //locations variable stores the location in an array as latitude and longitude.
            //store the current location from the location variable . 0th element returns current location
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            //how close i will zoom the latitude and longitude
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            //where will the center be
            let region = MKCoordinateRegion(center: location, span: span)
            map.setRegion(region, animated: true)
            
            //to pin the current location.
            annotation.coordinate = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            map.addAnnotation(annotation)
            
            choosenLatitude = locations[0].coordinate.latitude
            choosenLongtitude = locations[0].coordinate.longitude
        }
        
    }
     
    
    // to customize the pin.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
            
        }
        else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    // to open the maps when the button above the location is clicked.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if chosenId != nil {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongtitude)
            
            
            //koordinatlar ve yerler arasında bağlantı kurmaya yarayan sınıf
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                //closure
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem (placemark: newPlacemark)
                        item.name = self.nameField.text
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                

            }
            
            
        }
    }
    
    
    //save function.
    @objc func save() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newLocations = NSEntityDescription.insertNewObject(forEntityName: "Locations", into: context)
        
        newLocations.setValue(nameField.text!, forKey: "name")
        newLocations.setValue(commentField.text!, forKey: "comment")
        newLocations.setValue(UUID(), forKey: "id")
        newLocations.setValue(choosenLatitude, forKey: "latitude")
        newLocations.setValue(choosenLongtitude, forKey: "longtitude")
        
        do{
            try context.save()
            print("saved!")
        }catch{
            print("error!")
        }
        
        //to update my list by alerting the view controller when I click the save button.
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)
        
        // to return after clicking the save button.
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.map)
            let coordinate = self.map.convert(touchPoint, toCoordinateFrom: self.map)
            
            choosenLatitude = coordinate.latitude
            choosenLongtitude = coordinate.longitude
            
            annotation.coordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            annotation.title = nameField!.text
            annotation.subtitle = commentField!.text
        
  

            self.map.addAnnotation(annotation)
        }
 

    }

}
