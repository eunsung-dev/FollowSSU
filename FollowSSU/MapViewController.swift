//
//  MapViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/10/14.
//

import UIKit
import NMapsMap
import CoreLocation

class MapViewController: UIViewController, UISheetPresentationControllerDelegate {
    @IBOutlet weak var map: NMFMapView!
    @IBOutlet weak var searchTextField: UITextField!
    var std: Student = Student()    // 학생 구조체 단위로 저장하기 위해
    let defaults = UserDefaults.standard
    var searchContent: String = ""
    let architecture: Architecture = Architecture() // 강의실 번호를 매칭하기 위해
    
    var locationManager = CLLocationManager()
    
    var architectureNum = ""    // 건물 번호
    var lectureNum = "" // 강의실 번호
    
    var markers: [NMFMarker] = []   // 보여줄 마커를 저장
    
    var mapView: NMFMapView = NMFMapView()
    
    let instagram: Instagram = Instagram()  // 학과에 해당하는 인스타그램을 연결하기 위해
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 뒤로 가기 버튼이 필요없으므로
        self.navigationItem.hidesBackButton = true
        
        
        print("자동 로그인 여부: \(UserDefaults.standard.bool(forKey: "AutoLogin"))")
        // 기존에 자동 로그인을 선택했다면 다시 저장할 필요가 없으므로
        if !(std.name.isEmpty || std.major.isEmpty) {
            // 구조체 단위로 학생 정보를 UserDefaults 통해 로컬에 저장
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(std) {
                defaults.set(encoded, forKey: "Info")
            }
        }
        if let savedPerson = defaults.object(forKey: "Info") as? Data {
            let decoder = JSONDecoder()
            if let loadedPerson = try? decoder.decode(Student.self, from: savedPerson) {
                print("불러온 정보: \(loadedPerson)")
                std = loadedPerson
            }
        }
        searchTextField.delegate = self
        // 지도 불러오기
        locationManager.delegate = self
        getLocationUsagePermission()
        
        locationManager.requestLocation()
        
        mapView = NMFMapView(frame: map.frame)
        map.addSubview(mapView)
        
        
        mapView.touchDelegate = self
        mapView.zoomLevel = 17.5
        
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: locationManager.location?.coordinate.latitude ?? 0, lng: locationManager.location?.coordinate.longitude ?? 0))
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
        
        mapView.positionMode = .direction
        mapView.mapType = .navi // 지도 타입 변경
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //        if let location = locations.last {
        //            let lat = location.coordinate.latitude
        //            let lon = location.coordinate.longitude
        //            print("lat: ",lat)
        //            print("lon: ",lon)
        //        }
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

//MARK: - UITextFieldDelegate, 강의실 찾기 기능

extension MapViewController: UITextFieldDelegate {
    @IBAction func searchPressed(_ sender: UIButton) {
        searchTextField.endEditing(true)
        print("searchTextField: \(searchTextField.text!)")
        let length = searchTextField.text!.count    // searchTextField의 길이
        if length == 5 {    // 5글자라면 모두 숫자이어야 한다.
            if Int(searchTextField.text!) != nil {  // 모두 숫자인 경우
                if checkArchitectureNum() { // 올바른 건물 번호라면 해당 건물에 마커 생성
                    print("5글자 올바른 건물 번호입니다.")
                    createMarker()
                }
            }
            else {
                showAlert()
            }
            
        }
        else if length == 6 {   // 6글자라면 지하에 있는 강의실이므로 지정된 위치에 B가 존재해야 한다.
            if searchTextField.text!.filter({$0.isNumber == true}).count == length-1  && searchTextField.text![2] == "B" {
                if checkArchitectureNum() {
                    print("6글자 올바른 건물 번호입니다.")
                    lectureNum = "지하\(lectureNum.map{String($0)}[1...].joined())"
                    createMarker()
                }
            }
            else {
                showAlert()
            }
        }
        else {  // alert 메서드 호출
            showAlert()
        }
    }
    
