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
  func pollControllerCloseButtonPressed()
}

class PollController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var questionLabel: UILabel!
  
  weak var delegate: PollControllerDelegate?
  
  private var isPollStatistic: Bool! {
    didSet {
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
    let pollCellNib = UINib(nibName: String(describing: PollTableViewCell.self), bundle: Bundle(for: type(of: self)))
    questionLabel.text = poll?.pollQuestion
    tableView.register(pollCellNib, forCellReuseIdentifier: "pollCell")
    tableView.dataSource = self
    tableView.delegate = self
    isPollStatistic = poll?.userAnswer != nil
  }
  
  @objc
  private func handlePollUpdate(_ sender: NSNotification) {
    guard let newPoll = sender.userInfo?["poll"] as? Poll else {
      NotificationCenter.default.removeObserver(self)
      return
    }
    poll = newPoll
    isPollStatistic = poll?.userAnswer != nil
  }
  
  @IBAction func closeButtonPressed(_ sender: UIButton) {
    delegate?.pollControllerCloseButtonPressed()
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
    let cell = tableView.dequeueReusableCell(withIdentifier: "pollCell", for: indexPath) as! PollTableViewCell
    cell.isStatistic = isPollStatistic
    cell.titleLabel.text = poll?.pollAnswers[indexPath.row]
    cell.percentage = poll?.percentForEachAnswer[indexPath.row] ?? 0
    cell.isUserChoise = false
    if let answer = poll?.userAnswer {
      cell.isUserChoise = answer == indexPath.row
    }
    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 56
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard !isPollStatistic else {return}
    poll?.userAnswer = indexPath.row
    isPollStatistic = true
    poll?.saveAnswerWith(index: indexPath.row)
  }
  
}

