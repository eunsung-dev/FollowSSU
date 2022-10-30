//
//  MapViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/10/14.
//

import UIKit
import NMapsMap
import CoreLocation

class MapViewController: UIViewController {
    @IBOutlet weak var map: NMFMapView!
    @IBOutlet weak var searchTextField: UITextField!
    var std: Student = Student()
    let defaults = UserDefaults.standard
    var searchName: String = ""
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 뒤로 가기 버튼이 필요없으므로
        self.navigationItem.hidesBackButton = true
        
        print("자동 로그인 여부: \(UserDefaults.standard.bool(forKey: "AutoLogin"))")
        // 구조체 단위로 학생 정보를 UserDefaults 통해 로컬에 저장
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(std) {
            defaults.set(encoded, forKey: "Info")
        }
        if let savedPerson = defaults.object(forKey: "Info") as? Data {
            let decoder = JSONDecoder()
            if let loadedPerson = try? decoder.decode(Student.self, from: savedPerson) {
                print("불러온 정보: \(loadedPerson)")
            }
        }
        searchTextField.delegate = self
        // 지도 불러오기
        locationManager.delegate = self
        getLocationUsagePermission()
        
        locationManager.requestLocation()
        
        let mapView = NMFMapView(frame: map.frame)
        map.addSubview(mapView)
        
        mapView.touchDelegate = self
        mapView.zoomLevel = 17.5
        
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: locationManager.location?.coordinate.latitude ?? 0, lng: locationManager.location?.coordinate.longitude ?? 0))
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
        
        mapView.positionMode = .direction
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            print("lat: ",lat)
            print("lon: ",lon)
        }
    }
    
    // 반드시 있어야 함.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func getLocationUsagePermission() {
        self.locationManager.requestWhenInUseAuthorization()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("GPS 권한 설정됨")
            self.locationManager.startUpdatingLocation() // 중요!
        case .restricted, .notDetermined:
            print("GPS 권한 설정되지 않음")
            getLocationUsagePermission()
        case .denied:
            print("GPS 권한 요청 거부됨")
            getLocationUsagePermission()
        default:
            print("GPS: Default")
        }
    }
}

//MARK: - MapView Touch Delegate

 extension MapViewController: NMFMapViewTouchDelegate {
     func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
         print("\(latlng.lat), \(latlng.lng)")
     }
 }

//MARK: - UITextFieldDelegate

extension MapViewController: UITextFieldDelegate {
    @IBAction func searchPressed(_ sender: UIButton) {
            searchTextField.endEditing(true)
            print(searchTextField.text!)
        }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.endEditing(true)
        print(searchTextField.text!)
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text != "" {
            return true
        } else {
            textField.placeholder = "입력해주세요"
            return false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let name = searchTextField.text {
            searchName = name
            print("저장: \(searchName)")
        }
        searchTextField.text = ""
    }

    // 텍스트필드 밖을 클릭할 때 키보드를 내린다.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
         self.view.endEditing(true)
   }

}
