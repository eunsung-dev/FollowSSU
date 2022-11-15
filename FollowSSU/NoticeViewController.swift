//
//  NoticeViewController.swift
//  FollowSSU
//
//  Created by 최은성 on 2022/11/07.
//

import Foundation
import UIKit
import SwiftSoup
import RxSwift

class NoticeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let major: Major = Major()
    let defaults = UserDefaults.standard
    var selectedMajor = ""
    var notice: [Notice] = []
    var selectedContent = "빈 내용"
    var contents: [String] = []

    @IBOutlet var table: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Userdefaults 정보를 불러온다.
        if let savedPerson = defaults.object(forKey: "Info") as? Data {
            let decoder = JSONDecoder()
            if let loadedPerson = try? decoder.decode(Student.self, from: savedPerson) {
                print("불러온 정보: \(loadedPerson)")
                selectedMajor = loadedPerson.major
            }
        }
        // 저장되어 있는 학과를 토대로 해당 학과 공지사항을 불러온다.
        if let firstIndex = major.allMajors.firstIndex(of: selectedMajor) {
            let myURL = major.allUrls[firstIndex]
            fetchTitle(myURL)
        }
        
        table.delegate = self
        table.dataSource = self
//        self.table.separatorStyle = UITableViewCell.SeparatorStyle.none // 분리선 제거
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        var student = Student(name: name, studentID: studentID, major: major)
        guard let vc = segue.destination as? ContentViewController
        else { fatalError("Segue destination is not found") }
        vc.contents = selectedContent
    }
    
    // 하나의 cell에 하나의 section을 두겠다. Why? section마다 spacing을 주기 위해서.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return notice.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NoticeTableViewCell
        
        let selectedNotice = notice[indexPath.section]
        cell.noticeTextLabel?.text = selectedNotice.title
        cell.layer.cornerRadius = 30
        cell.layer.borderWidth = 1
//        cell.backgroundColor = .blue
//        selectedContent = ""
//        fetchContent(URL(string: notice[indexPath.section].url))
//        contents.append(selectedContent)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

//     Set the spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
        
    // method to run when table view cell is tapped
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // note that indexPath.section is used rather than indexPath.row
            print("You tapped cell number \(indexPath.section).")
            selectedContent = ""
            fetchContent(URL(string: notice[indexPath.section].url))    // 각 제목에 맞는 내용 불러오기
            let destinationVC = ContentViewController()
//            destinationVC.contents = contents[indexPath.section]
            print("selectedContent: \(selectedContent)")
            print("destinationVC.contents: \(destinationVC.contents)")
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ContentViewController") as? ContentViewController else { return }
            vc.contents = selectedContent
            self.present(vc, animated: true)
//            destinationVC.performSegue(withIdentifier: "goToContent", sender: self)
            
//            print("fetchContent 메서드 불러옴")
//            performSegue(withIdentifier: "goToContent", sender: nil)
//            print("selectedContent")
//            print(selectedContent)
        }
    
    // MARK: - 제목 가져오기
    func fetchTitle(_ url: URL?) {
            if let url = url {
                do {
                    let webString = try String(contentsOf: url)
                    let document = try SwiftSoup.parse(webString)
                    let contents = try document.getElementsByClass("bbs_list").select("tr").array()
//                    print(contents)
                    for content in contents {
                        if try content.select("td").hasClass("center") {    // 번호가 공지가 아닌 숫자인 공지사항만 불러오겠다.
                            let noticeUrl = try content.select("a").attr("href")    // 공지사항 게시글 url 저장
                            let c = try content.select("td").array().map{try $0.text()}
                            notice.append(Notice(number: c[0], title: c[1], url: "\(url)\(noticeUrl)" , date: c[3]))
                        }
                    }
                    
                } catch let error {
                    print(error)
                }
            }
        }
    
    // MARK: - 내용 가져오기
    func fetchContent(_ url: URL?) {
        if let url = url {
            do {
                let webString = try String(contentsOf: url)
                let document = try SwiftSoup.parse(webString)
                print("########## 가져온 내용 ##########")
                let contents = try document.getElementsByClass("content").select("p").array()
                for c in contents {
//                    print(try c.text())
                    selectedContent += "\(try c.text())\n"
                }
            } catch let error {
                print(error)
            }
        }
    }
}
