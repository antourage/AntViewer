//
//  PlayerController.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/5/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import AVKit
import AntViewerExt

private let maxTextLength = 250
private let maxUserNameLength = 50

class PlayerController: UIViewController {
  
  private var player: Player!
  
  @IBOutlet weak var portraitMessageBottomSpace: NSLayoutConstraint!
  @IBOutlet var landscapeMessageBottomSpace: NSLayoutConstraint!
  @IBOutlet weak var messageHeight: NSLayoutConstraint!
  @IBOutlet private var liveLabel: UILabel!
  @IBOutlet weak var liveLabelWidth: NSLayoutConstraint! {
    didSet {
      liveLabelWidth.constant = videoContent is VOD ? 0 : 36
    }
  }

  //MARK: - chat field staff
  @IBOutlet weak var bottomContainerView: UIView!
  @IBOutlet weak var bottomContainerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var chatTextView: IQTextView! {
    didSet {
      chatTextView.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
      chatTextView.placeholder = "Chat disabled"
    }
  }
  @IBOutlet weak var chatTextViewHolderView: UIView! {
    didSet {
      chatTextViewHolderView.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor

    }
  }
  @IBOutlet weak var chatTextViewHolderViewLeading: NSLayoutConstraint!
  @IBOutlet var chatTextViewTrailing: NSLayoutConstraint!
  @IBOutlet weak var bottomContainerLeading: NSLayoutConstraint!
  @IBOutlet weak var bottomContainerTrailing: NSLayoutConstraint!
  @IBOutlet weak var bottomContainerLandscapeTop: NSLayoutConstraint!
  fileprivate var isBottomContainerHidedByUser = false
  private var bottomContainerGradientLayer: CAGradientLayer = {
    let gradient = CAGradientLayer()
    gradient.colors = [UIColor.gradientDark.withAlphaComponent(0).cgColor,
                       UIColor.gradientDark.withAlphaComponent(0).cgColor,
                       UIColor.gradientDark.withAlphaComponent(0.5).cgColor,
                       UIColor.gradientDark.withAlphaComponent(0.6).cgColor
                      ]
    gradient.locations = [0, 0.33, 0.44, 1]
    return gradient
  }()
  var shouldScrollPortraitTable = false {
    didSet {
      if shouldScrollPortraitTable {
        alreadyWatchedMessage = messagesDataSource.count
      }
    }
  }
  //MARK:  -

