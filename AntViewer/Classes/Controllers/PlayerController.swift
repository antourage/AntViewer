//
//  PlayerController.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/5/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import AVKit
import ViewerExtension

private let maxTextLength = 250
private let maxUserNameLength = 50

class PlayerController: UIViewController {
  
//  private var player: Player!
  
  private var player: ModernAVPlayer!
  private var isPaused: Bool {
    guard let player = self.player else { return true }
    return player.state == .paused || player.state == .stopped || player.state == .failed
  }
  
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
      chatTextView.placeholder = LocalizedStrings.chatDisabled.localized
    }
  }
  @IBOutlet  var chatTextViewHolderView: UIView!
  @IBOutlet  var chatTextViewHolderViewLeading: NSLayoutConstraint!
  @IBOutlet var chatTextViewTrailing: NSLayoutConstraint!
  @IBOutlet  var bottomContainerLeading: NSLayoutConstraint!
  @IBOutlet  var bottomContainerTrailing: NSLayoutConstraint!
  @IBOutlet  var bottomContainerLandscapeTop: NSLayoutConstraint!
  @IBOutlet  var bottomContainerPortraitTop: NSLayoutConstraint!
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
  //MARK:  -

  //MARK: - new chat flow
  @IBOutlet var chatContainerView: UIView!
  @IBOutlet var chatContainerViewLandscapeLeading: NSLayoutConstraint!
  lazy var chatController: ChatViewController = {
    let vc = ChatViewController(nibName: "ChatViewController", bundle: Bundle(for: type(of: self)))
    vc.videoContent = videoContent
    vc.onTableViewTapped = { [weak self] in
      self?.view.endEditing(false)
      if OrientationUtility.isLandscape {
        self?.handleSingleTouchOnVideo(nil)
      }
    }
    vc.handleTableViewSwipeGesture = { [weak self] in
      self?.handleSwipe(isRightDirection: false)
    }
    return vc
  }()
  //MARK: -

  //MARK: - curtain staff
  @IBOutlet var skipCurtainButton: LocalizedButton!
  lazy var skipCurtainButtonDebouncer = Debouncer(delay: 7)
  var currentCurtain: CurtainRange?
  var shouldShowSkipButton = true
  //MARK: -

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
  @IBOutlet var cancelButton: LocalizedButton!
  @IBOutlet var fullScreenButtons: [UIButton]!
  @IBOutlet var liveDurationLabel: UILabel!
  private var isAutoplayMode = false
  private lazy var backgroundShape = CAShapeLayer()
  private lazy var progressShape = CAShapeLayer()
  lazy var autoplayDebouncer = Debouncer(delay: 4.5)
  //MARK: -
  
  
  @IBOutlet var pollContainerView: UIView!
  
  var activeSpendTime: Double = 0 {
    didSet {
      let type: ContentType = videoContent is VOD ? .VOD : .live
      Statistic.save(action: .close(span: Int(activeSpendTime)), for: type, contentID: videoContent.id)
    }
  }
  
  var dataSource: DataSource!
  fileprivate var streamTimer: Timer?
  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
    return OrientationUtility.isLandscape ? .top : .bottom
  }
  
  @IBOutlet var editProfileButton: UIButton! {
    didSet {
      editProfileButton.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
    }
  }
  @IBOutlet weak var shareButton: UIButton! {
     didSet {
       shareButton.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
     }
   }
  
  @IBOutlet var editProfileContainerView: UIView!
  var editProfileControllerIsLoading = false

  @IBOutlet weak var viewersCountLabel: UILabel! {
    didSet {
      viewersCountLabel.text = max(videoContent.viewsCount, 1).formatUsingAbbrevation()
    }
  }

  @IBOutlet var viewersCountView: UIView!

  @IBOutlet weak var portraitSeekSlider: CustomSlide! {
    didSet {
      if let video = videoContent as? VOD {
        portraitSeekSlider.isHidden = false
        self.portraitSeekSlider.isUserInteractionEnabled = false
        portraitSeekSlider.maximumValue = Float(video.duration.duration())
        portraitSeekSlider.setThumbImage(UIImage.image("thumb"), for: .normal)
        portraitSeekSlider.tintColor = .clear//UIColor.color("a_pink")
        portraitSeekSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        portraitSeekSlider.createAndSetMaxTrackImage(for: videoContent)
      }
    }
  }
  
  @IBOutlet weak var landscapeSeekSlider: CustomSlide! {
    didSet {
      if let video = videoContent as? VOD {
        landscapeSeekSlider.createAndSetMaxTrackImage(for: videoContent)
        landscapeSeekSlider.maximumValue = Float(video.duration.duration())
        landscapeSeekSlider.setThumbImage(UIImage.image("thumb"), for: .normal)
        landscapeSeekSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
      }
    }
  }
  
  @IBOutlet weak var seekLabel: UILabel! 

  //MARK: - new poll banner staff
  @IBOutlet var pollBannerAspectRatio: NSLayoutConstraint!
  @IBOutlet var pollBannerPortraitLeading: NSLayoutConstraint!
  @IBOutlet var pollTitleLabel: UILabel!
  @IBOutlet var pollBannerView: UIView!
  @IBOutlet var pollBannerIcon: UIImageView!
  var shouldShowExpandedBanner = true
  var pollAnswersFromLastView = 0
  var shouldShowPollBadge = false
  var isFirstTimeBannerShown = true
  //MARK: -

  //MARK: - edit profile staff
  @IBOutlet private var editProfileContainerPortraitBottom: NSLayoutConstraint!
  @IBOutlet private var editProfileContainerLandscapeBottom: NSLayoutConstraint!

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
  
  lazy var userImageView: CacheImageView = {
    let imageView = CacheImageView()
    circleImageView.addSubview(imageView)
    imageView.contentMode = .scaleAspectFill
    fixImageView(imageView, in: circleImageView)
    return imageView
  }()

  lazy var landscapeUserImageView: CacheImageView = {
    let imageView = CacheImageView()
    landscapeCircleImageView.addSubview(imageView)
    imageView.contentMode = .scaleAspectFill
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
          if isBottomContainerHidedByUser {
            chatTextView.resignFirstResponder()
          }
          if !viewersCountView.isHidden {
            liveToLandscapeInfoTop?.isActive = !isPlayerControlsHidden
            view.layoutIfNeeded()
          }
          if videoContent is Live {
            landscapeSeekSlider.removeFromSuperview()
          }
        } else {
          liveLabel.alpha = 1
          viewersCountView.alpha = 1
          bottomContainerLeading.constant = .zero
          bottomContainerTrailing.constant = .zero
        }
        if isAutoplayMode {
          adjustCircleLayersPath()
        }
        if shouldShowExpandedBanner, activePoll?.userAnswer == nil, activePoll != nil {
          expandPollBanner()
        }
        chatController.updateContentInsetForTableView()
        updateChatVisibility()
        updateBottomContainerVisibility()
        updatePollBannerVisibility()
      }
    }
  }

  fileprivate var isReachable: Bool {
    URLSessionNetworkDispatcher.instance.isReachable
  }

  private func updatePollBannerVisibility() {
    pollBannerView.isHidden = activePoll == nil
    if OrientationUtility.isLandscape {
      if !isPlayerControlsHidden {
        pollBannerView.alpha = 0
      } else {
        pollBannerView.alpha = activePoll == nil ? 0 : 1

      }
    } else {
      pollBannerView.alpha = activePoll == nil ? 0 : 1
    }
  }

  lazy var formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()
  fileprivate var pollManager: PollManager?
  fileprivate var shouldShowPollAnswers = false
  var pollBannerDebouncer = Debouncer(delay: 6)
  var activePoll: Poll? {
    didSet {
      NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "PollUpdated"), object: nil, userInfo: ["poll" : activePoll ?? 0])
      guard activePoll != nil else {
        pollBannerDebouncer.call {}
        self.shouldShowPollAnswers = false
        self.shouldShowExpandedBanner = true
        self.isFirstTimeBannerShown = true
        self.pollControllerCloseButtonPressed()
        self.collapsePollBanner()
        updatePollBannerVisibility()
        self.pollBannerIcon.hideBadge()
        return
      }

      activePoll?.onUpdate = { [weak self] in
        guard let `self` = self, self.activePoll != nil else { return }
        if self.pollBannerView.isHidden {
          self.updatePollBannerVisibility()
          self.activePoll?.userAnswer != nil ? self.collapsePollBanner(animated: false) : self.expandPollBanner()
          self.pollTitleLabel.text = self.activePoll?.pollQuestion
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
      sendButton.isEnabled = isChatEnabled
      if !isChatEnabled {
        if !isKeyboardShown {
          chatTextViewTrailing.isActive = true
        }
        chatTextView.text = ""
      }
      chatTextView.isEditable = isChatEnabled

      chatTextView.placeholder = isChatEnabled ? LocalizedStrings.chat.localized :
        LocalizedStrings.chatDisabled.localized
      updateBottomContainerVisibility()
      let alpha: CGFloat = isChatEnabled ? 0.6 : 0.2
      chatTextViewHolderView.layer.borderColor = UIColor.white.withAlphaComponent(alpha).cgColor
      chatTextView.placeholderTextColor = isChatEnabled ? .cellGray : .bottomMessageGray
      view.layoutIfNeeded()

    }
  }
  
  private var chat: Chat? {
    didSet {
      chat?.onAdd = { [weak self] message in
        self?.videoContent is VOD ? self?.chatController.vodMessages.append(message) : self?.chatController.insertMessages([message])
      }
      chat?.onRemove = { [weak self] message in
        self?.chatController.deleteMessages([message])
      }
      chat?.onStateChange = { [weak self] isActive in
        if self?.videoContent is Live {
          self?.isChatEnabled = isActive
          if self?.shouldEnableChatField == true, isActive {
            self?.chatTextView.becomeFirstResponder()
          }
          self?.shouldEnableChatField = false
        } else {
          self?.isChatEnabled = false
        }
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
        self?.chatController.scrollToBottom()
      }
    }
  }
  
  var videoContent: VideoContent!
  fileprivate var isVideoEnd = false
  fileprivate var isPlayerError = false
  
  var pollController: PollController?

  
  fileprivate var isControlsEnabled = false
  fileprivate var controlsDebouncer = Debouncer(delay: 2)
  fileprivate var seekByTapDebouncer = Debouncer(delay: 0.7)
  fileprivate var dobleTapDebouncer = Debouncer(delay: 0.5)
  fileprivate var acivityIndicatorDebouncer = Debouncer(delay: 0.5)
  
  //MARK: For vods
  fileprivate var vodMessages: [Message]? = []
  fileprivate var chatFieldLeading: CGFloat! {
    didSet {
      chatFieldLeadingChanged?(chatFieldLeading)
    }
  }
  var chatFieldLeadingChanged: ((CGFloat) -> ())?
  fileprivate var seekToByTapping: Int?
  fileprivate var isSeekByTappingMode = false
  fileprivate var seekPaddingView: SeekPaddingView?
  fileprivate var isPlayerControlsHidden: Bool = true {
    didSet {
      setPlayerControlsHidden(isPlayerControlsHidden)
    }
  }
  fileprivate var goToPressed = false

  private lazy var bottomMessage = BottomMessage(presentingController: self)

  private var playerSeekManualy = false
  fileprivate var seekTo: Int? {
    didSet {
      if seekTo == nil, let time = oldValue {
        player.player.rate = 0
        self.isVideoEnd = false
        playerSeekManualy = true
        player.seek(position: min(Double(time), (player.player.currentItem?.duration.seconds ?? 0.1) - 0.1))
        controlsDebouncer.call { [weak self] in
          if self?.isPaused == false {
            if OrientationUtility.isLandscape && self?.seekTo != nil {
              return
            }
            self?.isPlayerControlsHidden = true
          }
        }
      }
    }
  }
  var shouldEnableChatField = false
  
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
    previousButton.isExclusiveTouch = true
    nextButton.isExclusiveTouch = true
    setupGestureRecognizers()
    addChild(chatController)
    chatController.view.fixInView(chatContainerView)
    chatController.didMove(toParent: self)
    //FIXME:
    OrientationUtility.rotateToOrientation(OrientationUtility.currentOrientatin)
    currentOrientation = OrientationUtility.currentOrientatin
    self.dataSource.pauseUpdatingStreams()
     var token: NSObjectProtocol?
     token = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] (notification) in
       guard let `self` = self else {
         NotificationCenter.default.removeObserver(token!)
         return
       }
       self.currentOrientation = OrientationUtility.currentOrientatin
     }

    if self.videoContent is Live {
      // Move me
       self.pollManager = FirePollManager(streamId: self.videoContent.id)
       self.pollManager?.observePolls(completion: { [weak self] (poll) in
          self?.activePoll = poll
        })
       self.streamTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] (myTimer) in
          guard let `self` = self else {
            myTimer.invalidate()
            return
          }
          self.dataSource.getViewers(for: self.videoContent.id) { (result) in
            switch result {
            case .success(let count):
              self.viewersCountLabel.text = max(count, 1).formatUsingAbbrevation()
            case .failure(let error):
              print(error.localizedDescription)
            }
          }
        })

      }
    updateBottomContainerVisibility()
    
    //Why?
    DispatchQueue.main.async { [weak self] in
      guard let `self` = self else { return }
      self.isChatEnabled = false
      try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
      let type: ContentType = self.videoContent is VOD ? .VOD : .live
      Statistic.send(action: .open, for: type, contentID: self.videoContent.id)
      self.chat = FireChat(for: self.videoContent)
      self.startPlayer()
    }
    self.adjustHeightForTextView(self.chatTextView)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    adjustVideoControlsButtons()
    NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundHandler), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleWillBecomeActive(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    UIApplication.shared.isIdleTimerDisabled = true
    startObservingReachability()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    chatController.updateContentInsetForTableView()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self)
    view.endEditing(true)
    UIApplication.shared.isIdleTimerDisabled = false
    if let vod = videoContent as? VOD {
      vod.isNew = false
    }
    dataSource.startUpdatingStreams()
    streamTimer?.invalidate()
    stopObservingReachability()
  }
  
  deinit {
    print("Player DEINITED")
    pollManager?.removeFirebaseObserver()
    let type: ContentType = self.videoContent is VOD ? .VOD : .live
    Statistic.send(action: .close(span: Int(activeSpendTime)), for: type, contentID: self.videoContent.id)
    SponsoredBanner.current = nil
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    if videoContent is VOD {
      updateBottomContainerVisibility()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if OrientationUtility.isLandscape {
      updateBottomContainerGradientFrame()
    }
    userImageView.layer.cornerRadius = userImageView.bounds.width/2
    landscapeUserImageView.layer.cornerRadius = landscapeUserImageView.bounds.width/2
  }

  private func setupGestureRecognizers() {
    let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTouchOnVideo(_:)))
    singleTapGesture.numberOfTapsRequired = 1
    videoContainerView.addGestureRecognizer(singleTapGesture)
    singleTapGesture.delegate = self
    if videoContent is VOD {
      let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTouchOnVideo(_:)))
      doubleTapGesture.numberOfTapsRequired = 2
      videoContainerView.addGestureRecognizer(doubleTapGesture)
      doubleTapGesture.delegate = self
      singleTapGesture.require(toFail: doubleTapGesture)
    }
  }
  
  func collapseChatTextView() {
    chatTextViewHolderViewLeading.isActive = false
    editProfileButton.isHidden = false
    chatTextViewTrailing.isActive = chatTextView.text.isEmpty
    bottomContainerLeading.constant = .zero
    bottomContainerTrailing.constant = .zero
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }

  func expandChatTextView() {
    chatTextViewHolderViewLeading.isActive = true
    chatTextViewTrailing.isActive = false
    editProfileButton.isHidden = true
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

  func updateChatVisibility() {
    if videoContent is Live {
      guard !isVideoEnd else {
        chatContainerView.alpha = currentOrientation.isLandscape ? 0 : 1
        return
      }
      if currentOrientation.isLandscape {
        let hidden = !isPlayerControlsHidden || !pollContainerView.isHidden
        chatContainerView.alpha = hidden ? 0 : 1
        return
      }
    } else {
      if currentOrientation.isLandscape {
        let hidden = !isPlayerControlsHidden || isAutoplayMode
        chatContainerView.alpha = hidden ? 0 : 1
        return
      }
    }
    chatContainerView.alpha = 1
  }

  func updateBottomContainerVisibility(animated: Bool = false) {
    defer {
      UIView.animate(withDuration: animated ? 0.3 : 0) {
        self.view.layoutIfNeeded()
      }
    }
    if videoContent is Live {
      guard !isVideoEnd else {
        bottomContainerView.alpha = currentOrientation.isLandscape ? 0 : 1
        bottomContainerGradientLayer.removeFromSuperlayer()
        return
      }
      if currentOrientation.isLandscape {
        let hidden = !isPlayerControlsHidden || !pollContainerView.isHidden
        bottomContainerView.alpha = hidden ? 0 : 1
        bottomContainerLandscapeTop.isActive = isBottomContainerHidedByUser
        bottomContainerGradientLayer.removeFromSuperlayer()
        bottomContainerView.layer.insertSublayer(bottomContainerGradientLayer, at: 0)
        return
      }
      bottomContainerView.alpha = 1
      bottomContainerView.isHidden = false
      bottomContainerPortraitTop.isActive = false
    } else {
      bottomContainerView.alpha = 0
      bottomContainerPortraitTop.isActive = true
      bottomContainerLandscapeTop.isActive = true
    }
    bottomContainerGradientLayer.removeFromSuperlayer()
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


  func startObservingReachability() {
    if !isReachable {
      let color = UIColor.color("a_bottomMessageGray")
      bottomMessage.showMessage(title: LocalizedStrings.noConnection.localized.uppercased() , backgroundColor: color ?? .gray)
    }
    NotificationCenter.default.addObserver(self, selector: #selector(handleReachability(_:)), name: .reachabilityChanged, object: nil)
  }

  func stopObservingReachability() {
    NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: nil)
    bottomMessage.hideMessage()
  }

  @objc
  private func handleReachability(_ notification: Notification) {
    if isReachable {
      let color = UIColor.color("a_bottomMessageGreen")
      bottomMessage.showMessage(title: LocalizedStrings.youAreOnline.localized.uppercased(), duration: 2, backgroundColor: color ?? .green)
      //continue playing after connection established
      if player.state == .failed {
        if let media = player.currentMedia, let vod = videoContent as? VOD {
          player.load(media: media, autostart: true, position: Double(vod.stopTime.duration()))
        } else {
          player.play()
        }
      }
    } else {
      let color = UIColor.color("a_bottomMessageGray")
      bottomMessage.showMessage(title: LocalizedStrings.noConnection.localized.uppercased(), backgroundColor: color ?? .gray)
    }
  }

  @objc
  private func handleWillBecomeActive(_ notification: NSNotification) {
    if videoContent is Live {
      landscapeSeekSlider.removeFromSuperview()
      if let media = player.currentMedia {
        player.load(media: media, autostart: false)
      }
    } else {
      portraitSeekSlider.createAndSetMaxTrackImage(for: videoContent)
      landscapeSeekSlider.createAndSetMaxTrackImage(for: videoContent)
    }
    updateBottomContainerVisibility()
    if OrientationUtility.isLandscape {
      self.liveToLandscapeInfoTop?.isActive = !isPlayerControlsHidden
    }
    self.view.layoutIfNeeded()
  }
  
  private func startPlayer(){
    var seekTo: Double?
    if let vod = videoContent as? VOD {
      let alreadyWatchedTime = Double(vod.stopTime.duration())
      let duration = Double(vod.duration.duration())
      seekTo = alreadyWatchedTime/duration >= 0.9 ? 0 : alreadyWatchedTime
      var startCurtain = vod.curtainRangeModels.first { curtain in
        var tempCurt = curtain
        return tempCurt.range.lowerBound == 0 &&     
          tempCurt.range.contains(seekTo ?? 0)
        }
      currentCurtain = startCurtain
      if let curtainUpperBound = startCurtain?.range.upperBound {
        seekTo = Int(curtainUpperBound) >= vod.duration.duration() ? seekTo : curtainUpperBound
      }
    }

    guard let url = URL(string: videoContent.url) else {
      showError(autohide: false)
      return
    }
    
    let media = ModernAVPlayerMedia(url: url, type: videoContent is Live ? .stream(isLive: true) : .clip)
    player = ModernAVPlayer(config: AntourageAVPlayerConfiguration())
    player.load(media: media, autostart: true, position: seekTo)
    player.delegate = self
     
    //TODO: AirPlay
    
    videoContainerView.player = player.player
    videoContainerView.showActivityIndicator()
  }

  private func showError(autohide: Bool = true, message: String = LocalizedStrings.generalError.localized) {
    let color = UIColor.color("a_bottomMessageGray") ?? .gray
    bottomMessage.showMessage(title: message.uppercased(), duration: autohide ? 3 : .infinity, backgroundColor: color)
  }

  private func setThanksImage() {
    let text = LocalizedStrings.thanksForWatching.localized.uppercased()
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
        label.font = UIFont.systemFont(ofSize: labelFrame.size.height*0.06, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.draw(labelFrame)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.isPlayerControlsHidden = true
        self.liveDurationLabel.text = self.seekLabel.text
        self.seekLabel.isHidden = true
        self.liveDurationLabel.isHidden = false
        self.videoContainerView.image = newImage
        self.videoContainerView.isUserInteractionEnabled = true
      }
    }
  }

  private func startAutoplayNexItem() {
    if nextButton.isHidden {
      playButton.setImage(UIImage.image("PlayAgain"), for: .normal)
      return
    }

    playButton.setImage(UIImage.image("PlayNext"), for: .normal)
    previousButton.isHidden = true
    nextButton.isHidden = true
    isAutoplayMode = true
    cancelButton.isHidden = false

    playButton.layer.addSublayer(backgroundShape)
    playButton.layer.addSublayer(progressShape)
    adjustCircleLayersPath()
    let strokeWidth: CGFloat = 2.64
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


  @IBAction func cancelButtonTapped(_ sender: UIButton?) {
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

  @IBAction func skipCurtainButtonTapped(_ sender: UIButton) {
    //MARK: skip curtain
    defer {
      skipCurtainButtonDebouncer.call { }
      setSkipButtonHidden(hidden: true)
    }
    guard let vod = videoContent as? VOD,
      var currentCurtain = vod.curtainRangeModels
        .first(where: {
        var curtain = $0
        return curtain.range.contains(player.currentTime)
      }) else {
        return
    }
    seekTo = Int(currentCurtain.range.upperBound)
    seekTo = nil
  }
// FIXME: simplify (it executs every second)
  private func checkCurtains() {
    guard let vod = videoContent as? VOD,
    var curtain = vod.curtainRangeModels
      .first(where: {
      var curtain = $0
      return curtain.range.contains(player.currentTime)
      }) else {
        currentCurtain = nil
        setSkipButtonHidden(hidden: true)
        shouldShowSkipButton = true
        return
    }

    if var currentCurtain = currentCurtain {
      if currentCurtain.range != curtain.range {
        currentCurtain = curtain
        shouldShowSkipButton = false
        setSkipButtonHidden(hidden: true)
      }
    } else if Int(curtain.range.upperBound) >= vod.duration.duration() {
      currentCurtain = curtain
      shouldShowSkipButton = false
      setSkipButtonHidden(hidden: true)
    } else {
      currentCurtain = curtain
      setSkipButtonHidden(hidden: !shouldShowSkipButton)
      skipCurtainButtonDebouncer.call { [weak self] in
      self?.shouldShowSkipButton = false
        self?.setSkipButtonHidden(hidden: true)
      }
    }
  }

  private func setSkipButtonHidden(hidden: Bool) {
    guard skipCurtainButton.isHidden != hidden else { return }
    if !hidden {
      skipCurtainButton.alpha = 0
      skipCurtainButton.isHidden = false
    }
    UIView.animate(withDuration: 0.2, animations: {
      self.skipCurtainButton.alpha = hidden ? 0 : 1
    }) { _ in
      self.skipCurtainButton.isHidden = hidden
    }
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

  @IBAction func fullScreenButtonPressed(_ sender: UIButton?) {
    OrientationUtility.rotateToOrientation(OrientationUtility.isPortrait ? .landscapeRight : .portrait)
  }
  
  @IBAction func closeButtonPressed(_ sender: UIButton?) {
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    player.delegate = nil
    player?.stop()
    dismiss(animated: true, completion: nil)
  }
  
  @objc
  private func didEnterBackgroundHandler() {
    player?.pause()
    updatePlayButtonImage()
    if !liveDurationLabel.isHidden, videoContent is Live {
      isPlayerControlsHidden = true
    }
    if isAutoplayMode {
      cancelButtonTapped(nil)
    }
    chatTextView.resignFirstResponder()
  }
  
  func handleSeekByTapping(_ backwardDirection: Bool) {
    guard let vod = self.videoContent as? VOD else { return }
    self.isPlayerControlsHidden = true
    if OrientationUtility.isLandscape {
      self.liveToLandscapeInfoTop?.isActive = false
      self.view.layoutIfNeeded()
    }
    let activeSlider = OrientationUtility.currentOrientatin == .portrait ? self.portraitSeekSlider : self.landscapeSeekSlider
    self.seekTo = Int(activeSlider?.value ?? 0)
    
    if self.seekToByTapping == nil {
      self.seekToByTapping = self.seekTo
    }
    
    self.seekToByTapping! += backwardDirection ? -10 : 10
    
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
    if backwardDirection {
      self.seekPaddingView?.seekBackward()
      self.seekPaddingView?.soughtTime = self.seekToByTapping! == 0 ? 10 : (self.seekPaddingView?.soughtTime)! + 10
    } else {
      self.seekPaddingView?.seekForward()
      self.seekPaddingView?.soughtTime = (self.seekToByTapping! != vod.duration.duration() - 1) ? (self.seekPaddingView?.soughtTime)! + 10 : 10
    }
    activeSlider?.setValue(Float(self.seekToByTapping!), animated: true)
    self.seekTo = self.seekToByTapping
    
    seekByTapDebouncer.call { [weak self] in
      self?.seekToByTapping = nil
      self?.seekTo = nil
      self?.updatePlayButtonImage()
      self?.seekPaddingView = nil
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        self?.isSeekByTappingMode = false
      }
    }
  }
  
  @objc
  func handleSingleTouchOnVideo(_ sender: UITapGestureRecognizer?) {
    guard !isAutoplayMode, !isSeekByTappingMode else { return }

    guard isControlsEnabled else { return }
    if isKeyboardShown {
      chatTextView.endEditing(true)
      return
    }

    guard !(!pollContainerView.isHidden && OrientationUtility.isLandscape) else { return }
    self.isPlayerControlsHidden = !self.isPlayerControlsHidden
  }
  
  @objc
  func handleDoubleTouchOnVideo(_ sender: UITapGestureRecognizer) {
    sender.numberOfTapsRequired = 1
    dobleTapDebouncer.call {
      sender.numberOfTapsRequired = 2
    }
    //fixme
    let isLeftSide = sender.location(in: self.videoContainerView).x < self.videoContainerView.bounds.width / 2

    self.updatePlayButtonImage()
    if !self.isSeekByTappingMode {
      self.isSeekByTappingMode = true
    }
    handleSeekByTapping(isLeftSide)
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
    
    if !isHidden {
      self.videoControlsView.alpha = 0
      self.videoControlsView.isHidden = false
    }
    UIView.animate(withDuration: 0.2, animations: {
      self.videoControlsView.alpha = isHidden ? 0 : 1
      self.updateSeekThumbAppearance(isHidden: isHidden)
      self.skipCurtainButton.alpha = !isHidden ? 0 : 1
      if OrientationUtility.isLandscape {
        self.liveToLandscapeInfoTop?.isActive = !isHidden
        self.view.layoutIfNeeded()
        self.updatePollBannerVisibility()
      }
      self.updateChatVisibility()
      self.updateBottomContainerVisibility()
    }) { (finished) in
      if isHidden {
        self.videoControlsView.isHidden = true
      }
    }
    guard !self.isPlayerControlsHidden else { return }
    self.controlsDebouncer.call { [weak self] in
      guard let `self` = self else { return }
      if !self.isPaused || !(self.isVideoEnd && self.isAutoplayMode) {
        if (OrientationUtility.isLandscape && self.seekTo != nil) || self.isPlayerError {
          return
        }
        self.isPlayerControlsHidden = true
      }
    }
  }
  
  func updateSeekThumbAppearance(isHidden: Bool) {
    let thumbTintColor = isHidden ? .clear : UIColor.color("a_pink")
    self.portraitSeekSlider.tintColor = thumbTintColor
    self.portraitSeekSlider.isUserInteractionEnabled = !isHidden
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
    }
    
    if isPaused {
      //MARK: Bug, unable to start player when paused in the end of duration
      if let vod = videoContent as? VOD {
        let delta = Double(vod.duration.duration()) - player.currentTime
        if delta < 1.5 {
          player.seek(position: player.currentTime - 1)
        }
      }
      
      if isPlayerError, let media = player.currentMedia {
        if let vod = videoContent as? VOD {
          player.load(media: media, autostart: true, position: Double(vod.stopTime.duration()))
        } else {
          let position = seekLabel.text?.duration()
          player.load(media: media, autostart: true, position: Double(position ?? 0))
        }
      } else {
        player.play()
      }
      controlsDebouncer.call { [weak self] in
        self?.isPlayerControlsHidden = true
      }
    } else if player.state == .loaded {
      player.play()
    } else {
      player.pause()
      controlsDebouncer.call {}
    }
    updatePlayButtonImage()
  }
  
  func updatePlayButtonImage() {
    guard !isAutoplayMode, let player = player else { return }
    var image: UIImage?
    switch player.state {
      case .paused, .failed, .loaded: image = UIImage.image("Play")
      case .stopped: image = UIImage.image("PlayAgain")
      case .loading, .buffering: image = nil
      default: image = UIImage.image("Pause")
    }
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
    guard let _ = videoContent as? ViewerExtension.Live else {return}
    sender.isEnabled = false
    let message = Message(userID: "\(user.id)", nickname: user.displayName, text: text, avatarUrl: User.current?.imageUrl)
    chatTextView.text.removeAll()
    if !chatTextView.isFirstResponder {
      collapseChatTextView()
    }
    self.adjustHeightForTextView(self.chatTextView)
    sender.isEnabled = !isReachable
    self.chat?.send(message: message) { (error) in
      if error == nil {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
          self.chatController.scrollToBottom()
        })
      }
      sender.isEnabled = true
    }
  }
  
  func shouldEnableMessageTextFields(_ enable: Bool) {
    self.chatTextView.isEditable = enable && isChatEnabled
    self.sendButton.isEnabled = enable && isChatEnabled
  }
  
  fileprivate func adjustHeightForTextView(_ textView: UITextView) {
    let fixedWidth = textView.frame.size.width
    let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
    messageHeight.constant = newSize.height > 26 ? newSize.height : 26
    view.layoutIfNeeded()
  }
  
  @IBAction func handleSwipeGesture(_ sender: UISwipeGestureRecognizer) {
    let halfOfViewWidth = view.bounds.width / 2
    guard OrientationUtility.isLandscape, sender.location(in: view).x <= halfOfViewWidth else {return}
    handleSwipe(isRightDirection: true)
  }

  private func handleSwipe(isRightDirection: Bool) {
    guard editProfileContainerView.isHidden, videoControlsView.isHidden else { return }
    if videoContent is Live {
      isBottomContainerHidedByUser = !isRightDirection
    }
    updateBottomContainerVisibility(animated: true)
    chatContainerViewLandscapeLeading.constant = isRightDirection ? 16 : chatContainerView.bounds.width+16
    view.endEditing(false)
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
      self.chatController.updateContentInsetForTableView()
    }
  }

  @IBAction func handleHideGesture(_ sender: UISwipeGestureRecognizer) {
    if currentOrientation.isPortrait {
      closeButtonPressed(nil)
    } else {
      fullScreenButtonPressed(nil)
    }
  }
  
  @IBAction func goToButtonPressed(_ sender: UIButton) {
    guard !goToPressed else { return }
    goToPressed = true
    let index = sender == nextButton ? 1 : -1
    
    guard let currentIndex = dataSource.videos.firstIndex(where: {$0.id == videoContent.id}), dataSource.videos.indices.contains(currentIndex + index),
      let navController = navigationController as? PlayerNavigationController else {
        return
    }
    let nextContent = dataSource.videos[currentIndex + index]
    let playerVC = PlayerController(nibName: "PlayerController", bundle: Bundle(for: type(of: self)))
    playerVC.videoContent = nextContent
    playerVC.dataSource = dataSource
    player.delegate = nil
    player.stop()
    navController.pushViewController(playerVC, withPopAnimation: sender == previousButton)
    
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
          liveLabel.alpha = 1
          viewersCountView.alpha = 1
        } else if OrientationUtility.isLandscape {
          let isLeftInset = view.safeAreaInsets.left > 0
          chatFieldLeading = OrientationUtility.currentOrientatin == .landscapeRight && isLeftInset ? 30 : 0
          editProfileContainerLandscapeBottom.constant = keyboardSize.height
          landscapeMessageBottomSpace.constant = keyboardSize.height - bottomPadding
          liveLabel.alpha = 0
          viewersCountView.alpha = 0
        } else {
          portraitMessageBottomSpace.constant = keyboardSize.height - bottomPadding
          editProfileContainerPortraitBottom.constant = keyboardSize.height
        }
      }
      adjustHeightForTextView(chatTextView)
      UIView.animate(withDuration: animationDuration, delay: 0, options: [.beginFromCurrentState, animationCurve], animations: {
        self.view.layoutIfNeeded()
        self.chatController.updateContentInsetForTableView()
      }, completion: nil)
    }
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
    chatController.scrollToBottom()
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




