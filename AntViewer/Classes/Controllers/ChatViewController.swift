//
//  ChatViewController.swift
//  AntViewer
//
//  Created by Maryan Luchko on 27.05.2020.
//

import UIKit
import AntViewerExt

class ChatViewController: UIViewController {

  @IBOutlet var tableView: UITableView!
  @IBOutlet var newCommentsView: UIView!
  @IBOutlet var newCommentsIcon: UIImageView!
  @IBOutlet var newCommentsLabel: UILabel!

  private var messagesDataSource: [Message] = []
  var vodMessages: [Message] = []
  var videoContent: VideoContent!
  private var alreadyWatchedMessage = 0 {
    didSet {
      updateChatTipView(newMessagesCount: messagesDataSource.count-alreadyWatchedMessage)
    }
  }

  var onTableViewTapped: (()->())?
  var handleTableViewSwipeGesture: (()->())?

  private var shouldUpdateIndexPath = true
  private var chatGradientLayer: CAGradientLayer = {
    let gradient = CAGradientLayer()
    gradient.colors = [UIColor.clear.withAlphaComponent(0).cgColor, UIColor.clear.withAlphaComponent(0.7).cgColor, UIColor.clear.withAlphaComponent(1).cgColor, UIColor.clear.withAlphaComponent(1).cgColor]
    gradient.locations = [0, 0.15, 0.5, 1]
    return gradient
  }()

  override func viewDidLoad() {
      super.viewDidLoad()
    let  cellNib = UINib.init(nibName: "PortraitMessageCell", bundle: Bundle(for: type(of: self)))
    let reuseIdentifire = "portraitCell"
    tableView.register(cellNib, forCellReuseIdentifier: reuseIdentifire)
    tableView.estimatedRowHeight = 50
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0
    tableView.rowHeight = UITableView.automaticDimension
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    if size.width > size.height {
      self.view.layer.mask = chatGradientLayer
      chatGradientLayer.frame = self.view.bounds
    } else {
      chatGradientLayer.removeFromSuperlayer()
    }
    shouldUpdateIndexPath = false

    let lastVisibleIndexPath = tableView.indexPathsForVisibleRows?.sorted().last

    DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
      self.updateContentInsetForTableView(false)
      self.shouldUpdateIndexPath = true
      guard let indexPath = lastVisibleIndexPath else { return }
      self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    chatGradientLayer.frame = self.view.bounds
  }

  deinit {
    print("Chat controller DEINITED")
    if videoContent is VOD {
      StorageManager.shared.saveChat(for: videoContent, value: vodMessages)
    }
  }

  @IBAction func handleNewCommentButtonTapped(_ sender: UITapGestureRecognizer) {
    let latestIndex = messagesDataSource.count - 1
    tableView.scrollToRow(at: IndexPath(row: latestIndex, section: 0), at: .bottom, animated: false)
    alreadyWatchedMessage = messagesDataSource.count
  }

  @IBAction func handleTableViewTapped(_ sender: UITapGestureRecognizer) {
    onTableViewTapped?()
  }

  @IBAction func handleSwipeGesture(_ sender: UISwipeGestureRecognizer) {
    if OrientationUtility.isLandscape {
      handleTableViewSwipeGesture?()
    }
  }

  func insertMessages(_ messages: [Message]) {
    let shouldScroll = tableView.contentOffset.y >= tableView.contentSize.height - tableView.frame.size.height - 20
    let addedIndexes: [Int] = Array(messagesDataSource.count..<messagesDataSource.count+messages.count)
    messagesDataSource += messages
    let indexPaths = addedIndexes.map { IndexPath(row: $0, section: 0) }
    tableView.beginUpdates()
    tableView.insertRows(at: indexPaths, with: .none)
    tableView.endUpdates()
    updateContentInsetForTableView()
    tableView.layoutIfNeeded()
    if shouldScroll {
      alreadyWatchedMessage = messagesDataSource.count
      tableView.scrollToRow(at: IndexPath(row: self.messagesDataSource.count-1, section: 0), at: .bottom, animated: true)
    }
    if tableView.contentSize.height < tableView.bounds.height {
      alreadyWatchedMessage = messagesDataSource.count
    }
    updateChatTipView(newMessagesCount: messagesDataSource.count-alreadyWatchedMessage)
  }