  @IBOutlet weak var portraitTableView: UITableView! {
    didSet {
      setupChatTableView(portraitTableView)
      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHideKeyboardGesture(_:)))
      portraitTableView.addGestureRecognizer(tapGesture)
    }
  }
  
  @IBOutlet weak var landscapeTableViewContainer: UIView! {
    didSet {
      chatGradientLayer.frame = landscapeTableViewContainer.bounds
      landscapeTableViewContainer.layer.mask = chatGradientLayer
    }
  }
  @IBOutlet weak var landscapeTableViewContainerLeading: NSLayoutConstraint!
  @IBOutlet weak var landscapeTableView: UITableView! {
    didSet {
      setupChatTableView(landscapeTableView)
    }
  }
  @IBOutlet weak var sendButton: UIButton!
  @IBOutlet weak var videoContainerView: AVPlayerView! {
    didSet {
      videoContainerView.contentMode = .scaleAspectFit
      videoContainerView.load(url: URL(string: videoContent.thumbnailUrl), placeholder: nil)
    }
  }

  //MARK: - video controls
  @IBOutlet weak var videoControlsView: UIView!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var previousButton: UIButton!
  @IBOutlet var cancelButton: UIButton!
  @IBOutlet var fullScreenButtons: [UIButton]!
  @IBOutlet var thanksForWatchingLabel: UILabel!
  private var isAutoplayMode = false
  private lazy var backgroundShape = CAShapeLayer()
  private lazy var progressShape = CAShapeLayer()
  lazy var autoplayDebouncer = Debouncer(delay: 4.5)
  //MARK: -
  
  
  @IBOutlet weak var pollContainerView: UIView!
  @IBOutlet weak var durationView: UIView! {
    didSet {
      durationView.isHidden = !(videoContent is VOD)
    }
  }
  
  var activeSpendTime: Double = 0 {
    didSet {
      Statistic.save(action: .close(span: Int(activeSpendTime)), for: videoContent)
    }
  }
  
  var dataSource: DataSource!
  fileprivate var streamTimer: Timer?
  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
    return OrientationUtility.isLandscape ? .top : .bottom
  }
  

  @IBOutlet weak var editProfileButton: UIButton! {
    didSet {
      editProfileButton.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
    }
  }
  @IBOutlet weak var shareButton: UIButton! {
     didSet {
       shareButton.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
     }
   }
  
  @IBOutlet weak var editProfileContainerView: UIView!
  
  @IBOutlet weak var durationLabel: UILabel! {
    didSet {
      if let video = videoContent as? VOD {
        durationLabel.text = video.duration
      }
    }
  }

  @IBOutlet weak var landscapeBroadcasterProfileImage: CacheImageView! {
    didSet {
      landscapeBroadcasterProfileImage.load(url: URL(string: videoContent.broadcasterPicUrl), placeholder: UIImage.image("avaPic"))
    }
  }
  
  @IBOutlet weak var startLabel: UILabel!

  @IBOutlet weak var viewersCountLabel: UILabel! {
    didSet {
      viewersCountLabel.text = "\(videoContent.viewsCount)"
    }
  }

  @IBOutlet var viewersCountView: UIView!

  @IBOutlet weak var portraitSeekSlider: CustomSlide! {
    didSet {
      if let video = videoContent as? VOD {
        portraitSeekSlider.isHidden = false
        portraitSeekSlider.maximumValue = Float(video.duration.duration())
        portraitSeekSlider.setThumbImage(UIImage.image("thumb"), for: .normal)
        portraitSeekSlider.tintColor = UIColor.color("a_pink")//.clear
        portraitSeekSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
      }
    }
  }
  
  @IBOutlet weak var landscapeSeekSlider: UISlider! {
    didSet {
      if let video = videoContent as? VOD {
        landscapeSeekSlider.maximumValue = Float(video.duration.duration())
        landscapeSeekSlider.setThumbImage(UIImage.image("thumb"), for: .normal)
        landscapeSeekSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
      }
    }
  }
  
  @IBOutlet weak var seekLabel: UILabel! 

  //MARK: - new poll banner staff
  @IBOutlet private var pollBannerAspectRatio: NSLayoutConstraint!
  @IBOutlet private var pollBannerPortraitLeading: NSLayoutConstraint!
  @IBOutlet private var pollTitleLabel: UILabel!
  @IBOutlet private var pollBannerView: UIView!
  @IBOutlet private var pollBannerIcon: UIImageView!
  var shouldShowExpandedBanner = true
  //MARK: -

  //MARK: - edit profile staff
  @IBOutlet private var editProfileContainerPortraitBottom: NSLayoutConstraint!
  @IBOutlet private var editProfileContainerLandscapeBottom: NSLayoutConstraint!
  private var pollAnswersFromLastView = 0
  private var shouldShowPollBadge = false
  private var isFirstTimeBanerShown = true
  //MARK: -

  //MARK: - chat tip staff
  @IBOutlet private var chatTipView: UIView!
  @IBOutlet private var chatTipLabel: UILabel!
  @IBOutlet private var chatTipIcon: UIImageView!
  var alreadyWatchedMessage = 0 {
    didSet {
      updateChatTipView(newMessagesCount: messagesDataSource.count-alreadyWatchedMessage)
    }
  }
  var shouldUpdateIndexPath = true
  //MARK: -

  //MARK: - player header staff
  @IBOutlet private var circleImageView: UIImageView! {
    didSet {
      userImageView.load(url: URL(string: videoContent.broadcasterPicUrl), placeholder: UIImage.image("avaPic"))
    }
  }
  @IBOutlet private var titleLabel: UILabel! {
    didSet {
      titleLabel.text = videoContent.title
    }
  }
  @IBOutlet private var subtitleLabel: UILabel! {
    didSet{
      subtitleLabel.text = String(format: "%@ • %@", videoContent.creatorNickname, videoContent.date.timeAgo())
      updateContentTimeAgo()
    }
  }
  @IBOutlet var landscapeCircleImageView: UIImageView! {
    didSet {
      landscapeUserImageView.load(url: URL(string: videoContent.broadcasterPicUrl), placeholder: UIImage.image("avaPic"))
    }
  }
  @IBOutlet var landscapeTitleLabel: UILabel! {
    didSet {
      landscapeTitleLabel.text = videoContent.title
    }
  }
  @IBOutlet var landscapeSubtitleLabel: UILabel! {
    didSet{
      landscapeSubtitleLabel.text = String(format: "%@ • %@", videoContent.creatorNickname, videoContent.date.timeAgo())
    }
  }
  @IBOutlet var liveToLandscapeInfoTop: NSLayoutConstraint!
  @IBOutlet var headerHeightConstraint: NSLayoutConstraint!
  
  lazy var userImageView: CacheImageView = {
    let imageView = CacheImageView()
    circleImageView.addSubview(imageView)
    fixImageView(imageView, in: circleImageView)
    return imageView
  }()

  lazy var landscapeUserImageView: CacheImageView = {
    let imageView = CacheImageView()
    landscapeCircleImageView.addSubview(imageView)
    fixImageView(imageView, in: landscapeCircleImageView)
    return imageView
  }()
  var timeAgoWorkItem: DispatchWorkItem?
  //MARK: -

  fileprivate var currentOrientation: UIInterfaceOrientation! {
    didSet {
      if currentOrientation != oldValue {
        if videoContent is VOD {
          seekTo = nil
        }
        adjustHeightForTextView(chatTextView)
        if OrientationUtility.isLandscape {
          let leftInset = view.safeAreaInsets.left
          if leftInset > 0 {
            var leading: CGFloat = .zero
            var trailing: CGFloat = .zero
            if chatTextView.isFirstResponder {
              trailing = OrientationUtility.currentOrientatin == .landscapeLeft ? 30 : 0
              leading = OrientationUtility.currentOrientatin == .landscapeLeft ? 0 : 30
            }
            bottomContainerTrailing.constant = trailing
            bottomContainerLeading.constant = leading
          }
          bottomContainerView.isHidden = !(videoControlsView.isHidden && pollContainerView.isHidden)
          landscapeTableViewContainer.isHidden = !(videoControlsView.isHidden && pollContainerView.isHidden)
          if !isBottomContainerHidedByUser {
            bottomContainerLandscapeTop.isActive = !isChatEnabled
            isChatEnabled ? bottomContainerView.layer.insertSublayer(bottomContainerGradientLayer, at: 0) :
                            bottomContainerGradientLayer.removeFromSuperlayer()
          } else {
            bottomContainerLandscapeTop.isActive = true
            chatTextView.resignFirstResponder()
            bottomContainerGradientLayer.removeFromSuperlayer()
          }
          currentTableView.frame.origin = CGPoint(x: !isBottomContainerHidedByUser ? 0 : -self.currentTableView.frame.width, y: 0)
          liveToLandscapeInfoTop.isActive = !videoControlsView.isHidden
          if videoContent is Live {
            landscapeSeekSlider.removeFromSuperview()
          }
        } else {
          liveLabel.isHidden = false
          viewersCountView.isHidden = false
          shouldUpdateIndexPath = true
          bottomContainerLeading.constant = .zero
          bottomContainerTrailing.constant = .zero
          bottomContainerView.isHidden = false
          bottomContainerGradientLayer.removeFromSuperlayer()
          alreadyWatchedMessage += 0
        }
        updatePollBannerVisibility()
        if isAutoplayMode {
          print("PlayButton: \(playButton.bounds)")
          adjustCircleLayersPath()
        }
        if shouldShowExpandedBanner, OrientationUtility.isPortrait, activePoll?.userAnswer == nil {
          expandPollBanner(enableAutoHide: false)
        }
        self.updateContentInsetForTableView(self.currentTableView)
        shouldUpdateIndexPath = true
      }
    }
  }

  private func updatePollBannerVisibility() {
    if OrientationUtility.isLandscape {
      if !videoControlsView.isHidden {
        pollBannerView.isHidden = true
      } else {
        pollBannerView.isHidden = activePoll == nil
      }
    } else {
      pollBannerView.isHidden = activePoll == nil
    }
  }

  lazy var formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()
  fileprivate var pollManager: PollManager?
  fileprivate var isShouldShowPollAnswers = false
  fileprivate var pollBannerDebouncer = Debouncer(delay: 6)
  fileprivate var activePoll:  Poll? {
    didSet {
      NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "PollUpdated"), object: nil, userInfo: ["poll" : activePoll ?? 0])
      guard let poll = activePoll else {
        pollBannerDebouncer.call {}
        self.isShouldShowPollAnswers = false
        self.shouldShowExpandedBanner = true
        self.isFirstTimeBanerShown = true
        self.pollControllerCloseButtonPressed()
        self.collapsePollBanner()
        updatePollBannerVisibility()
        self.pollBannerIcon.hideBadge()
        self.updateContentInsetForTableView(self.portraitTableView)
        return
      }

      poll.onUpdate = { [weak self] in
        guard let `self` = self, self.activePoll != nil else { return }
        if self.pollBannerView.isHidden {
          if OrientationUtility.isPortrait {
            poll.userAnswer != nil ? self.collapsePollBanner(animated: false) : self.expandPollBanner()
          } else {
            self.collapsePollBanner()
          }
          self.pollBannerView.isHidden = false
          self.pollTitleLabel.text = poll.pollQuestion
        }

        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "PollUpdated"), object: nil, userInfo: ["poll" : self.activePoll ?? 0])
        if self.activePoll?.userAnswer != nil, self.pollContainerView.isHidden, self.shouldShowPollBadge {
          let count = self.activePoll?.answersCount.reduce(0, +) ?? 0
          let dif = count - self.pollAnswersFromLastView - 1
          if dif > 0 {
            self.pollBannerIcon.addBadge(title: String(format: "%d", dif), belowView: self.pollContainerView)
          }
        }
      }
    }
  }

  fileprivate var isKeyboardShown = false
  
  private var chatGradientLayer: CAGradientLayer = {
    let gradient = CAGradientLayer()
    gradient.colors = [UIColor.clear.withAlphaComponent(0).cgColor, UIColor.clear.withAlphaComponent(0.7).cgColor, UIColor.clear.withAlphaComponent(1).cgColor, UIColor.clear.withAlphaComponent(1).cgColor]
    gradient.locations = [0, 0.15, 0.5, 1]
    return gradient
  }()
  
  private var isChatEnabled = false {
    didSet {
      editProfileButton.isHidden = !isChatEnabled
      sendButton.isEnabled = isChatEnabled
      chatTextView.isEditable = isChatEnabled
      chatTextView.placeholder = isChatEnabled ? "Chat" : "Chat disabled"
      bottomContainerLandscapeTop.isActive = !isChatEnabled
      view.layoutIfNeeded()
      if !isChatEnabled {
        chatTextView.text = ""
      }
    }
  }
  
  private var chat: Chat? {
    didSet {
      chat?.onAdd = { [weak self] message in
        self?.videoContent is VOD ? self?.vodMessages?.append(message) : self?.insertMessage(message)
      }
      chat?.onRemove = { [weak self] message in
        self?.removeMessage(message)
      }
      chat?.onStateChange = { [weak self] isActive in
        if !(self?.videoContent is VOD) {
          self?.isChatEnabled = isActive
        } else {
          self?.isChatEnabled = false
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
        if self?.messagesDataSource.isEmpty == false {
          let lastIndexPath = IndexPath(row: self!.messagesDataSource.count - 1, section: 0)
          if lastIndexPath.row >= 0 {
            self?.currentTableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
          }
        }
      }
    }
  }
  
  var videoContent: VideoContent!
  fileprivate var isVideoEnd = false
  fileprivate var swiftMessage: SwiftMessage?
  fileprivate var isPlayerError = false
  
  fileprivate var messagesDataSource = [Message]()
  fileprivate var pollController: PollController?
  fileprivate var currentTableView: UITableView {
    return OrientationUtility.isPortrait ? portraitTableView : landscapeTableView
  }
  
  fileprivate var isControlsEnabled = false
  fileprivate var controlsDebouncer = Debouncer(delay: 3)
  fileprivate var controlsAppearingDebouncer = Debouncer(delay: 0.4)
  fileprivate var seekByTapDebouncer = Debouncer(delay: 0.7)
  
  //MARK: For vods
  fileprivate var vodMessages: [Message]? = []
  fileprivate var chatFieldLeading: CGFloat! {
    didSet {
      chatFieldLeadingChanged?(chatFieldLeading)
    }
  }
  var chatFieldLeadingChanged: ((CGFloat) -> ())?
  private var timeOfLastTap: Date?
  fileprivate var seekToByTapping: Int?
  fileprivate var isSeekByTappingMode = false
  fileprivate var seekPaddingView: SeekPaddingView?
  fileprivate var isPlayerControlsHidden: Bool = true {
    didSet {
      setPlayerControlsHidden(isPlayerControlsHidden)
    }
  }
  
  
  fileprivate var seekTo: Int? {
    didSet {
      if seekTo == nil, let time = oldValue {
        player.player.rate = 0
        self.isVideoEnd = false
        player.seek(to: CMTime(seconds: Double(time), preferredTimescale: 1), completionHandler: { [weak self] (value) in
          self?.player.isPlayerPaused ?? false ? self?.player.pause() : self?.player.play()
          
          if self?.isSeekByTappingMode ?? true {
            self?.isSeekByTappingMode = false
          }
          
        })
        handleVODsChat(forTime: time)
        if messagesDataSource.count > 0 {
          currentTableView.scrollToRow(at: IndexPath(row: messagesDataSource.count - 1, section: 0), at: .bottom, animated: true)
          alreadyWatchedMessage = messagesDataSource.count
        }
        controlsDebouncer.call { [weak self] in
          if self?.player.isPlayerPaused == false {
            if OrientationUtility.isLandscape && self?.seekTo != nil {
              return
            }
            self?.isPlayerControlsHidden = true
          }
        }
      }
    }
  }
  
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return .lightContent
  }
  
  override var prefersStatusBarHidden: Bool {
    let window = UIApplication.shared.keyWindow
    let bottomPadding = window?.safeAreaInsets.bottom
    return bottomPadding == 0
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    swiftMessage = SwiftMessage(presentingController: self)
    previousButton.isExclusiveTouch = true
    nextButton.isExclusiveTouch = true
    //FIXME:
    OrientationUtility.rotateToOrientation(OrientationUtility.currentOrientatin)
    currentOrientation = OrientationUtility.currentOrientatin
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
    
    isChatEnabled = false
    
    Statistic.send(action: .open, for: videoContent)
    dataSource.pauseUpdatingStreams()
    if videoContent is Live {

      pollManager = PollManager(streamId: videoContent.id)
      pollManager?.observePolls(completion: { [weak self] (poll) in
        self?.activePoll = poll
      })
      streamTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] (myTimer) in
        guard let `self` = self else {
          myTimer.invalidate()
          return
        }
        self.dataSource.getViewers(for: self.videoContent.id) { (result) in
          switch result {
          case .success(let count):
            self.viewersCountLabel.text = "\(count)"
          case .failure(let error):
            print(error.localizedDescription)
          }
        }
      })
      
    }
    self.chat = Chat(streamID: videoContent.id)

    var token: NSObjectProtocol?
    token = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] (notification) in
      guard let `self` = self else {
        NotificationCenter.default.removeObserver(token!)
        return
      }
      self.currentOrientation = OrientationUtility.currentOrientatin
      
    }
    startPlayer()
    adjustHeightForTextView(chatTextView)
  }

  func updateChatTipView(isNewUser: Bool = false, newMessagesCount: Int = 0) {
    chatTipIcon.isHidden = false
    chatTipView.isHidden = false
    chatTipView.isUserInteractionEnabled = false
    switch (isNewUser, newMessagesCount) {
    case (false, let count) where count >= 1:
      chatTipLabel.text = String(format: "%d NEW COMMENTS", count)
      chatTipView.isUserInteractionEnabled = true
    case (false, let count) where count < 1:
      chatTipView.isHidden = true
      chatTipView.isUserInteractionEnabled = false
    case (true, _):
      chatTipIcon.isHidden = true
      if messagesDataSource.isEmpty, let displayName = User.current?.displayName {
        let attributedString = NSMutableAttributedString()
        let displayName = NSAttributedString(string: displayName, attributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold)])
        attributedString.append(displayName)
        let joinedString = NSAttributedString(string: " JOINED", attributes: [.font: UIFont.systemFont(ofSize: 9, weight: .regular)])
        attributedString.append(joinedString)
        chatTipLabel.attributedText = attributedString
      }
    default:
      break
    }
  }

  func collapsePollBanner(animated: Bool = true) {
    pollBannerPortraitLeading.isActive = false
    pollBannerAspectRatio.isActive = true
    UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
      self.view.layoutIfNeeded()
    })
  }

  func expandPollBanner(enableAutoHide: Bool = true) {
    pollBannerAspectRatio.isActive = false
    if OrientationUtility.currentOrientatin.isPortrait {
      pollBannerPortraitLeading.isActive = true
    }
    UIView.animate(withDuration: 0.3, animations: {
      self.view.layoutIfNeeded()
    })
    guard isFirstTimeBanerShown else { return }
    isFirstTimeBanerShown = false
    pollBannerDebouncer.call { [weak self] in
      self?.shouldShowExpandedBanner = false
      self?.collapsePollBanner()
    }
  }

  func collapseChatTextView() {
    chatTextViewHolderViewLeading.isActive = false
    chatTextViewTrailing.isActive = true
    bottomContainerLeading.constant = .zero
    bottomContainerTrailing.constant = .zero
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }

  func expandChatTextView() {
    chatTextViewHolderViewLeading.isActive = true
    chatTextViewTrailing.isActive = false
    if view.safeAreaInsets.left > 0, OrientationUtility.isLandscape {
      let leading: CGFloat = OrientationUtility.currentOrientatin == .landscapeLeft ? 0 : 30
      let trailing: CGFloat = OrientationUtility.currentOrientatin == .landscapeLeft ? 30 : 0
      bottomContainerTrailing.constant = trailing
      bottomContainerLeading.constant = leading
    }
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }

  func updateContentTimeAgo() {
    guard videoContent.date <= Date() else {
      timeAgoWorkItem?.cancel()
      timeAgoWorkItem = nil
      return
    }
    let components = Calendar.current.dateComponents([.hour], from: videoContent.date, to: Date())
    timeAgoWorkItem?.cancel()
    timeAgoWorkItem = nil
    timeAgoWorkItem = DispatchWorkItem { [weak self] in
      guard let `self` = self else { return }
      let text = String(format: "%@ • %@", self.videoContent.creatorNickname, self.videoContent.date.timeAgo())
      self.subtitleLabel.text = text
      self.landscapeSubtitleLabel.text = text
      self.updateContentTimeAgo()
    }
    if let hours = components.hour,
      let workItem = timeAgoWorkItem {
      let delay: Double = hours > 0 ? 3600 : 60
      DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
  }

  private func fixImageView(_ imageView: CacheImageView, in parentView: UIView) {
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.centerXAnchor.constraint(equalToSystemSpacingAfter: parentView.centerXAnchor, multiplier: 1).isActive = true
    imageView.centerYAnchor.constraint(equalTo: parentView.centerYAnchor).isActive = true
    imageView.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: 0.8).isActive = true
    imageView.heightAnchor.constraint(equalTo: parentView.heightAnchor, multiplier: 0.8).isActive = true
    imageView.layer.masksToBounds = true
  }

  @objc
  func handleTouches(sender: UITapGestureRecognizer) {
    let point = sender.location(in: view)
    let isTouchOnTableView = portraitTableView.frame.contains(point)
    if isTouchOnTableView {
      view.endEditing(true)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    adjustVideoControlsButtons()
    landscapeTableViewContainer.addObserver(self, forKeyPath: #keyPath(UIView.bounds), options: [.new], context: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundHandler), name: UIApplication.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    UIApplication.shared.isIdleTimerDisabled = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self)
    landscapeTableViewContainer.removeObserver(self, forKeyPath: #keyPath(UIView.bounds))
    view.endEditing(true)
    UIApplication.shared.isIdleTimerDisabled = false
    if let vod = videoContent as? VOD {
      let seconds = player.currentTime
      vod.isNew = false
      vod.stopTime = Int(seconds.isNaN ? 0 : seconds).durationString()
    }
    dataSource.startUpdatingStreams()
    streamTimer?.invalidate()
  }
  
  deinit {
    print("Player DEINITED")
    pollManager?.removeFirObserver()
    Statistic.send(action: .close(span: Int(activeSpendTime)), for: videoContent)
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    shouldUpdateIndexPath = false
    chatTextView.resignFirstResponder()
    chatTextView.text.removeAll()
    if size.width > size.height {
      self.landscapeTableView.reloadData()
    } else {
      self.portraitTableView.reloadData()
    }
    var lastIndexPath = IndexPath(row: self.messagesDataSource.count - 1, section: 0)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      lastIndexPath = IndexPath(row: self.messagesDataSource.count - 1, section: 0)
      if lastIndexPath.row >= 0 {
        self.landscapeTableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
      }
      self.updateContentInsetForTableView(self.currentTableView)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if OrientationUtility.isLandscape {
      updateBottomContainerGradientFrame()
    }
    userImageView.layer.cornerRadius = userImageView.bounds.width/2
    landscapeUserImageView.layer.cornerRadius = landscapeUserImageView.bounds.width/2
    updateContentInsetForTableView(currentTableView)
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if (keyPath == #keyPath(UIView.bounds)) {
      if let tableViewContainerBounds = landscapeTableView.superview?.bounds {
        chatGradientLayer.frame = tableViewContainerBounds
      }
      return
    }
    super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
  }


  private func handleVODsChat(forTime time: Int) {
    let messagesAfterStream = isVideoEnd ? 600 : 0
    let currentTime = Int(videoContent.date.timeIntervalSince1970) + time + messagesAfterStream
    guard let vodMessages = self.vodMessages else { return }
    let filteredArr = vodMessages.filter({$0.timestamp <= currentTime })
    let dif = filteredArr.count - messagesDataSource.count
    guard dif != 0 else { return }
    var difArr: [Message]
    difArr =  dif > 0 ?
      filteredArr.filter { mes in !messagesDataSource.contains(where: { $0.key == mes.key })} :
      messagesDataSource.filter { mes in !filteredArr.contains(where: { $0.key == mes.key })}
    
    difArr.forEach { (message) in
      dif > 0 ? self.insertMessage(message) : self.removeMessage(message)
    }
  }
  
  private func startPlayer(){
    
    var seekTo: Double?
    if let vod = videoContent as? VOD {
      seekTo = Double(vod.stopTime.duration())
    }
    player = Player(url: URL(string:videoContent.url)!, seekTo: seekTo)
    
    player.addPeriodicTimeObserver { [weak self] (time, isLikelyToKeepUp) in
      guard let `self` = self else {return}
      if isLikelyToKeepUp {
        self.videoContainerView.removeActivityIndicator()
        self.playButton.isHidden = false
        if !self.videoControlsView.isHidden {
          self.updatePlayButtonImage()
        }
      } else if self.player.isPlayerPaused == false, !self.videoContainerView.isActivityIndicatorLoaded {
        self.videoContainerView.showActivityIndicator()
        self.playButton.isHidden = true
      }
      self.activeSpendTime += 0.2
      
      if let vod = self.videoContent as? VOD {
        self.handleVODsChat(forTime: Int(time.seconds))
        self.seekLabel.text = String(format: "%@ / %@", Int(time.seconds).durationString(), vod.duration)
        if self.seekTo == nil, self.player.player.rate == 1 {
          self.portraitSeekSlider.setValue(Float(time.seconds), animated: false)
          self.landscapeSeekSlider.setValue(Float(time.seconds), animated: false)
        }
      } else {
        self.seekLabel.text = String(format: "%@", Int(time.seconds).durationString())
      }
    }
    
    player.playerReadyToPlay = { [weak self] in
      self?.isControlsEnabled = true
      self?.videoContainerView.image = nil
    }
    
    //TODO: AirPlay
    
    videoContainerView.player = player.player
    
    player.onErrorApear = { [weak self] error in
      self?.playButton.setImage(UIImage.image("Play"), for: .normal)
      self?.isPlayerControlsHidden = false
      self?.videoContainerView.removeActivityIndicator()
      self?.isControlsEnabled = true
      self?.swiftMessage?.showBanner(title: error.description)
      self?.isPlayerError = true
    }
    
    player.onVideoEnd = { [weak self] in
      self?.playButton.setImage(UIImage.image("Play"), for: .normal)
      if self?.videoContent is VOD {
        self?.isVideoEnd = true
        self?.isPlayerControlsHidden = false
        self?.startAutoplayNexItem()
      } else {
        //TODO: set thanks image
        self?.setThanksImage()
        self?.videoContainerView.layer.sublayers?.first?.isHidden = true
        self?.liveLabelWidth.constant = 0
        self?.playButton.isHidden = true
        self?.view.layoutIfNeeded()
      }
      
    }
    videoContainerView.showActivityIndicator()
  }

  private func setThanksImage() {
    let text = "thanks for watching"
    if let imageUrl = URL(string: videoContent.thumbnailUrl) {
      let _ =  ImageService.getImage(withURL: imageUrl) { [weak self] thumbnail in
        guard let `self` = self, let thumbnail = thumbnail else { return }
        let scale = UIScreen.main.scale
        let labelFrame = CGRect(origin: .zero, size: CGSize(width: thumbnail.size.width*3, height: thumbnail.size.height*3))
        UIGraphicsBeginImageContextWithOptions(labelFrame.size, false, scale)
        thumbnail.draw(in: labelFrame)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.black.withAlphaComponent(0.65).cgColor)
        context.fill(labelFrame)
        let label = UILabel(frame: labelFrame)
        label.text = text.uppercased()
        label.font = UIFont.systemFont(ofSize: labelFrame.size.height*0.08, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.draw(labelFrame)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.videoContainerView.image = newImage
        self.videoContainerView.isUserInteractionEnabled = false
      }
    }
  }

  private func startAutoplayNexItem() {
    if nextButton.isHidden {
      playButton.setImage(UIImage.image("PlayAgain"), for: .normal)
      return
    }

    isSeekByTappingMode = false

    playButton.setImage(UIImage.image("PlayNext"), for: .normal)
    previousButton.isHidden = true
    nextButton.isHidden = true
    isAutoplayMode = true
    cancelButton.isHidden = false

    playButton.layer.addSublayer(backgroundShape)
    playButton.layer.addSublayer(progressShape)
    adjustCircleLayersPath()
    let strokeWidth: CGFloat = 4.0
    backgroundShape.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
    backgroundShape.lineWidth = strokeWidth
    backgroundShape.fillColor = UIColor.clear.cgColor

    progressShape.strokeColor = UIColor.white.withAlphaComponent(0.67).cgColor
    progressShape.lineWidth = backgroundShape.lineWidth
    progressShape.fillColor = UIColor.clear.cgColor
    progressShape.lineCap = .round
    progressShape.strokeEnd = 0

    progressShape.removeAnimation(forKey: "fillAnimation")
    let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
    basicAnimation.toValue = 1
    basicAnimation.duration = 5
    basicAnimation.fillMode = .forwards
    basicAnimation.isRemovedOnCompletion = false
    progressShape.add(basicAnimation, forKey: "fillAnimation")

    autoplayDebouncer.call { [weak self] in
      guard let `self` = self else { return }
      self.goToButtonPressed(self.nextButton)
    }
  }

  private func adjustCircleLayersPath() {
    // temp solution (doesn't work in viewDidLayoutSubviews)
    let side = OrientationUtility.isLandscape ? 84 : 56
    let size = CGSize(width: side, height: side)
    let frame = CGRect(origin: .zero, size: size)
    backgroundShape.frame = frame
    progressShape.frame = frame
    backgroundShape.path = UIBezierPath(ovalIn: playButton.bounds).cgPath
    progressShape.path = UIBezierPath(arcCenter: CGPoint(x: playButton.bounds.width/2, y: playButton.bounds.height/2), radius: playButton.bounds.width/2, startAngle: -CGFloat.pi/2, endAngle: 1.5 * CGFloat.pi, clockwise: true).cgPath
  }


  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    autoplayDebouncer.call {}
    isAutoplayMode = false
    previousButton.isHidden = false
    nextButton.isHidden = false
    adjustVideoControlsButtons()
    updatePlayButtonImage()
    backgroundShape.removeFromSuperlayer()
    progressShape.removeFromSuperlayer()
    cancelButton.isHidden = true
  }

  @objc
  private func onSliderValChanged(slider: UISlider, event: UIEvent) {
    if let touchEvent = event.allTouches?.first {
      switch touchEvent.phase {
      case .began:
        seekTo = Int(slider.value)
        isVideoEnd = false
        cancelButtonTapped(cancelButton)
      case .moved:
        seekTo = Int(slider.value)
      default:
        seekTo = nil
      }
    }
  }
  
  private func insertMessage(_ message: Message) {
    messagesDataSource.append(message)
    updateChatTipView(newMessagesCount: messagesDataSource.count-alreadyWatchedMessage)
    let shouldScroll = currentTableView.contentOffset.y >= currentTableView.contentSize.height - currentTableView.frame.size.height - 20
    let indexPath = IndexPath(row: messagesDataSource.count - 1, section: 0)
    currentTableView.beginUpdates()
    currentTableView.insertRows(at: [indexPath], with: .none)
    currentTableView.endUpdates()
    updateContentInsetForTableView(currentTableView)
    currentTableView.layoutIfNeeded()
    if shouldScroll {
      UIView.animate(withDuration: 0.3) {
        self.currentTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
      }
    }
  }
  
  private func removeMessage(_ message: Message) {
    if let index = messagesDataSource.firstIndex(where: {$0.key == message.key}) {
      self.messagesDataSource.remove(at: index)
      if alreadyWatchedMessage > messagesDataSource.count {
        alreadyWatchedMessage = messagesDataSource.count
      }
      let indexPath = IndexPath(row: index, section: 0)
      UIView.setAnimationsEnabled(false)
      currentTableView.beginUpdates()
      currentTableView.deleteRows(at: [indexPath], with: .none)
      currentTableView.endUpdates()
      updateContentInsetForTableView(currentTableView)
      UIView.setAnimationsEnabled(true)
    }
  }

  private func updateBottomContainerGradientFrame() {
    let topExtra: CGFloat = 35
    let origin = CGPoint(x: bottomContainerView.bounds.origin.x, y: -topExtra)
    let size = CGSize(width: bottomContainerView.bounds.width, height: bottomContainerView.bounds.height+topExtra+view.safeAreaInsets.bottom)
    bottomContainerGradientLayer.frame = CGRect(origin: origin, size: size)
  }

  private func adjustVideoControlsButtons() {
    guard videoContent is VOD else {
      nextButton.isHidden = true
      previousButton.isHidden = true
      return
    }
    let index = dataSource.videos.firstIndex(where: { $0.id == videoContent.id }) ?? 0
    let videosCount = dataSource.videos.count
    
    switch index {
    case 0:
      previousButton?.isHidden = true
    case videosCount - 2:
      if videosCount % 15 == 0 {
        dataSource.fetchNextItemsFrom(index: videosCount) { (_) in }
      }
    case videosCount - 1:
      nextButton?.isHidden = true
    default:
      break
    }
  }
  
  private func updateContentInsetForTableView(_ table: UITableView) {
    let numRows = tableView(table, numberOfRowsInSection: 0)
    var contentInsetHeight = table.bounds.size.height
    guard table.contentSize.height <= contentInsetHeight else {
      table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
      if currentTableView == portraitTableView, shouldScrollPortraitTable {
        let lastIndexPath = IndexPath(row: self.messagesDataSource.count - 1, section: 0)
        if lastIndexPath.row >= 0 {
          self.currentTableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
          shouldScrollPortraitTable = false
        }
      }
      return
    }
    for i in 0..<numRows {
      let rowRect = table.rectForRow(at: IndexPath(item: i, section: 0))
      contentInsetHeight -= rowRect.size.height
      if contentInsetHeight <= 0 {
        contentInsetHeight = 0
      }
    }
    UIView.animate(
      withDuration: 0.3,
      delay: 0,
      options: [.curveEaseOut, .beginFromCurrentState],
      animations: {
        table.contentInset = UIEdgeInsets(top: contentInsetHeight, left: 0, bottom: 0, right: 0)
    },
      completion: nil)
  }

  @IBAction func chatTipPressed(_ sender: UITapGestureRecognizer) {
    let lastIndexPath = IndexPath(row: messagesDataSource.count-1, section: 0)
    currentTableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
    alreadyWatchedMessage = messagesDataSource.count
  }

  @IBAction func fullScreenButtonPressed(_ sender: UIButton) {
    OrientationUtility.rotateToOrientation(OrientationUtility.isPortrait ? .landscapeRight : .portrait)
  }
  
  @IBAction func closeButtonPressed(_ sender: UIButton) {
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    player.stop()
    dismiss(animated: true, completion: nil)
  }
  
  @objc
  private func didEnterBackgroundHandler() {
    player.pause()
    updatePlayButtonImage()
    isPlayerControlsHidden = false
  }
  
  func handleSeekByTapping(_ sender: UITapGestureRecognizer) {
    guard let vod = self.videoContent as? VOD else { return }
    self.controlsAppearingDebouncer.call {}
    self.videoControlsView.isHidden = true
    self.liveToLandscapeInfoTop.isActive = false
    self.view.layoutIfNeeded()
    let isLeftSide = sender.location(in: self.videoContainerView).x < self.videoContainerView.bounds.width / 2
    let activeSlider = OrientationUtility.currentOrientatin == .portrait ? self.portraitSeekSlider : self.landscapeSeekSlider
    self.seekTo = Int(activeSlider?.value ?? 0)
    
    if self.seekToByTapping == nil {
      self.seekToByTapping = self.seekTo
    }
    
    self.seekToByTapping! += isLeftSide ? -10 : 10
    
    switch self.seekToByTapping! {
    case let val where val < 0:
      self.seekToByTapping = 0
    case let val:
      self.seekToByTapping = (vod.duration.duration() >= val) ? val : (vod.duration.duration() - 1)
    }
    //Initialization of seekPaddingView
    if self.seekPaddingView == nil {
      self.seekPaddingView = SeekPaddingView(showInView: self.videoContainerView)
    }
    //seek forward/backward
    if isLeftSide {
      self.seekPaddingView?.seekBackward()
      self.seekPaddingView?.soughtTime = self.seekToByTapping! == 0 ? 10 : (self.seekPaddingView?.soughtTime)! + 10
    } else {
      self.seekPaddingView?.seekForward()
      self.seekPaddingView?.soughtTime = (self.seekToByTapping! != vod.duration.duration() - 1) ? (self.seekPaddingView?.soughtTime)! + 10 : 0
    }
    activeSlider?.setValue(Float(self.seekToByTapping!), animated: true)
    self.seekTo = self.seekToByTapping
    
    seekByTapDebouncer.call { [weak self] in
      self?.seekToByTapping = nil
      self?.timeOfLastTap = nil
      self?.seekTo = nil
      self?.updatePlayButtonImage()
      self?.seekPaddingView = nil
    }
  }
  
  @IBAction func handleTouchOnVideo(_ sender: UITapGestureRecognizer) {
    guard !isAutoplayMode else { return }
    let buttons: [UIButton] = [cancelButton, playButton] + fullScreenButtons
    let onButtons = buttons.map { $0.frame.contains(sender.location(in: videoContainerView)) && !isPlayerControlsHidden }.reduce(false) { $0 || $1 }
    guard isControlsEnabled else { return }
    if isKeyboardShown {
      chatTextView.endEditing(true)
      return
    }
    
    guard !onButtons, !(!pollContainerView.isHidden&&OrientationUtility.isLandscape) else { return }

    //MARK: seek by typing
    self.updatePlayButtonImage()
    if self.isSeekByTappingMode {
      self.isPlayerControlsHidden = true
      handleSeekByTapping(sender)
    } else {
      if self.timeOfLastTap == nil {
        self.timeOfLastTap = Date()
      } else {
        if Date().timeIntervalSince(self.timeOfLastTap!) > 0.3 {
          self.timeOfLastTap = nil
          self.seekToByTapping = nil
          self.isSeekByTappingMode = false
        }
        else {
          self.isSeekByTappingMode = true
          handleSeekByTapping(sender)
        }
      }
    }
    guard !self.isSeekByTappingMode else { return }
    self.isPlayerControlsHidden = !self.isPlayerControlsHidden
  }
  
  @objc
  func handleHideKeyboardGesture(_ sender: UITapGestureRecognizer) {
    if isKeyboardShown {
      chatTextView.endEditing(true)
    }
  }
  
  func setPlayerControlsHidden(_ isHidden: Bool) {
    if !isHidden {
      self.controlsDebouncer.call { }
    }
    controlsAppearingDebouncer.call { [weak self] in
      guard let `self` = self else { return }
      self.startLabel.text = self.videoContent.date.timeAgo()
      self.videoControlsView.isHidden = isHidden
      self.updateSeekThumbAppearance(isHidden: isHidden)
      if OrientationUtility.isLandscape {
        self.liveToLandscapeInfoTop.isActive = !isHidden
        self.landscapeTableViewContainer.isHidden = !isHidden
        self.bottomContainerView.isHidden = !isHidden
        self.updatePollBannerVisibility()
        self.view.layoutIfNeeded()
      }
      self.controlsDebouncer.call { [weak self] in
        guard let `self` = self else { return }
        //MARK: auto hide player controls
        if self.player.isPlayerPaused == false {
          if OrientationUtility.isLandscape && self.seekTo != nil {
            return
          }
          if OrientationUtility.isLandscape {
            self.landscapeTableViewContainer.isHidden = !self.pollContainerView.isHidden
            self.bottomContainerView.isHidden = !self.pollContainerView.isHidden
            self.liveToLandscapeInfoTop.isActive = false
            self.view.layoutIfNeeded()
          }
          self.updateSeekThumbAppearance(isHidden: true)
          self.videoControlsView.isHidden = true
          self.updatePollBannerVisibility()
        }
      }
    }
  }
  
  func updateSeekThumbAppearance(isHidden: Bool) {
    let thumbTintColor = isHidden ? .clear : UIColor.color("a_pink")
    self.landscapeSeekSlider?.tintColor = thumbTintColor
    self.landscapeSeekSlider?.isUserInteractionEnabled = !isHidden
  }
  
  @IBAction func playButtonPressed(_ sender: UIButton) {
    if self.isVideoEnd {
      if isAutoplayMode {
        goToButtonPressed(nextButton)
        return
      }
      self.isVideoEnd = false
      self.player.seek(to: .zero)
    }
    
    if player.isPlayerPaused {
      if isPlayerError {
        player.reconnect()
      } else {
        player.play()
      }
      
      controlsDebouncer.call { [weak self] in
        self?.isPlayerControlsHidden = true
      }
      
    } else {
      player.pause()
      controlsDebouncer.call {}
    }
    updatePlayButtonImage()
  }
  
  func updatePlayButtonImage() {
    guard !isAutoplayMode else { return }
    let image = (player.isPlayerPaused == false) ? UIImage.image("Pause") :
      isVideoEnd ? UIImage.image("PlayAgain") : UIImage.image("Play")
    self.playButton.setImage(image, for: .normal)
  }
  
  @IBAction func sendButtonPressed(_ sender: UIButton) {
    guard let user = User.current else {
      return
    }
    guard let text = chatTextView.text, text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 else {
      chatTextView.text.removeAll()
      self.adjustHeightForTextView(self.chatTextView)
      return
    }
    guard let _ = videoContent as? AntViewerExt.Live else {return}
    sender.isEnabled = false
    let message = Message(userID: "\(user.id)", nickname: user.displayName, text: text, avatarUrl: User.current?.imageUrl)
    chatTextView.text = ""
    self.adjustHeightForTextView(self.chatTextView)
    self.chat?.send(message: message) { (error) in
      if error == nil {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
          let lastIndexPath = IndexPath(row: self.messagesDataSource.count - 1, section: 0)
          if lastIndexPath.row >= 0 {
            self.currentTableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
          }
        })
      }
      sender.isEnabled = true
    }
  }
  
  func shouldEnableMessageTextFields(_ enable: Bool) {
    self.chatTextView.isEditable = enable && isChatEnabled
    self.sendButton.isEnabled = enable && isChatEnabled
  }
  
  @IBAction func editProfileButtonPressed(_ sender: UIButton?) {
    if editProfileContainerView.isHidden {
      showEditProfileView()
    } else {
      dismissEditProfileView()
    }
  }
  
  var editProfileControllerIsLoading = false
  
  func showEditProfileView() {
    guard pollContainerView.isHidden else { return }
    editProfileControllerIsLoading = true
    shouldEnableMessageTextFields(false)
    let editProfileController = EditProfileViewController(nibName: "EditProfileViewController", bundle: Bundle(for: type(of: self)))
    editProfileController.delegate = self
    addChild(editProfileController)
    editProfileContainerView.addSubview(editProfileController.view)
    editProfileController.didMove(toParent: self)
    editProfileController.view.translatesAutoresizingMaskIntoConstraints = false
    UIView.performWithoutAnimation {
      editProfileController.view.topAnchor.constraint(equalTo: self.editProfileContainerView.topAnchor).isActive = true
      editProfileController.view.leftAnchor.constraint(equalTo: self.editProfileContainerView.leftAnchor).isActive = true
      editProfileController.view.rightAnchor.constraint(equalTo: self.editProfileContainerView.rightAnchor).isActive = true
      editProfileController.view.bottomAnchor.constraint(equalTo: self.editProfileContainerView.bottomAnchor).isActive = true
    }
    
    
    editProfileContainerView.isHidden = false
  }
  
  func dismissEditProfileView() {
    shouldEnableMessageTextFields(true)

    editProfileContainerView.isHidden = true
    let editProfile = children.first(where: { $0 is EditProfileViewController})
    editProfile?.willMove(toParent: nil)
    editProfile?.view.removeFromSuperview()
    editProfile?.removeFromParent()
  }
  
  fileprivate func adjustHeightForTextView(_ textView: UITextView) {
    let fixedWidth = textView.frame.size.width
    let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
    messageHeight.constant = newSize.height > 26 ? newSize.height : 26
    view.layoutIfNeeded()
  }
  
  @IBAction func handleSwipeGesture(_ sender: UISwipeGestureRecognizer) {
    guard editProfileContainerView.isHidden, videoControlsView.isHidden else { return }
    let halfOfViewWidth = view.bounds.width / 2
    guard OrientationUtility.isLandscape, sender.location(in: view).x <= halfOfViewWidth else {return}
    
    var isRightDirection = false
    switch sender.direction {
    case .right:
      isRightDirection = true
    case .left:
      chatFieldLeading = -currentTableView.frame.width
      
    default:
      return
    }
    if videoContent is Live, isChatEnabled {
      isBottomContainerHidedByUser = !isRightDirection
      bottomContainerLandscapeTop.isActive = !isRightDirection
    }
    view.endEditing(false)
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
      self.currentTableView.frame.origin = CGPoint(x: isRightDirection ? 0 : -self.currentTableView.frame.width, y: 0)
    }
  }

  @IBAction func openPollBannerPressed(_ sender: Any) {
    guard editProfileContainerView.isHidden else { return }
    dismissEditProfileView()
    shouldEnableMessageTextFields(false)
    view.endEditing(true)
    pollController = PollController()
    pollController?.poll = activePoll
    guard let pollController = pollController else {return}
    addChild(pollController)
    pollContainerView.addSubview(pollController.view)
    pollController.view.frame = pollContainerView.bounds
    pollController.didMove(toParent: self)
    pollController.delegate = self
    pollContainerView.isHidden = false
    portraitTableView.isHidden = true
    bottomContainerView.isHidden = true
    pollBannerIcon.hideBadge()
    collapsePollBanner(animated: false)
    shouldShowPollBadge = true
    shouldShowExpandedBanner = false
    bottomContainerView.isHidden = true
    landscapeTableViewContainer.isHidden = true
  }

  
  @IBAction func goToButtonPressed(_ sender: UIButton) {
    let index = sender == nextButton ? 1 : -1
    
    guard let currentIndex = dataSource.videos.firstIndex(where: {$0.id == videoContent.id}), dataSource.videos.indices.contains(currentIndex + index),
      let navController = navigationController as? PlayerNavigationController else {
        return
    }
    let nextContent = dataSource.videos[currentIndex + index]
    let playerVC = PlayerController(nibName: "PlayerController", bundle: Bundle(for: type(of: self)))
    playerVC.videoContent = nextContent
    playerVC.dataSource = dataSource
    player.stop()
    navController.pushViewController(playerVC, withPopAnimation: sender == previousButton)
    
  }
  
  private func setupChatTableView(_ sender: UITableView) {
    let  cellNib = UINib.init(nibName: "PortraitMessageCell", bundle: Bundle(for: type(of: self)))
    let reuseIdentifire = "portraitCell"
    sender.register(cellNib, forCellReuseIdentifier: reuseIdentifire)
    sender.estimatedRowHeight = 50
    sender.estimatedSectionHeaderHeight = 0
    sender.estimatedSectionFooterHeight = 0
    sender.rowHeight = UITableView.automaticDimension
  }
}

