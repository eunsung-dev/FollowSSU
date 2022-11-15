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
import RxSwift

class ViewController: UIViewController {
    
    var request = VNRecognizeTextRequest(completionHandler: nil)
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var majorTextField: UITextField!
    @IBOutlet weak var toggle: UISwitch!
    var text = ""
    var name = ""   // 이름
    var major = ""  // 전공
    var comparedMajor: Major = Major()
    var selectedStudentSubject = PublishSubject<Student>()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // 자동 로그인 기능 구현
        if UserDefaults.standard.bool(forKey: "AutoLogin") {
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
            self.show(vc, sender: nil)
        }
        checkCameraPermission() // 카메라 사용 권한
        checkLocationPermission()   // 위치 정보 사용 권한
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        var student = Student(name: name, studentID: studentID, major: major)
        guard let vc = segue.destination as? MapViewController
        else { fatalError("Segue destination is not found") }
        selectedStudentSubject.subscribe(onNext: { student in
            vc.std = student
        })
        .disposed(by: disposeBag)
        selectedStudentSubject.onNext(Student(name: nameTextField.text ?? "nil", major: majorTextField.text ?? "nil"))
    }
    //MARK: - 로그인 버튼 클릭 시
    @IBAction func onClickLogin(_sender: UIButton) {
        print("onClickLogin")
        UserDefaults.standard.set(toggle.isOn, forKey: "AutoLogin")
    }
    
    //MARK: - 토글 클릭 시
    @IBAction func onClickToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(toggle.isOn, forKey: "AutoLogin")
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
        // setupTextRecognition
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
        
        // add some properties
        request.recognitionLanguages = ["en-US", "ko-KR"]
        request.automaticallyDetectsLanguage = true
        
        let requests = [request]
        
        // creating request handler
        
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
        print("")
        print("===============================")
        print("[MainController > checkCameraPermission() : 카메라 권한 요청 실시]")
        print("===============================")
        print("")
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
            if granted {
                print("")
                print("===============================")
                print("[MainController > checkCameraPermission() : 카메라 권한 허용 상태]")
                print("===============================")
                print("")
            } else {
                print("")
                print("===============================")
                print("[MainController > checkCameraPermission() : 카메라 권한 거부 상태]")
                print("===============================")
                print("")
//                self.permissionNoArray.append("카메라")
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
//                    print(maxStr)
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
        recognizeTextRequest.automaticallyDetectsLanguage = true
        
        print(try! VNRecognizeTextRequest().supportedRecognitionLanguages())
        
        for image in images {
            let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
            
            try? requestHandler.perform([recognizeTextRequest])
        }
        
        print(entireRecognizedText)
        return entireRecognizedText
    }
    
}

