//
//  PollViewController.swift
//  controllers fot kolya
//
//  Created by Maryan Luchko on 12/13/18.
//  Copyright © 2018 Maryan Luchko. All rights reserved.
//

import UIKit
import AntViewerExt

protocol PollControllerDelegate: class {
  func closeButtonPressed()
}

let colors = ["a_poll1LightOrange", "a_poll2Terracotta", "a_poll3Blue", "a_poll4Green"]

class PollController: UIViewController {
  
  @IBOutlet weak var heightBottomView: NSLayoutConstraint!
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var bottomView: UIView!
  @IBOutlet weak var questionLabel: UILabel!
  @IBOutlet weak var totalAnswersLabel: UILabel! {
    didSet {
      let count = poll?.answersCount.reduce(0, +) ?? 0
      totalAnswersLabel.text = "\(count)"
    }
  }
  
  weak var delegate: PollControllerDelegate?
  
  private var isPollStatistic: Bool! {
    didSet {
      heightBottomView.constant = isPollStatistic ? 61 : 0
      bottomView.isHidden = !isPollStatistic
      tableView.reloadData()
    }
  }
  
  var poll: Poll?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    NotificationCenter.default.addObserver(self, selector: #selector(handlePollUpdate(_:)), name: NSNotification.Name(rawValue: "PollUpdated"), object: nil)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.reloadData()
  }

  private func setupUI() {
    let nibStatistic = UINib(nibName: "PollStatisticCell", bundle: Bundle(for: type(of: self)))
    let nib = UINib(nibName: "PollCell", bundle: Bundle(for: type(of: self)))
    questionLabel.text = poll?.pollQuestion
    tableView.register(nibStatistic, forCellReuseIdentifier: "pollStatisticCell")
    tableView.register(nib, forCellReuseIdentifier: "pollCell")
    tableView.dataSource = self
    tableView.delegate = self
    isPollStatistic = poll?.answeredByUser == true
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 70
}
  
  @objc
  private func handlePollUpdate(_ sender: NSNotification) {
    guard let newPoll = sender.userInfo?["poll"] as? Poll else {
      NotificationCenter.default.removeObserver(self)
      return
    }
    poll = newPoll
    let count = poll?.answersCount.reduce(0, +) ?? 0
    totalAnswersLabel.text = "\(count)"
    isPollStatistic = poll?.answeredByUser == true
  }
  
  @IBAction func closeButtonPressed(_ sender: UIButton) {
    delegate?.closeButtonPressed()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
}

extension PollController: UITableViewDelegate, UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return poll?.pollAnswers.count ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if isPollStatistic {
      let cell = tableView.dequeueReusableCell(withIdentifier: "pollStatisticCell", for: indexPath) as! PollStatisticCell
      cell.pollChoiceLabel.text = poll?.pollAnswers[indexPath.row]
      cell.progresView.backgroundColor = UIColor.color(colors[indexPath.row])
      let progress = tableView.bounds.width * CGFloat(poll?.percentForEachAnswer[indexPath.row] ?? 0) / 100
      cell.progressLabel.text = "\(poll?.percentForEachAnswer[indexPath.row] ?? 0) %"
      cell.progress.constant = progress

      return cell
    }
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "pollCell", for: indexPath) as! PollCell
    cell.pollChoiceLabel.text = poll?.pollAnswers[indexPath.row]
    cell.backgroundCellView.backgroundColor = UIColor.color(colors[indexPath.row])
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard !isPollStatistic else {return}
    poll?.answeredByUser = true
    isPollStatistic = true
    poll?.saveAnswerWith(index: indexPath.row)
  }
  
}

