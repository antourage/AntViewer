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
  
  @IBOutlet var tableView: UITableView!
  @IBOutlet var questionLabel: UILabel!
  @IBOutlet var sponsoredBanner: CacheImageView!
  @IBOutlet var sponsoredBannerHeight: NSLayoutConstraint!

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
    fetchBanner()
    NotificationCenter.default.addObserver(self, selector: #selector(handlePollUpdate(_:)), name: NSNotification.Name(rawValue: "PollUpdated"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleBannerUpdate), name: NSNotification.Name(rawValue: "SponsoredBannerDidUpdate"), object: nil)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.reloadData()
  }

  private func fetchBanner() {
    guard let banner = SponsoredBanner.current, let url =  URL(string: banner.imageUrl) else {
      print("Error: sponsored image url absent or broken")
      return
    }
    sponsoredBanner.load(url: url, placeholder: nil)
    sponsoredBannerHeight.isActive = false
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

  @objc
  func handleBannerUpdate() {
    guard let banner = SponsoredBanner.current, let url =  URL(string: banner.imageUrl) else {
      print("Error: sponsored image url absent or broken")
      return
    }
    sponsoredBanner.load(url: url, placeholder: nil)
    sponsoredBannerHeight.isActive = false
  }
  
  @IBAction func closeButtonPressed(_ sender: UIButton) {
    delegate?.pollControllerCloseButtonPressed()
  }

  @IBAction func handleTapOnBanner(_ sender: UITapGestureRecognizer) {
    guard let banner = SponsoredBanner.current, let url =  URL(string: banner.externalUrl) else {
      print("Error: sponsored external url absent or broken ")
      return
    }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
    return 50
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard !isPollStatistic else {return}
    poll?.userAnswer = indexPath.row
    isPollStatistic = true
    poll?.saveAnswerWith(index: indexPath.row)
  }
  
}