//MARK: Keyboard handling
extension PlayerController {
  
  @objc
  fileprivate func keyboardWillChangeFrame(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
      let isHidden = keyboardSize.origin.y == view.bounds.height
      isKeyboardShown = !isHidden
      let userInfo = notification.userInfo!
      let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
      let rawAnimationCurve = (notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uint32Value << 16
      let animationCurve = UIView.AnimationOptions.init(rawValue: UInt(rawAnimationCurve))
      let bottomPadding = view.safeAreaInsets.bottom
      print(keyboardSize)
      if keyboardSize.width == view.frame.width {
        if isHidden {
          if editProfileControllerIsLoading { return }
          portraitMessageBottomSpace.constant = 0
          landscapeMessageBottomSpace.constant = 0
          liveLabel.isHidden = false
          viewersCountView.isHidden = false
          headerHeightConstraint.isActive = false
        } else if OrientationUtility.isLandscape {
          let isLeftInset = view.safeAreaInsets.left > 0
          chatFieldLeading = OrientationUtility.currentOrientatin == .landscapeRight && isLeftInset ? 30 : 0
          editProfileContainerLandscapeBottom.constant = keyboardSize.height
          landscapeMessageBottomSpace.constant = keyboardSize.height - bottomPadding
          liveLabel.isHidden = true
          viewersCountView.isHidden = true
        } else {
          headerHeightConstraint.isActive = true
          portraitMessageBottomSpace.constant = keyboardSize.height - bottomPadding
          editProfileContainerPortraitBottom.constant = keyboardSize.height
        }
      }
      adjustViewsFor(keyboardFrame: keyboardSize, with: animationDuration, animationCurve: animationCurve)
    }
  }

  
  func adjustViewsFor(keyboardFrame: CGRect, with animationDuration: TimeInterval, animationCurve: UIView.AnimationOptions) {
    adjustHeightForTextView(chatTextView)
    UIView.animate(withDuration: animationDuration, delay: 0, options: [.beginFromCurrentState, animationCurve], animations: {
      self.view.layoutIfNeeded()
      self.updateContentInsetForTableView(self.currentTableView)
    }, completion: { value in
      self.currentTableView.beginUpdates()
      self.currentTableView.endUpdates()
    })
  }
}

