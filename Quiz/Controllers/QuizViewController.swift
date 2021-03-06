//
//  QuizViewController.swift
//  Quiz
//
//  Created by five on 10/05/2020.
//  Copyright © 2020 Ivana Mesic. All rights reserved.
//

import UIKit
import CoreData

class QuizViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBAction func FetchButtonClick(_ sender: UIButton) {
        if sender.tag != 0 {return}
        self.reachability = try! Reachability.init()
        if reachability?.connection != Reachability.Connection.unavailable {
            fetchQuizzesOnline()
        } else {
            let quizzes: Array<Quiz> = PersistenceService.getQuizzesCD()
            fillElementsWithData(quizzes: quizzes)
        }
    }
    @IBOutlet weak var QuizTableView: UITableView!
    @IBOutlet weak var wrongFetchLabel: UILabel!
    @IBOutlet weak var funFactLabel: UILabel!

    @objc func SignOutButton(_ sender: UIButton) {
        _ = UserDefaults.standard
        //userDefaults.removeObject(forKey: "token")
        //userDefaults.removeObject(forKey: "user_id")
        self.navigationController?.pushViewController(SearchController(), animated: false)
        
    }
    
    var allQuizzes: Array<Array<Quiz>> = []
    var refresher: UIRefreshControl!
    var groupedByCategories: [QuizCategory: Array<Quiz>] = [:]
    var categories: [Int:QuizCategory] = [:]
    
    var reachability: Reachability?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.wrongFetchLabel.isHidden = true
        self.QuizTableView.delegate = self
        self.QuizTableView.dataSource = self
        
        QuizTableView.register(UINib(nibName: "QuizTableViewCell", bundle: nil), forCellReuseIdentifier: "QuizTableViewCell")

    }
    
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           navigationController?.navigationBar.isTranslucent = true
           navigationController?.navigationBar.barTintColor = .clear
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return allQuizzes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuizTableViewCell", for: indexPath) as? QuizTableViewCell ?? QuizTableViewCell()
        
        let thisCell: Quiz = allQuizzes[indexPath.section][indexPath.row]
        
        self.wrongFetchLabel.isHidden = true
        
        cell.quizCellTitle.text = thisCell.title
        var lvl = "";
        for _ in 1...thisCell.level{
            lvl += "*"
        }
        cell.quizCellLevel.text = lvl
        cell.quizCellDescription.text=thisCell.description
        self.fetchQuizImage(pickedQuiz: thisCell, imageView: cell.quizCellImage)
        
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allQuizzes[section].count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oneQuizController = OneQuizController()
        let quiz = allQuizzes[indexPath.section][indexPath.row]
        oneQuizController.quiz = quiz
        self.navigationController?.pushViewController(oneQuizController, animated: false)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 18))
        let label = UILabel(frame: CGRect(x: 10, y: 5, width: tableView.frame.size.width, height: 18))
        label.text = categories[section]?.text
        view.backgroundColor = Constants.backgroundColors[categories[section]!]
        view.addSubview(label)
        return view
    }
    
    
    func fetchQuizzesOnline() {
            
        let quizService = QuizService()
            
        quizService.fetchQuiz(urlString: Constants.fetchQuizesURL) { (quizArray) in
                DispatchQueue.main.async {
                    if let quizArray = quizArray {
                        PersistenceService.saveQuizzes(quizzes: quizArray)
                        let quizzes: Array<Quiz> = PersistenceService.getQuizzesCD()
                        self.fillElementsWithData(quizzes: quizzes)
                        
                    } else{
                        self.wrongFetchLabel.isHidden = false
                    }
                }
            }
    }
    
    func fillElementsWithData(quizzes: [Quiz]){
        self.wrongFetchLabel.isHidden = true
        var collection: Array<String> = []
        var tempDict: [QuizCategory:Array<Quiz>] = [:]
        for quiz in quizzes{
            for question in quiz.questions{
                collection.append(question.questionText)
            }
            var res = tempDict[quiz.category]
            if res==nil{
                let newar = [quiz]
                tempDict[quiz.category]=newar
            } else {
                res?.append(quiz)
                tempDict[quiz.category]=res
            }
        }
        
        let number = collection.filter({e in e.contains("NBA")}).count
        self.groupedByCategories=tempDict
        self.allQuizzes.removeAll()
        var counter = 0
        for (cat, ar) in tempDict{
            self.allQuizzes.append(ar)
            self.categories[counter]=cat
            counter += 1
        }
        
        self.funFactLabel.text="FUN FACT: The word NBA is in questions \(number) times"
        self.QuizTableView.reloadData()
    }
        
    func fetchQuizImage(pickedQuiz: Quiz, imageView: UIImageView){

        let quizService = QuizService()
        quizService.fetchImage(quiz: pickedQuiz) { (fetchedImage) in
                DispatchQueue.main.async {
                    imageView.image = fetchedImage
                }
        }
    }

}