extension PlayerController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    touch.view === videoContainerView || touch.view === videoControlsView
  }
}

extension PlayerController: ModernAVPlayerDelegate {
  func modernAVPlayer(_ player: ModernAVPlayer, didStateChange state: ModernAVPlayer.State) {
    DispatchQueue.main.async { [weak self] in
      guard let `self` = self else { return }
      print("Player state: \(Date().debugDescription) \(state)")
      switch state {
        case .failed:
          self.isPlayerControlsHidden = false
          self.acivityIndicatorDebouncer.call {}
          self.videoContainerView.removeActivityIndicator()
          self.isControlsEnabled = true
          if self.isReachable {
            self.showError(message: LocalizedStrings.streamInterrupted.localized)
          }
          self.isPlayerError = true
        case .loaded:
          self.isControlsEnabled = true
          self.videoContainerView.image = nil
          self.isPlayerError = false
          self.acivityIndicatorDebouncer.call {}
          self.videoContainerView.removeActivityIndicator()
          self.playButton.isHidden = false
          if !self.videoControlsView.isHidden {
            self.updatePlayButtonImage()
          }
        case .playing:
          self.acivityIndicatorDebouncer.call {}
          self.videoContainerView.removeActivityIndicator()
        case .buffering, .loading:
          guard !self.videoContainerView.isActivityIndicatorLoaded else { break }
          self.acivityIndicatorDebouncer.call { [weak self] in
            self?.videoContainerView.showActivityIndicator()
          }
        case .stopped:
          self.isVideoEnd = true
          if self.videoContent is VOD {
            self.isSeekByTappingMode = false
            self.seekByTapDebouncer.call {}
            self.seekPaddingView = nil
            self.isPlayerControlsHidden = false
            self.startAutoplayNexItem()
          } else {
            //MARK: set thanks image
            self.setThanksImage()
            self.isChatEnabled = false
            self.editProfileButton.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            self.editProfileButton.tintColor = UIColor.white.withAlphaComponent(0.2)
            self.videoContainerView.layer.sublayers?.first?.isHidden = true
            self.liveLabelWidth.constant = 0
            self.playButton.isHidden = true
            self.view.layoutIfNeeded()
          }
          self.updateChatVisibility()
        default: break
      }
      self.updatePlayButtonImage()
    }
  }
  
