//
//  ConfirmViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/10/07.
//

import UIKit
import RxSwift

class ConfirmViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var majorTextField: UITextField!
    @IBOutlet weak var studentIDTextField: UITextField!
    var text = ""
    var name = ""   // 이름
    var studentID = ""  // 학번
    var major = ""  // 전공
    var comparedMajor: Major = Major()
    var selectedStudentSubject = PublishSubject<Student>()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.segueTextField.text = text // 전달받은 텍스트를 저장함.
//        segueTextField.numberOfLines = .max
        separatedData(text)
        nameTextField.text = name
        studentIDTextField.text = studentID
        majorTextField.text = major
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        var student = Student(name: name, studentID: studentID, major: major)
        guard let vc = segue.destination as? MapViewController
        else { fatalError("Segue destination is not found") }
        selectedStudentSubject.subscribe(onNext: { student in
            vc.std = student
        })
        .disposed(by: disposeBag)
        selectedStudentSubject.onNext(Student(name: name, studentID: studentID, major: major))
    }
    
    // 로그인 버튼 클릭 시 View 이동과 함께 데이터 전달(이 데이터는 UserDefaults로 로컬에 저장됨)
    @IBAction func clickButton(_ sender: UIButton) {
        
//        var student = Student(name: name, studentID: studentID, major: major)
//        print(student)
//        guard let vc = storyboard?.instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
//        vc.std = student
    }
    
    // MARK: - 전달받은 텍스트에서 필요한 정보를 추출하는 메서드
    func separatedData(_ str: String) {
        print(str)
        for s in str.components(separatedBy: "\n") {
            if s.prefix(2) == "이름" || (s.count == 3 && s != "학생증") || (s.count == 3 && s != "학생중") {
                let extractedStr = s.components(separatedBy: " ")
                if extractedStr.count > 1 {
                    name = extractedStr[2]
                }
                else {
                    name = s
                }
            }
            
            if s.suffix(2) == "학부" || s.suffix(2) == "학과" { // 전공 추출
                let extractedStr = s.components(separatedBy: " ")
                if extractedStr.count > 1 { // 모바일 학생증에 대한 처리
//                    major = accurateMajor(extractedStr[1])
                    major = String(s.replacingOccurrences(of: " ", with: "")[s.index(s.startIndex, offsetBy: 3)...])
                }
                else {
//                    major = accurateMajor(s)
                    major = s
                }
                continue
            }
            let extractedStr = s.components(separatedBy: " ")
            if extractedStr.count > 1 && extractedStr[1].count == 8 {   // 학번 추출
                studentID = extractedStr[1]
            }
        }
//        print("전공: \(major)")
//        print("학번: \(studentID)")
    }
    
    //MARK: - 전공 인식 정확성 향상 메서드
    // 전공이 한글이므로 정확성 문제로 인하여 현재 존재하는 학과와 비교하면서 가장 유사한 전공을 리턴한다.
    func accurateMajor(_ str: String) -> String {
        for i in comparedMajor.allMajors {
            var cnt = 0
            for j in str {
                if String(i) == String(j) {
                   cnt += 1
                }
            }
            if cnt > str.count/2 {
                return i
            }
        }
        return "Not Found"
    }
    
    // 화면을 터치하여 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){self.view.endEditing(true)}
    // 리턴키 델리게이트 처리
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


extension String {
    subscript(_ index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
}
