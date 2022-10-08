//
//  ViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/10/05.
//

import UIKit
import VisionKit
import Vision
import PhotosUI // WWDC20 참고. UIImagePickerController를 대체.

class ViewController: UIViewController {
    
    var request = VNRecognizeTextRequest(completionHandler: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    //MARK: - 학생증을 스캔하여 로그인 버튼 클릭 시
    @IBAction func onClick(_ sender: UIButton) {
        configureDocumentView()
    }
    
    private func configureDocumentView() {
        let scanningDocumentVC = VNDocumentCameraViewController()
        scanningDocumentVC.delegate = self
        self.present(scanningDocumentVC, animated: true, completion: nil)
    }
    
    //MARK: - 모바일 학생증으로 로그인 버튼 클릭 시
    @IBAction func touchUpInsideCameraButton(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images  // 이미지만 불러옴
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
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
                
//                DispatchQueue.main.async {
//                }
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
            guard let vc = self.storyboard?.instantiateViewController(identifier: "navPush") as? ConfirmViewController else {return}
            vc.text = data
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) //   먼저 picker를 dismiss시켜줍니다.
        let itemProvider = results.first?.itemProvider // itemProvider를 가져옵니다. itemProvider는 선택된 asset의 Representation이라고 해요.
        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) { // provider가 내가 지정한 타입을 로드할 수 있는지 먼저 체크를 한 뒤
            itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in // 로드 할 수 있으면 로드를 합니다.
                DispatchQueue.main.async {
                    self.setupVisionTextRecognizeImage(image: image as? UIImage)
//                    self.myImageView.image = image as? UIImage // 5
                }
            }
        } else {
            // TODO: Handle empty results or item provider not being able load UIImage
        }
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
        //            recognizeTextRequest.recognitionLevel = .accurate
        
        for image in images {
            let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
            
            try? requestHandler.perform([recognizeTextRequest])
        }
        
        print(entireRecognizedText)
        return entireRecognizedText
    }
    
}