    // alert을 띄워주는 메서드
    func showAlert() {
        let alert = UIAlertController(title: "잘못된 번호", message: "번호가 올바르지 않습니다.", preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        alert.addAction(defaultAction)
        present(alert, animated: true, completion: nil)
    }
    
    // 올바른 건물번호를 체크하는 메서드
    func checkArchitectureNum() -> Bool {
        let separatedStr = searchTextField.text!.map{String($0)}
        architectureNum = separatedStr[0..<2].joined()  // 건물 번호 분리
        lectureNum = separatedStr[2..<separatedStr.count].joined()  // 강의실 번호 분리
        if Int(architectureNum)! > 25 {   // 건물 번호가 25가 넘으면 잘못된 번호이므로 alert show
            showAlert()
            return false
        }
        return true
    }
    
    // 마커를 생성하는 메서드
    func createMarker() {
        print("건물 번호: \(architectureNum)")
        print("강의실: \(lectureNum)")
        // 기존에 마커가 존재하면 있던 마커 삭제
        for i in markers {
            i.mapView = nil
        }
        markers = []    // 마커를 저장하는 배열 초기화
        let marker = NMFMarker()
        // 마커 위치 지정
        marker.position = NMGLatLng(lat: architecture.positions[Int(architectureNum)!-1].lat, lng: architecture.positions[Int(architectureNum)!-1].lng)
        // 마커 캡션 달기
        marker.captionText = architecture.allArchitectures[Int(architectureNum)!-1]
        // 마커 터치 이벤트
        marker.touchHandler = { (overlay: NMFOverlay) -> Bool in
            print("\(self.architectureNum)번 건물 마커 터치")
            // 해당 마커를 클릭 시 해당 건물에 대한 정보와 강의실 번호를 알려주는 Modal View 생성
            let vc = UIViewController()
            vc.view.backgroundColor = .white
            vc.modalPresentationStyle = .pageSheet
            let testLabel = UILabel()
            testLabel.text = "건물: \(self.architecture.allArchitectures[Int(self.architectureNum)!-1])\n강의실: \(self.lectureNum)호"
            testLabel.numberOfLines = 2
            testLabel.translatesAutoresizingMaskIntoConstraints = false // 제약을 받아들일 준비
            vc.view.addSubview(testLabel)

            let testImage = UIImageView(image: UIImage(named: String(Int(self.architectureNum)!)))
            testImage.translatesAutoresizingMaskIntoConstraints = false
            vc.view.addSubview(testImage)
            testImage.topAnchor.constraint(equalTo: testLabel.topAnchor, constant: 60).isActive = true

            if let sheet = vc.sheetPresentationController {
                //지원할 크기 지정
                sheet.detents = [.medium(), .large()]
                //크기 변하는거 감지
                sheet.delegate = self
                //시트 상단에 그래버 표시 (기본 값은 false)
                sheet.prefersGrabberVisible = true
                //처음 크기 지정 (기본 값은 가장 작은 크기)
                //sheet.selectedDetentIdentifier = .large
                //뒤 배경 흐리게 제거 (기본 값은 모든 크기에서 배경 흐리게 됨)
                //sheet.largestUndimmedDetentIdentifier = .medium
            }
            self.present(vc, animated: true, completion: nil)

            return true // 이벤트 소비, -mapView:didTapMap:point 이벤트는 발생하지 않음
        }
        markers.append(marker)
        // 해당 건물에 대한 마커 생성
        for i in markers {
            i.mapView = mapView
        }
        // 마커로 카메라 이동
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: architecture.positions[Int(architectureNum)!-1].lat, lng: architecture.positions[Int(architectureNum)!-1].lng))
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.endEditing(true)
        //        print(searchTextField.text!)
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
            searchContent = name
            print("저장된 내용: \(searchContent)")
        }
        //        searchTextField.text = ""
    }
    
    // 텍스트필드 밖을 클릭할 때 키보드를 내린다.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
    }
    
}

// MARK: - 공지사항 불러오기 기능
extension MapViewController {
    @IBAction func noticePressed(_ sender: UIButton) {
        print("notice pressed")
    }
}

// MARK: - 로그아웃 기능
extension MapViewController {
    @IBAction func logoutPressed(_ sender: UIButton) {
        print("logout pressed")
        UserDefaults.standard.set(false, forKey: "AutoLogin")
        self.navigationController?.popToRootViewController(animated: true)
        // 앱 처음 시작 시 루트 뷰 설정해줘야할듯
//        guard let vc = self.storyboard?.instantiateViewController(identifier: "RootViewController") as? ViewController else {return}
//        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootVC(vc, animated: false)
    }
}

// MARK: - 인스타그램 불러오기 기능
extension MapViewController {
    @IBAction func instaPressed(_ sender: UIButton) {
        print("insta pressed")
        let Username = instagram.instagram[std.major]
        print(std.major)
        let appURL = URL(string: "instagram://user?username=\(Username ?? "")")!
        let application = UIApplication.shared
        
        if application.canOpenURL(appURL) {
            application.open(appURL)
        } else {
            // if Instagram app is not installed, open URL inside Safari
            let webURL = URL(string: "https://instagram.com/\(Username ?? "")")!
            application.open(webURL)
        }
    }
}

// MARK: - UISheetPresentationControllerDelegate

extension ViewController: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        //크기 변경 됐을 경우
        print(sheetPresentationController.selectedDetentIdentifier == .large ? "large" : "medium")
    }
}
