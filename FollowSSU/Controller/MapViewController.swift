//
//  MapViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/10/14.
//

import UIKit
import NMapsMap
import CoreLocation
import Firebase

class MapViewController: UIViewController, UISearchControllerDelegate, UISearchBarDelegate {
    @IBOutlet weak var map: NMFMapView!
    @IBOutlet weak var changeImageButton: UIButton!
    @IBOutlet weak var backgroundButton: UIImageView!
    @IBOutlet weak var noticeButton: UIButton!
    @IBOutlet weak var instagramButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
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
    let infoWindow = NMFInfoWindow()
    let dataSource = NMFInfoWindowDefaultTextSource.data()
    let majorCode = MajorCode()
    let searchController = UISearchController()
    let lectureRoom = LectureRoom() // 입력한 강의실 번호가 존재하는지 여부를 확인하기 위해
    var isActive: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 뒤로 가기 버튼이 필요없으므로
        self.navigationItem.hidesBackButton = true
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // 사용 권한 거부시 권한 설정 유도하기
        let authorizationStatus: CLAuthorizationStatus
        let manager = CLLocationManager()
        if #available(iOS 14, *) {
            authorizationStatus = manager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        switch authorizationStatus {
        case .denied:
            setAuthAlertAction()
        default:
            print("Auth Error")
        }
        
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
        
        // 자동 로그인되었다면 timestamp 업데이트
        if UserDefaults.standard.bool(forKey: "AutoLogin") {
            let ref = Database.database().reference(withPath: "userInfo")
            let token = UserDefaults.standard.string(forKey: "fcmToken") ?? "Not Found Token"
            let userItemRef = ref.child(majorCode.codes[std.major]!).child(token)
            let timestamp = Date().timeIntervalSince1970.rounded()
            let values: [String: Double] = ["timestamp":timestamp]
            userItemRef.setValue(values)
        }
        
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
        
        // 네비게이션 제목 설정과 search textfield 설정
        searchController.searchBar.delegate = self
        searchController.delegate = self
        searchController.searchBar.placeholder = "강의실 번호를 검색해보세요"
        searchController.searchBar.setValue("취소", forKey: "cancelButtonText")
        // 인사말 설정
        let label = UILabel()
        label.text = "\(std.name)님, 안녕하세요"
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 20)
        let fullText = label.text ?? ""
        let attribtuedString = NSMutableAttributedString(string: fullText)
        let range = (fullText as NSString).range(of: "\(std.name)님")    // 사용자 이름만 색상을 바꾸기 위해
        attribtuedString.addAttribute(.foregroundColor, value: UIColor(named: "AccentColor")!, range: range)
        label.attributedText = attribtuedString
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: label)
        navigationItem.searchController = searchController
        navigationController?.navigationBar.backgroundColor = .white
        
        self.backgroundButton.alpha = 0.0
        self.noticeButton.alpha = 0.0
        self.instagramButton.alpha = 0.0
        self.logoutButton.alpha = 0.0
    }
    
    @IBAction func buttonStart(_ sender: UIButton) {
        if isActive {
            isActive = false
            changeImageButton.setImage(UIImage(named: "minusBtn"), for: .normal)
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.backgroundButton.alpha = 1.0
                self.noticeButton.alpha = 1.0
                self.instagramButton.alpha = 1.0
                self.logoutButton.alpha = 1.0
            })
        }
        else {
            isActive = true
            changeImageButton.setImage(UIImage(named: "plusBtn"), for: .normal)
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.backgroundButton.alpha = 0.0
                self.noticeButton.alpha = 0.0
                self.instagramButton.alpha = 0.0
                self.logoutButton.alpha = 0.0
            })
        }
    }
    func setAuthAlertAction() {
        let authAlertController: UIAlertController
        authAlertController = UIAlertController(title: "위치 권한 요청", message: "위치 권한을 허용해야만 앱을 사용할 수 있습니다.", preferredStyle: UIAlertController.Style.alert)
        let getAuthAction: UIAlertAction
        getAuthAction = UIAlertAction(title: "확인", style: UIAlertAction.Style.default, handler: { (UIAlertAction) in
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        })
        authAlertController.addAction(getAuthAction)
        self.present(authAlertController, animated: true, completion: nil)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
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
            self.locationManager.startUpdatingLocation()
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
        // 지도를 탭하면 정보 창을 닫음
        infoWindow.close()
    }
}