  func deleteMessages(_ messages: [Message]) {
    let arrWithoutUpdates = messagesDataSource
    self.messagesDataSource.removeAll { mess in messages.contains { $0.key == mess.key } }//.remove(at: index)
    let deletedIndexes: [Int] = Array(messagesDataSource.count..<arrWithoutUpdates.count)
    let deletedIndexPaths = deletedIndexes.map { IndexPath(row: $0, section: 0) }
    if alreadyWatchedMessage > messagesDataSource.count {
      alreadyWatchedMessage = messagesDataSource.count
    }
    tableView.beginUpdates()
    tableView.deleteRows(at: deletedIndexPaths, with: .none)
    tableView.endUpdates()
    updateContentInsetForTableView()
  }

  func updateContentInsetForTableView(_ animated: Bool = true) {
    let numRows = tableView(tableView, numberOfRowsInSection: 0)
    var contentInsetHeight = tableView.bounds.size.height
    guard tableView.contentSize.height <= contentInsetHeight else {
      tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//      if currentTableView == portraitTableView, shouldScrollPortraitTable {
//        let lastIndexPath = IndexPath(row: self.messagesDataSource.count - 1, section: 0)
//        if lastIndexPath.row >= 0 {
//          self.currentTableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
//          shouldScrollPortraitTable = false
//        }
//      }
      return
    }
    for i in 0..<numRows {
      let rowRect = tableView.rectForRow(at: IndexPath(item: i, section: 0))
      contentInsetHeight -= rowRect.size.height
      if contentInsetHeight <= 0 {
        contentInsetHeight = 0
      }
    }
    UIView.animate(
      withDuration: animated ? 0.3 : 0,
      delay: 0,
      options: [.curveEaseOut, .beginFromCurrentState],
      animations: {
        self.tableView.contentInset = UIEdgeInsets(top: contentInsetHeight, left: 0, bottom: 0, right: 0)
    },
      completion: nil)
  }

  func updateChatTipView(isNewUser: Bool = false, newMessagesCount: Int = 0) {
     newCommentsIcon.isHidden = false
     newCommentsView.isHidden = false
     newCommentsView.isUserInteractionEnabled = false
     switch (isNewUser, newMessagesCount) {
     case (false, let count) where count >= 1:
      newCommentsLabel.text = String(format: "NewComment".localized(), count)
       newCommentsView.isUserInteractionEnabled = true
     case (false, let count) where count < 1:
       newCommentsView.isHidden = true
       newCommentsView.isUserInteractionEnabled = false
     case (true, _):
      fallthrough
//       newCommentsIcon.isHidden = true
//       if messagesDataSource.isEmpty, let displayName = User.current?.displayName {
//         let attributedString = NSMutableAttributedString()
//         let displayName = NSAttributedString(string: displayName, attributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold)])
//         attributedString.append(displayName)
//         let joinedString = NSAttributedString(string: " JOINED", attributes: [.font: UIFont.systemFont(ofSize: 9, weight: .regular)])
//         attributedString.append(joinedString)
//         newCommentsLabel.attributedText = attributedString
//       }
     default:
       break
     }
   }

  func reloadData() {
    tableView.reloadData()
  }

  func handleVODsChat(forTime time: Int) {
    let currentTime = Int(videoContent.date.timeIntervalSince1970) + time
    let filteredArr = vodMessages.filter({$0.timestamp <= currentTime })
    let dif = filteredArr.count - messagesDataSource.count
    guard dif != 0 else { return }
    var difArr: [Message]
    difArr =  dif > 0 ?
      filteredArr.filter { mes in !messagesDataSource.contains(where: { $0.key == mes.key })} :
      messagesDataSource.filter { mes in !filteredArr.contains(where: { $0.key == mes.key })}

    dif > 0 ? self.insertMessages(difArr) : self.deleteMessages(difArr)
  }

  func scrollToBottom() {
    let lastIndexPath = IndexPath(row: self.messagesDataSource.count - 1, section: 0)
    if lastIndexPath.row >= 0 {
      tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
    }
  }
}


extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messagesDataSource.count
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "portraitCell", for: indexPath) as! PortraitMessageCell
    let message = messagesDataSource[indexPath.row]
    let isCurrentUser = Int(message.userID) == User.current?.id
    cell.messageLabel.text = message.text
    let userName = isCurrentUser ? User.current?.displayName ?? message.nickname : message.nickname
    let messageDate = Date(timeIntervalSince1970: TimeInterval(message.timestamp))
    let time = Calendar.current.dateComponents([.second], from: videoContent.date, to: messageDate).second ?? 0
    cell.messageInfoLabel.text = String(format: "%@ at %@".localized(), userName, time.durationString())
    return cell
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard shouldUpdateIndexPath, tableView.contentSize.height > tableView.bounds.height else { return }
    alreadyWatchedMessage = max(indexPath.row+1, alreadyWatchedMessage)
  }
}
