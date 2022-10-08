//
//  ConfirmViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/10/07.
//

import UIKit

class ConfirmViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField.delegate = self
        }
    }
    @IBOutlet weak var majorTextField: UITextField! {
        didSet {
            majorTextField.delegate = self
        }
    }
    @IBOutlet weak var studentIDTextField: UITextField! {
        didSet {
            studentIDTextField.delegate = self
        }
    }
    var text = ""
    var name = ""   // 이름
    var studentID = ""  // 학번
    var major = ""  // 전공
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.segueTextField.text = text // 전달받은 텍스트를 저장함.
//        segueTextField.numberOfLines = .max
        separatedData(text)
        nameTextField.text = name
        studentIDTextField.text = studentID
        majorTextField.text = major
        
    }
    
    // MARK: - 전달받은 텍스트에서 필요한 정보를 추출하는 메서드
    func separatedData(_ str: String) {
        for s in str.components(separatedBy: "\n") {
            if s.prefix(2) == "이름" || (s.count == 3 && s != "학생증") {
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
                    major = extractedStr[1]
                }
                else {
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
    // 화면을 터치하여 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){self.view.endEditing(true)}
    // 리턴키 델리게이트 처리
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