//MARK: - UITextFieldDelegate, 강의실 찾기 기능
extension MapViewController: UITextFieldDelegate {
    // alert을 띄워주는 메서드
    func showAlert() {
        let alert = UIAlertController(title: "잘못된 번호", message: "번호가 올바르지 않습니다.", preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        alert.addAction(defaultAction)
        present(alert, animated: true, completion: nil)
    }
    
    // 올바른 건물번호를 체크하는 메서드
    func checkArchitectureNum(_ searchTextField: String) -> Bool {
        let separatedStr = searchTextField.map{String($0)}
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
        
        if self.lectureNum.map({String($0)}).first == "B" { // 지하에 있는 강의실일 경우
            dataSource.title = "지하 \(self.lectureNum.map{String($0)}[1...].joined())호"
        }
        else {
            if self.lectureNum.count == 3 { // 10층 미만인 강의실일 경우
                dataSource.title = "\(self.lectureNum.map{String($0)}.first ?? "0")층  \(self.lectureNum)호"
            }
            else {  // 10층 이상이거나 "-"가 존재할 경우
                if let num = Int(self.lectureNum) { // 10층 이상일 경우
                    dataSource.title = "\(self.lectureNum.map{String($0)}.prefix(2).joined())층  \(num)호"
                }
                else {  // "-"가 존재한 경우
                    dataSource.title = "\(self.lectureNum.map{String($0)}.first ?? "0")층  \(self.lectureNum)호"
                }
            }
        }
        infoWindow.dataSource = dataSource
        // 마커를 탭하면:
//        let handler = { [weak self] (overlay: NMFOverlay) -> Bool in
//            if let marker = overlay as? NMFMarker {
//                if marker.infoWindow == nil {
//                    // 현재 마커에 정보 창이 열려있지 않을 경우 엶
//                    self?.infoWindow.open(with: marker)
//                } else {
//                    // 이미 현재 마커에 정보 창이 열려있을 경우 닫음
//                    self?.infoWindow.close()
//                }
//            }
//            return true
//        };
//
//        marker.touchHandler = handler
        markers.append(marker)
        // 해당 건물에 대한 마커 생성
        for i in markers {
            i.mapView = mapView
        }
        self.infoWindow.open(with: marker)  // 마커를 탭하지 않고 정보 창 생성
        // 마커로 카메라 이동
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: architecture.positions[Int(architectureNum)!-1].lat, lng: architecture.positions[Int(architectureNum)!-1].lng))
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
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
        UserDefaults.standard.set(false, forKey: "AutoLogin")   // 자동 로그인 해제
        self.navigationController?.popToRootViewController(animated: true)
        let token = UserDefaults.standard.string(forKey: "fcmToken") ?? "not found token"
        Database.database().reference(withPath: "userInfo").child(majorCode.codes[std.major]!).child(token).removeValue()   // 저장된 FCM 토큰 삭제
    }
}

// MARK: - 인스타그램 불러오기 기능
extension MapViewController {
    @IBAction func instaPressed(_ sender: UIButton) {
        print("insta pressed")
        let Username = instagram.instagram[std.major]
        let appURL = URL(string: "instagram://user?username=\(Username ?? "")")!
        let application = UIApplication.shared
        
        if application.canOpenURL(appURL) {
            application.open(appURL)
        } else {
            // 인스타그램 앱이 설치되지 않았으면, Safari로 오픈
            let webURL = URL(string: "https://instagram.com/\(Username ?? "")")!
            application.open(webURL)
        }
    }
}

extension MapViewController {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchBar: \(searchBar.text ?? "")")
        if lectureRoom.noNumber.contains(searchBar.text ?? "") && checkArchitectureNum(searchBar.text ?? "") {    // 존재하는 강의실일 경우
            createMarker()
        }
        else if let num = Int(searchBar.text!) {
            if binarySearch(lectureRoom.lectureRooms, num: num) && checkArchitectureNum(searchBar.text ?? "") {
                createMarker()
            }
            else {
                showAlert()
            }
        }
        else {
            showAlert()
        }
//        let length = searchBar.text!.count    // searchTextField의 길이
//        if length == 5 {    // 5글자라면 모두 숫자이어야 한다.
//            if Int(searchBar.text!) != nil {  // 모두 숫자인 경우
//                if checkArchitectureNum(searchBar.text!) { // 올바른 건물 번호라면 해당 건물에 마커 생성
//                    print("5글자 올바른 건물 번호입니다.")
//                    createMarker()
//                }
//            }
//            else {
//                showAlert()
//            }
//        }
//        else if length == 6 {   // 6글자라면 지하에 있는 강의실이므로 지정된 위치에 B가 존재해야 한다.
//            if searchBar.text!.filter({$0.isNumber == true}).count == length-1  && searchBar.text!.map({String($0)})[2] == "B" {
//                if checkArchitectureNum(searchBar.text!) {
//                    print("6글자 올바른 건물 번호입니다.")
//                    createMarker()
//                }
//            }
//            else {
//                showAlert()
//            }
//        }
//        else {  // alert 메서드 호출
//            showAlert()
//        }
    }
    func binarySearch(_ array: [Int], num: Int) -> Bool {
        var start = 0
        var end = (array.count - 1)
        
        while start <= end {
            let mid = (start + end) / 2
            
            if array[mid] == num { return true }
            if array[mid] > num {
                end = mid - 1
            } else {
                start = mid + 1
            }
        }
        return false
    }

}