  func modernAVPlayer(_ player: ModernAVPlayer, didCurrentTimeChange currentTime: Double) {
    DispatchQueue.main.async { [weak self] in
      guard let `self` = self else { return }

      self.activeSpendTime += 0.2
      if let vod = self.videoContent as? VOD {
        let playerSeekManualy = self.playerSeekManualy
        if playerSeekManualy {
          self.playerSeekManualy = false
          if self.isSeekByTappingMode  {
            self.isSeekByTappingMode = false
          }
          self.shouldShowSkipButton = false
          self.setSkipButtonHidden(hidden: true)
        }
        if !playerSeekManualy {
          if self.seekTo == nil, self.player.player.rate == 1 {
            self.checkCurtains()
            self.portraitSeekSlider.setValue(Float(currentTime), animated: false)
            self.landscapeSeekSlider.setValue(Float(currentTime), animated: false)
          }
        }
        
        vod.stopTime = min(Int(currentTime), vod.duration.duration()).durationString()
        
        let chatTime = self.isVideoEnd ? vod.duration.duration() + 100500 : Int(currentTime)
        self.chatController.handleVODsChat(forTime: chatTime)
        if !self.isVideoEnd {
          self.seekLabel.text = String(format: "%@ / %@", Int(currentTime).durationString(), vod.duration.duration().durationString())
        }
      } else {
        self.seekLabel.text = String(format: "%@", Int(currentTime).durationString())
      }
    }
  }
}
