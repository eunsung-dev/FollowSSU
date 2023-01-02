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
    var pageIdx = 2   // 다음 페이지의 공지사항을 불러오기 위해
    var selectedTitle = ""
    var selectedDate = ""
    
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
        
        navigationItem.title = selectedMajor
        
        table.separatorStyle = .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? ContentViewController
        else { fatalError("Segue destination is not found") }
        vc.contents = selectedContent
    }
    
    // 하나의 cell에 하나의 section을 두겠다. Why? section마다 spacing을 주기 위해서.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return notice.count
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "staticCell", for: indexPath) as! StaticCell
            cell.staticLabel?.text = "\(selectedMajor) 홈페이지"
            cell.view.layer.cornerRadius = cell.view.frame.height/4
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NoticeTableViewCell
            
            let selectedNotice = notice[indexPath.row]
            cell.noticeTextLabel?.text = selectedNotice.title
            cell.dateTextLabel?.text = selectedNotice.date
            cell.dateTextLabel.textColor = .gray
            cell.view.layer.cornerRadius = cell.view.frame.height/4
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 70
        }
        else {
            return 100
        }
    }
    
    // cell이 탭되었을 때, 실행되는 메서드
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // note that indexPath.section is used rather than indexPath.row
        if indexPath.section == 0 {
            if let firstIndex = major.allMajors.firstIndex(of: selectedMajor) {
                guard let myURL = major.allUrls[firstIndex] else { return print("url을 찾을 수 없습니다.") }
                UIApplication.shared.open(myURL)
            }
        }
        else {
            print("You tapped cell number \(indexPath.row).")
            selectedContent = ""
            fetchContent(URL(string: notice[indexPath.row].url))    // 각 제목에 맞는 내용 불러오기
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ContentViewController") as? ContentViewController else { return }
            vc.contents = selectedContent
            vc.noticeTitle = notice[indexPath.row].title
            vc.noticeDate = notice[indexPath.row].date
            self.present(vc, animated: true)
        }
    }
    
    // 아래로 스크롤할 때마다 공지사항 계속 불러오기
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == notice.count - 1 {
            // 저장되어 있는 학과를 토대로 해당 학과 공지사항을 불러온다.
            if let firstIndex = major.allMajors.firstIndex(of: selectedMajor) {
                let myURL = major.allUrls[firstIndex]
                switch selectedMajor {
                    // MARK: - IT대학 load more notice
                case "컴퓨터학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page=1", with: "page=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "소프트웨어학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page=1", with: "page=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "글로벌미디어학부":
                    print("미구현")
                case "전자정보공학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "No=1", with: "No=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "융합특성화자유전공학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "offset=0", with: "offset=\((pageIdx-1)*10)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "미디어경영학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page=1", with: "page=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "AI융합학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page=1", with: "page=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                    // MARK: - 공과대학 load more notice
                case "화학공학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "offset=0", with: "offset=\((pageIdx-1)*10)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "유기신소재파이버공학과":
                    print("미구현")
                case "전기공학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "offset=0", with: "offset=\((pageIdx-1)*10)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "기계공학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page=1", with: "page=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "산업정보시스템공학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page/1", with: "page/\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "건축학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page/1", with: "page/\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                    // MARK: - 인문대학 load more notice
                case "기독교학과", "국어국문학과", "영어영문학과", "독어독문학과", "불어불문학과", "중어중문학과", "일어일문학과", "철학과", "사학과", "문예창작전공", "스포츠학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page/1", with: "page/\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                    // MARK: - 자연과학대학 load more notice
                case "수학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "paged=1", with: "paged=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "물리학과", "화학과", "의생명시스템학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page/1", with: "page/\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "정보통계보험수리학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page=1", with: "page=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                    // MARK: - 법과대학 load more notice
                case "법학과":
                    print("미구현")
                case "국제법무학과":
                    print("미구현")
                    // MARK: - 사회과학대학 load more notice
                case "사회복지학부", "행정학부", "정치외교학과", "언론홍보학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page/1", with: "page/\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "정보사회학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "offset=0", with: "offset=\((pageIdx-1)*10)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "평생교육학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page=1", with: "page=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                    // MARK: - 경제통상대학 load more notice
                case "경제학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page=1", with: "page=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "글로벌통상학과", "국제무역학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page/1", with: "page/\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "금융경제학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page=1", with: "page=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                // MARK: - 경영대학 load more notice
                case "경영학부":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page=1", with: "page=\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "벤처중소기업학과", "회계학과", "금융학부","혁신경영학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page/1", with: "page/\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))
                case "벤처경영학과":
                    guard let str = myURL?.absoluteString.replacingOccurrences(of: "page/1", with: "page/\(pageIdx)") else { return print("not found page") }
                    pageIdx += 1
                    fetchTitle(URL(string: str))




                default:
                    print("새로운 데이터를 추가할 수 없습니다.")   // 추후에, 한번만 실행되게 구현해야 함
                }
            }
            self.perform(#selector(loadTable), with: nil, afterDelay: 1.0)
        }
    }
    @objc func loadTable() {
        self.table.reloadData()
    }
    
    // 제목 가져오기
    func fetchTitle(_ url: URL?) {
        if let url = url {
            do {
                let webString = try String(contentsOf: url)
                let document = try SwiftSoup.parse(webString)
                switch selectedMajor {
                    // MARK: - IT대학 fetch title
                case "컴퓨터학부":
                    let contents = try document.getElementsByClass("bbs_list").select("tr").array()
                    for content in contents {
                        if pageIdx == 2 {   // 첫번째 페이지를 불러올 때만 번호가 공지인 게시글을 보여줘야 하므로
                            let noticeUrl = try content.select("a").attr("href")    // 공지사항 게시글 url 저장
                            let c = try content.select("td").array().map{try $0.text()}
                            if !c.isEmpty {
                                notice.append(Notice(number: c[0], title: c[1], url: "http://cse.ssu.ac.kr/03_sub/01_sub.htm\(noticeUrl)" , date: c[3]))
                            }
                        }
                        else {
                            if try content.select("td").hasClass("center") {
                                let noticeUrl = try content.select("a").attr("href")    // 공지사항 게시글 url 저장
                                let c = try content.select("td").array().map{try $0.text()}
                                if !c.isEmpty {
                                    notice.append(Notice(number: c[0], title: c[1], url: "http://cse.ssu.ac.kr/03_sub/01_sub.htm\(noticeUrl)" , date: c[3]))
                                }
                            }
                        }
                    }
                case "소프트웨어학부":
                    let contents = try document.getElementsByClass("bo_list").select("tr").array()
                    for content in contents {
                        if pageIdx == 2 {
                            let noticeUrl = try content.select("a").attr("href").split(separator: "&")[1]    // 공지사항 게시글 url 저장
                            let c = try content.select("td").array().map{try $0.text()}
                            if !c.isEmpty {
                                notice.append(Notice(number: c[0], title: c[1], url: "\(url)&\(noticeUrl)" , date: c[3]))
                            }
                        }
                        else {
                            if try content.getElementsByClass("num").text() != "공지" {
                                let noticeUrl = try content.select("a").attr("href").split(separator: "&")[1]    // 공지사항 게시글 url 저장
                                let c = try content.select("td").array().map{try $0.text()}
                                if !c.isEmpty {
                                    notice.append(Notice(number: c[0], title: c[1], url: "\(url)&\(noticeUrl)" , date: c[3]))
                                }
                            }
                        }
                    }
                case "글로벌미디어학부":
                    print("미구현")
                case "전자정보공학부":
                    let contents = try document.getElementsByClass("list_box").select("a").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("con_box").attr("href")    // 공지사항 게시글 url 저장
                        let title = try content.getElementsByClass("subject on").select("span").text()
                        let date = try content.getElementsByClass("date").text()
                        notice.append(Notice(number: "", title: title, url: "http://infocom.ssu.ac.kr/\(noticeUrl)", date: date))
                    }
                case "융합특성화자유전공학부":
                    let contents = try document.getElementsByClass("board-list").select("li").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("subject").select("a").attr("href")
                        let number = try content.getElementsByClass("num").text()
                        let title = try content.getElementsByClass("subject").text()
                        let date = try content.getElementsByClass("info").select("span")[0].text()
                        notice.append(Notice(number: number, title: title, url: "http://ssuconvergence.co.kr/\(noticeUrl)", date: date))
                    }
                case "미디어경영학과":
                    let contents = try document.select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("bo_tit").select("a").attr("href")    // 공지사항 게시글 url 저장
                        let title = try content.getElementsByClass("bo_tit").select("a").text()
                        let date = try content.getElementsByClass("td_datetime").text()
                        notice.append(Notice(number: "", title: title, url: "\(noticeUrl)", date: date))
                    }
                case "AI융합학부":
                    let contents = try document.getElementsByClass("table").select("tr").array()
                    for idx in 0..<contents.count {
                        if idx == 0 {   // 게시글이 아닌 tr을 안보이게 하기 위해
                            continue
                        }
                        let noticeUrl = try contents[idx].select("a").attr("href")    // 공지사항 게시글 url 저장
                        let c = try contents[idx].select("td").array().map{try $0.text()}
                        if !c.isEmpty {
                            notice.append(Notice(number: "", title: c[0], url: "http://aix.ssu.ac.kr/\(noticeUrl)" , date: c[2]))
                        }
                    }
                    
                    // MARK: - 공과대학 fetch title
                case "화학공학과":
                    let contents = try document.getElementsByClass("board-list").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("subject").select("a").attr("href")    // 공지사항 게시글 url 저장
                        let number = try content.getElementsByClass("no").text()
                        let title = try content.getElementsByClass("subject").select("a").text()
                        let date = try content.getElementsByClass("date").text()
                        notice.append(Notice(number: number, title: title, url: "http://chemeng.ssu.ac.kr/\(noticeUrl)", date: date))
                    }
                case "유기신소재파이버공학과":
                    print("미구현")
                case "전기공학부":
                    let contents = try document.getElementsByClass("board-list2").select("li").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("subject").select("a").attr("href")
                        let number = try content.getElementsByClass("num").text()
                        let title = try content.getElementsByClass("subject").select("a").text()
                        let date = try content.getElementsByClass("date").text()
                        notice.append(Notice(number: number, title: title, url: "http://ee.ssu.ac.kr/\(noticeUrl)", date: date))
                    }
                case "기계공학부":
                    let contents = try document.getElementsByClass("board-list").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("subject").select("a").attr("href")
                        let number = try content.getElementsByClass("w_cell").text()
                        let title = try content.getElementsByClass("subject").select("a").text()
                        guard let date = try content.select("td").array().last?.text() else { return print("날짜를 찾을 수 없습니다.") }
                        notice.append(Notice(number: number, title: title, url: "http://me.ssu.ac.kr/\(noticeUrl)", date: date))
                    }
                case "산업정보시스템공학과":
                    let contents = try document.getElementsByClass("t_list hover").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("title").select("a").attr("href")
                        let number = try content.getElementsByClass("first").text()
                        let title = try content.getElementsByClass("title").select("a").text()
                        let date = try content.select("td").array().map{try $0.text()}[3]
                        notice.append(Notice(number: number, title: title, url: noticeUrl, date: date))
                    }
                case "건축학부":
                    let contents = try document.getElementsByClass("t_list hover").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("title").select("a").attr("href")
                        let title = try content.getElementsByClass("title").select("a").text()
                        let date = try content.select("td").array().map{try $0.text()}[2]
                        notice.append(Notice(number: "", title: title, url: noticeUrl, date: date))
                    }
                    
                    // MARK: - 인문대학 fetch title
                case "기독교학과", "국어국문학과", "영어영문학과", "독어독문학과", "불어불문학과", "중어중문학과", "일어일문학과", "철학과", "사학과", "문예창작전공", "스포츠학부":
                    let contents = try document.getElementsByClass("t_list hover").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("title").select("a").attr("href")
                        let title = try content.getElementsByClass("title").select("a").text()
                        let c = try content.select("td").array().map{try $0.text()}
                        if c.count >= 4 {   // 공지사항 페이지 범위를 넘어가는 것을 막기 위해
                            notice.append(Notice(number: "", title: title, url: noticeUrl, date: c[3]))
                        }
                    }
                    // MARK: - 자연과학대학 fetch title
                case "수학과", "물리학과", "화학과":
                    let contents = try document.getElementsByClass("t_list hover").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("title").select("a").attr("href")
                        let title = try content.getElementsByClass("title").select("a").text()
                        let c = try content.select("td").array().map{try $0.text()}
                        if c.count >= 4 {   // 공지사항 페이지 범위를 넘어가는 것을 막기 위해
                            notice.append(Notice(number: "", title: title, url: noticeUrl, date: c[3]))
                        }
                    }
                case "정보통계보험수리학과":
                    let contents = try document.getElementsByClass("table").select("tbody").select("tr").array()
                    for idx in 0..<contents.count {
                        if idx == 0 {   // 게시글이 아닌 tr을 안보이게 하기 위해
                            continue
                        }
                        let noticeUrl = try contents[idx].select("a").attr("href")    // 공지사항 게시글 url 저장
                        let c = try contents[idx].select("td").array().map{try $0.text()}
                        if c.count >= 4 {   // 공지사항 페이지 범위를 넘어가는 것을 막기 위해
                            notice.append(Notice(number: c[0], title: c[1], url: "http://stat.ssu.ac.kr/\(noticeUrl)", date: c[3]))
                        }
                    }
                case "의생명시스템학부":
                    let contents = try document.getElementsByClass("t_list hover").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("title").select("a").attr("href")
                        let title = try content.getElementsByClass("title").select("a").text()
                        let date = try content.select("td").array().map{try $0.text()}[2]
                        notice.append(Notice(number: "", title: title, url: noticeUrl, date: date))
                    }
                    // MARK: - 법과대학 fetch title
                case "법학과":
                    print("미구현")
                case "국제법무학과":
                    print("미구현")
                    // MARK: - 사회과학대학 fetch title
                case "사회복지학부", "행정학부", "정치외교학과", "언론홍보학과":
                    let contents = try document.getElementsByClass("t_list hover").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("title").select("a").attr("href")
                        let title = try content.getElementsByClass("title").select("a").text()
                        let c = try content.select("td").array().map{try $0.text()}
                        if c.count >= 4 {   // 공지사항 페이지 범위를 넘어가는 것을 막기 위해
                            notice.append(Notice(number: "", title: title, url: noticeUrl, date: c[3]))
                        }
                    }
                case "정보사회학과":
                    let contents = try document.getElementsByClass("board_list").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("subject").select("a").attr("href")
                        let title = try content.getElementsByClass("subject").select("a").text()
                        let c = try content.select("td").array().map{try $0.text()}
                        if c.count >= 5 {   // 공지사항 페이지 범위를 넘어가는 것을 막기 위해
                            notice.append(Notice(number: "", title: title, url: "http://inso.ssu.ac.kr\(noticeUrl.replacingOccurrences(of: "학과공지", with: "%ED%95%99%EA%B3%BC%EA%B3%B5%EC%A7%80"))", date: c[4]))
                        }
                    }
                case "평생교육학과":
                    let contents = try document.getElementsByClass("board_list").select("tbody").select("tr").array()
                    for idx in 0..<contents.count {
                        if idx == 0 {   // 게시글이 아닌 tr을 안보이게 하기 위해
                            continue
                        }
                        let noticeUrl = try contents[idx].getElementsByClass("subject").select("a").attr("href")    // 공지사항 게시글 url 저장
                        let title = try contents[idx].getElementsByClass("subject").select("a").text()
                        let date = try contents[idx].getElementsByClass("datetime").text()
                        notice.append(Notice(number: "", title: title, url: noticeUrl.replacingOccurrences(of: "../", with: "http://lifelongedu.ssu.ac.kr/"), date: date))
                    }
                    // MARK: - 경제통상대학 fetch title
                case "경제학과":
                    let contents = try document.getElementsByClass("notice_list").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("td_subject").select("a").attr("href")
                        let title = try content.getElementsByClass("td_subject").select("a").text()
                        let date = try content.getElementsByClass("td_datetime").text()
                        notice.append(Notice(number: "", title: title, url: noticeUrl, date: date))
                    }
                case "글로벌통상학과", "국제무역학과":
                    let contents = try document.getElementsByClass("t_list hover").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("title").select("a").attr("href")
                        let title = try content.getElementsByClass("title").select("a").text()
                        let c = try content.select("td").array().map{try $0.text()}
                        if c.count >= 4 {   // 공지사항 페이지 범위를 넘어가는 것을 막기 위해
                            notice.append(Notice(number: "", title: title, url: noticeUrl, date: c[3]))
                        }
                    }
                case "금융경제학과":
                    let contents = try document.getElementsByClass("table table-hover").select("tbody").select("tr").array()
                    for content in contents {
                        if pageIdx == 2 {   // 첫번째 페이지를 불러올 때만 번호가 공지인 게시글을 보여줘야 하므로
                            let noticeUrl = try content.getElementsByClass("td-title").select("a").attr("href")
                            let title = try content.getElementsByClass("td-title").select("a").text()
                            let date = try content.getElementsByClass("td-date").text()
                            notice.append(Notice(number: "", title: title, url: noticeUrl, date: date))
                        }
                        else {
                            if !content.hasClass("el-notice") {
                                let noticeUrl = try content.getElementsByClass("td-title").select("a").attr("href")
                                let title = try content.getElementsByClass("td-title").select("a").text()
                                let date = try content.getElementsByClass("td-date").text()
                                notice.append(Notice(number: "", title: title, url: noticeUrl, date: date))
                            }
                        }
                    }
                    // MARK: - 경영대학 fetch title
                case "경영학부":
                    let contents = try document.getElementById("bList01")!.select("li").array()
                    for content in contents {
                        let noticeUrl = try content.select("a").attr("href")
                        let title = try content.select("a").text()
                        let date = (try content.select("span").text().split(separator: " ").first.map{String($0)})!
                        notice.append(Notice(number: "", title: title, url: "http://biz.ssu.ac.kr/\(noticeUrl)", date: date))
                    }
                case "벤처중소기업학과", "회계학과", "금융학부","혁신경영학과":
                    let contents = try document.getElementsByClass("t_list hover").select("tbody").select("tr").array()
                    for content in contents {
                        let noticeUrl = try content.getElementsByClass("title").select("a").attr("href")
                        let title = try content.getElementsByClass("title").select("a").text()
                        let c = try content.select("td").array().map{try $0.text()}
                        if c.count >= 4 {   // 공지사항 페이지 범위를 넘어가는 것을 막기 위해
                            notice.append(Notice(number: "", title: title, url: noticeUrl, date: c[3]))
                        }
                    }
                case "벤처경영학과":
                    let contents = try document.getElementsByClass("card_cont").array()
                    for content in contents {
                        let noticeUrl = try content.select("a").attr("href")
                        let title = try content.select("p").text()
                        let date = try content.select("date_val").text()
                        notice.append(Notice(number: "", title: title, url: noticeUrl, date: date))
                    }


                default:
                    print("제목을 가져올 수 없습니다.")
                }
            } catch let error {
                print(error)
            }
        }
    }
    
    // 내용 가져오기
    func fetchContent(_ url: URL?) {
        if let url = url {
            do {
                let webString = try String(contentsOf: url)
                let document = try SwiftSoup.parse(webString)
                switch selectedMajor {
                    // MARK: - IT대학 fetch content
                case "컴퓨터학부":
                    selectedContent = try document.getElementsByClass("content").html()
                case "소프트웨어학부":
                    selectedContent = try document.getElementsByClass("bo_view_2").html()
                case "글로벌미디어학부":
                    print("미구현")
                case "전자정보공학부":
                    selectedContent = try document.getElementsByClass("con").html()
                case "융합특성화자유전공학부":
                    selectedContent = try document.getElementsByClass("body").html()
                case "미디어경영학과":
                    selectedContent = try document.getElementById("bo_v_atc")!.html()
                case "AI융합학부":
                    selectedContent = try document.getElementsByClass("table").html()
                    // MARK: - 공과대학 fetch content
                case "화학공학과":
                    selectedContent = try document.getElementsByClass("body").html()
                case "유기신소재파이버공학과":
                    print("미구현")
                case "전기공학부":
                    selectedContent = try document.getElementsByClass("body").html()
                case "기계공학부":
                    selectedContent = try document.getElementsByClass("view_con").html()
                case "산업정보시스템공학과":
                    selectedContent = try document.getElementsByClass("td_box").html()
                case "건축학부":
                    selectedContent = try document.getElementsByClass("td_box").html()
                    // MARK: - 인문대학 fetch content
                case "기독교학과", "국어국문학과", "영어영문학과", "독어독문학과", "불어불문학과", "중어중문학과", "일어일문학과", "철학과", "사학과", "문예창작전공", "스포츠학부":
                    selectedContent = try document.getElementsByClass("td_box").html()
                    // MARK: - 자연과학대학 fetch content
                case "수학과", "물리학과", "화학과", "의생명시스템학부":
                    selectedContent = try document.getElementsByClass("td_box").html()
                case "정보통계보험수리학과":
                    selectedContent = try document.getElementsByClass("content").html()
                    // MARK: - 법과대학 fetch content
                case "법학과":
                    print("미구현")
                case "국제법무학과":
                    print("미구현")
                    // MARK: - 사회과학대학 fetch content
                case "사회복지학부", "행정학부", "정치외교학과", "언론홍보학과":
                    selectedContent = try document.getElementsByClass("td_box").html()
                case "정보사회학과":
                    selectedContent = try document.getElementsByClass("view_content").html()
                case "평생교육학과":
                    selectedContent = try document.getElementById("writeContents")!.html()
                    // MARK: - 경제통상대학 fetch content
                case "경제학과":
                    selectedContent = try document.getElementById("bo_v_atc")!.html()
                case "글로벌통상학과", "국제무역학과":
                    selectedContent = try document.getElementsByClass("td_box").html()
                case "금융경제학과":
                    selectedContent = try document.getElementById("post-content")!.html()
                    // MARK: - 경영대학 fetch content
                case "경영학부":
                    selectedContent = try document.getElementById("postContents")!.html()
                case "벤처중소기업학과", "회계학과", "금융학부","혁신경영학과":
                    selectedContent = try document.getElementsByClass("td_box").html()
                case "벤처경영학과":
                    selectedContent = try document.getElementsByClass("td_box").html()

                default:
                    print("내용을 가져올 수 없습니다.")
                }
            } catch let error {
                print(error)
            }
        }
    }
}