extension PlayerController: UITextViewDelegate {
  
  func textViewDidChange(_ textView: UITextView) {
    adjustHeightForTextView(textView)
  }
  
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    let curentText = text != "" ? (textView.text ?? "") + String(text.dropFirst()) : String((textView.text ?? " ").dropLast())
    
    if curentText.count > maxTextLength {
      textView.text = String(curentText.prefix(maxTextLength))
      return false
    }
    return textView.text.count + text.count - range.length <= maxTextLength
  }

  func textViewDidBeginEditing(_ textView: UITextView) {
    shouldScrollPortraitTable = true
    let lastIndexPath = IndexPath(row: self.messagesDataSource.count - 1, section: 0)
    if lastIndexPath.row >= 0 {
      self.currentTableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
    }
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    collapseChatTextView()
  }

  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    
    if User.current?.displayName.isEmpty == true {
      if editProfileContainerView.isHidden, !editProfileControllerIsLoading {
        showEditProfileView()
      }
      return false
    }
    expandChatTextView()
    return true
  }
  
}

extension PlayerController: UITableViewDataSource, UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if messagesDataSource.count > 0 {
      portraitTableView.backgroundView = nil
    } else if portraitTableView.backgroundView == nil {
      portraitTableView.backgroundView = EmptyView(frame: tableView.bounds)
    }
    return messagesDataSource.count
  }
  
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "portraitCell", for: indexPath) as! PortraitMessageCell
    
    let message = messagesDataSource[indexPath.row]
    let isCurrentUser = Int(message.userID) == User.current?.id
    cell.messageLabel.text = message.text
    let userName = isCurrentUser ? User.current?.displayName ?? message.nickname : message.nickname
    let date = Date(timeIntervalSince1970: TimeInterval(message.timestamp))
    cell.messageInfoLabel.text = String(format: "%@ at %@", userName, formatter.string(from: date))
    return cell
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard tableView == portraitTableView, shouldUpdateIndexPath else { return }
    alreadyWatchedMessage = max(indexPath.row+1, alreadyWatchedMessage)
  }
}


extension PlayerController: PollControllerDelegate {
  
  func pollControllerCloseButtonPressed() {
    pollController?.willMove(toParent: nil)
    pollController?.view.removeFromSuperview()
    pollController?.removeFromParent()
    pollController = nil
    pollContainerView.isHidden = true
    portraitTableView.isHidden = false
    bottomContainerView.isHidden = false
    pollAnswersFromLastView = activePoll?.answersCount.reduce(0,+) ?? 0
    bottomContainerView.isHidden = false
    landscapeTableViewContainer.isHidden = false
    shouldEnableMessageTextFields(true)
  }
}

extension PlayerController: EditProfileControllerDelegate {
  func editProfileLoaded() {
    editProfileControllerIsLoading = false
  }
  
  func editProfileCloseButtonPressed(withChanges: Bool) {
    if withChanges {
      currentTableView.reloadData()
    }
    dismissEditProfileView()
  }
}
