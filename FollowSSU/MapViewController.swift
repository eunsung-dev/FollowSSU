//
//  MapViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/10/14.
//

import UIKit

class MapViewController: UIViewController {
    var std: Student = Student()
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    }
    
}
