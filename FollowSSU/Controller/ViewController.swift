//
//  ViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/10/05.
//

import UIKit
import VisionKit
import Vision
import AVFoundation
import CoreLocation
import Firebase

class ViewController: UIViewController {
    
    var request = VNRecognizeTextRequest(completionHandler: nil)
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var majorTextField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    var name = ""   // 이름
    var major = ""  // 전공
    var comparedMajor: Major = Major()
    let majorCode = MajorCode()
    
    var pickerView: UIPickerView = UIPickerView()
    
    let list = [        "컴퓨터학부",
                        "소프트웨어학부",
                        "전자정보공학부",
                        "미디어경영학과",
                        "융합특성화자유전공학부",
                        "AI융합학부",
                        "화학공학과",
                        "전기공학부",
                        "기계공학부",
                        "산업정보시스템공학과",
                        "건축학부",
                        "기독교학과",
                        "국어국문학과",
                        "영어영문학과",
                        "독어독문학과",
                        "불어불문학과",
                        "중어중문학과",
                        "일어일문학과",
                        "철학과",
                        "사학과",
                        "문예창작전공",
                        "스포츠학부",
                        "수학과",
                        "물리학과",
                        "화학과",
                        "정보통계보험수리학과",
                        "의생명시스템학부",
                        "사회복지학부",
                        "행정학부",
                        "정치외교학과",
                        "정보사회학과",
                        "언론홍보학과",
                        "평생교육학과",
                        "경제학과",
                        "글로벌통상학과",
                        "금융경제학과",
                        "국제무역학과",
                        "경영학부",
                        "벤처중소기업학과",
                        "회계학과",
                        "금융학부",
                        "혁신경영학과",
                        "벤처경영학과"
    ].sorted()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 자동 로그인 기능 구현
        if UserDefaults.standard.bool(forKey: "AutoLogin") {
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
            self.show(vc, sender: nil)
        }
        checkLocationPermission()   // 위치 정보 사용 권한
        
        
        // 텍스트필드 밑줄 출가
        let bottomLine1 = CALayer()
        bottomLine1.frame = CGRect(x: 0, y: nameTextField.frame.height-2, width: nameTextField.frame.width, height: 2)
        bottomLine1.backgroundColor = UIColor.placeholderText.cgColor
        nameTextField.borderStyle = .none
        nameTextField.layer.addSublayer(bottomLine1)
        let bottomLine2 = CALayer()
        bottomLine2.frame = CGRect(x: 0, y: majorTextField.frame.height-2, width: majorTextField.frame.width, height: 2)
        bottomLine2.backgroundColor = UIColor.placeholderText.cgColor
        majorTextField.borderStyle = .none
        majorTextField.layer.addSublayer(bottomLine2)
        
        // 시작하기 버튼 round 효과 설정
        startButton.layer.cornerRadius = startButton.frame.height/4
        
        // picker 설정
        pickerView.delegate = self
        pickerView.dataSource = self
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(title: "선택", style: .done, target: self, action: #selector(done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        majorTextField.inputView = pickerView
        majorTextField.inputAccessoryView = toolbar
        
        
        nameTextField.delegate = self
    }
    
    @objc func done() {
        majorTextField.endEditing(true)
        majorTextField.text = "\(list[pickerView.selectedRow(inComponent: 0)])"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
    }
    
    
    //MARK: - 로그인 버튼 클릭 시
    @IBAction func onClickLogin(_sender: UIButton) {
        print("onClickLogin")
        if nameTextField.text == "" || majorTextField.text == "" {
            showAlert()
        }
        else {
            UserDefaults.standard.set(true, forKey: "AutoLogin")
            // 생성된 토큰 저장
            let ref = Database.database().reference(withPath: "userInfo")
            let token = UserDefaults.standard.string(forKey: "fcmToken") ?? "Not Found Token"
            let userItemRef = ref.child(majorCode.codes[majorTextField.text!]!).child(token)
            let timestamp = Date().timeIntervalSince1970.rounded()
            let values: [String: Double] = ["timestamp":timestamp]
            userItemRef.setValue(values)
            
            // 데이터 전달
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController
            else { fatalError("Segue destination is not found") }
            vc.std.name = nameTextField.text ?? "nil"
            vc.std.major = majorTextField.text ?? "nil"
            print("vc.std: \(vc.std)")
            self.navigationController?.pushViewController(vc, animated: true)
            // 로그인하였으니 텍스트 필드에 있는 개인 정보 삭제
            nameTextField.text = ""
            majorTextField.text = ""
        }        
    }
    func showAlert() {
        let alert = UIAlertController(title: "잘못된 입력", message: "이름과 전공을 모두 입력해주세요.", preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        alert.addAction(defaultAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - 개인정보 처리방침 클릭 시
    @IBAction func onClickInfo(_ sender: UIButton) {
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "InfoViewController") as? InfoViewController else { return }
        
        nextVC.modalTransitionStyle = .coverVertical
        nextVC.modalPresentationStyle = .automatic
        
        self.present(nextVC, animated: true, completion: nil)
    }
    
    //MARK: - 카메라 버튼 클릭 시
    @IBAction func onClickCamera(_ sender: UIButton) {
        configureDocumentView()
    }
    
    private func configureDocumentView() {
        let scanningDocumentVC = VNDocumentCameraViewController()
        scanningDocumentVC.delegate = self
        self.present(scanningDocumentVC, animated: true, completion: nil)
    }
    
    private func setupVisionTextRecognizeImage(image: UIImage?) {
        // TextRecognition 설정
        var textString = ""
        
        request = VNRecognizeTextRequest(completionHandler: {(request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {fatalError("Recieved Invalid Observation")}
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else {
                    print("No candidate")
                    continue
                }
                textString += "\n\(topCandidate.string)"
            }
            self.sendData(textString)
            print(textString)
        })
        // property 추가
        request.recognitionLanguages = ["en-US", "ko-KR"]
        if #available(iOS 16.0, *) {
            request.automaticallyDetectsLanguage = true
        } else {
            // Fallback on earlier versions
        }
        
        let requests = [request]
        // request handler 생성
        DispatchQueue.global(qos: .userInitiated).async {
            guard let img = image?.cgImage else {fatalError("Missing image to scan")}
            let handle = VNImageRequestHandler(cgImage: img, options: [:])
            try? handle.perform(requests)
        }
    }
    
    // MARK: - 데이터 전달
    private func sendData(_ data: String) {
        DispatchQueue.main.async {
            self.separatedData(data)
            self.nameTextField.text = self.name
            self.majorTextField.text = self.major
        }
    }
    
    // MARK: - 카메라 권한 요청
    func checkCameraPermission(){
        print("카메라 권한 요청 실시")
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
            if granted {
                print("카메라 권한 허용 상태")
            } else {
                print("카메라 권한 거부 상태")
            }
        })
    }
    
    // MARK: - 위치 정보 권한 요청
    func checkLocationPermission() {
        let locationManager: CLLocationManager?
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    // MARK: - 전달받은 텍스트에서 필요한 정보를 추출하는 메서드
    func separatedData(_ str: String) {
        for st in str.components(separatedBy: "\n") {
            let s = st.replacingOccurrences(of: " ", with: "")
            if s.prefix(2) == "이름" || (s.count == 3 && s != "학생증") || (s.count == 3 && s != "학생중") {
                if s.prefix(2) == "이름" {    // 모바일 학생증에 대한 처리
                    name = String(s.replacingOccurrences(of: " ", with: "")[s.index(s.startIndex, offsetBy: 3)...])
                }
                else {
                    name = s
                }
            }
            
            if s.suffix(2) == "학부" || s.suffix(2) == "학과" { // 전공 추출
                if s.prefix(2) == "소속" { // 모바일 학생증에 대한 처리
                    major = accurateMajor(String(s.replacingOccurrences(of: " ", with: "")[s.index(s.startIndex, offsetBy: 3)...]))
                }
                else {
                    major = accurateMajor(s)
                }
                continue
            }
        }
    }
    
    //MARK: - 전공 인식 정확성 향상 메서드
    // 전공이 한글이므로 정확성 문제로 인하여 현재 존재하는 학과와 비교하면서 가장 유사한 전공을 리턴한다.
    func accurateMajor(_ str: String) -> String {
        var maxCnt = 0
        var maxStr = ""
        for i in comparedMajor.allMajors {
            var cnt = 0
            if i.count != str.count {
                continue
            }
            for k in i {
                for j in str {
                    if String(k) == String(j) {
                        cnt += 1
                    }
                }
                if cnt > maxCnt {
                    maxCnt = cnt
                    maxStr = i
                }
            }
        }
        return maxStr
    }
}

extension ViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        for pageNumber in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: pageNumber)
            let extractedImages = extractImages(from: scan)
            let processedText = recognizeText(from: extractedImages)
            sendData(processedText)
            print(image)
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func extractImages(from scan: VNDocumentCameraScan) -> [CGImage] {
        var extractedImages = [CGImage]()
        for index in 0..<scan.pageCount {
            let extractedImage = scan.imageOfPage(at: index)
            guard let cgImage = extractedImage.cgImage else { continue }
            extractedImages.append(cgImage)
        }
        return extractedImages
    }
    
    fileprivate func recognizeText(from images: [CGImage]) -> String {
        var entireRecognizedText = ""
        let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
            guard error == nil else { return }
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let maximumRecognitionCandidates = 1
            for observation in observations {
                guard let candidate = observation.topCandidates(maximumRecognitionCandidates).first else { continue }
                entireRecognizedText += "\(candidate.string)\n"
                
            }
        }
        recognizeTextRequest.recognitionLanguages = ["en-US", "ko-KR"]
        if #available(iOS 16.0, *) {
            recognizeTextRequest.automaticallyDetectsLanguage = true
        } else {
            // Fallback on earlier versions
        }
        for image in images {
            let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
            
            try? requestHandler.perform([recognizeTextRequest])
        }
        return entireRecognizedText
    }
    
}

extension ViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return list.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return list[row]
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            majorTextField.becomeFirstResponder()
        }
        return true
    }
}
