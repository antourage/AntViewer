//
//  AntWidgetN.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 25.03.2020.
//

import ViewerExtension
import AVKit
import os.log

public enum WidgetLocale: String {
  case english = "en"
  case swedish = "sv"
}

public enum WidgetState {
  case resting
  case vod
  case live
  case loading(player: AVPlayer)

  var description: String {
    switch self {
    case .resting:
      return "resting"
    case .vod:
      return "vod"
    case .live:
      return "live"
    case .loading:
      return "loading"
    }
  }
}

public enum WidgetPosition: String {
  case topLeft, midLeft, bottomLeft
  case topMid, bottomMid
  case topRight, midRight, bottomRight
  
  var isLeft: Bool {
    self == .topLeft || self == .midLeft || self == .bottomLeft
  }
  
  var isRight: Bool {
    self == .topRight || self == .midRight || self == .bottomRight
  }
  
  var isTop: Bool {
    self == .topLeft || self == .topRight || self == .topMid
  }
  
  var isBottom: Bool {
    self == .bottomLeft || self == .bottomRight || self == .bottomMid
  }
  
  private var defaultVertical: CGFloat {
    switch self {
    case .midLeft, .midRight:
      return 0
    default:
      return 100
    }
  }
  private var defaultHorizontal: CGFloat {
    switch self {
    case .topMid, .bottomMid:
      return 0
    default:
      return 20
    }
  }
  private var maxVertical: CGFloat {
    switch self {
    case .midLeft, .midRight:
      return 0
    default:
      return 220
    }
  }
  private var maxHorizontal: CGFloat {
    switch self {
    case .topMid, .bottomMid:
      return 0
    default:
      return 50
    }
  }
  
  func validateMargins(_ margin: WidgetMargins?) -> WidgetMargins {
    guard let margin = margin else {
      return WidgetMargins(vertical: defaultVertical, horizontal: defaultHorizontal)
    }
    return WidgetMargins(vertical: min(margin.vertical, maxVertical), horizontal: min(margin.horizontal, maxHorizontal))
  }
  
  func getPointWith(margins: WidgetMargins?, for size: CGSize?) -> CGPoint {
    let screenSize = size ?? UIScreen.main.bounds.size
    let validMargins = validateMargins(margins)
    var x: CGFloat = 0
    var y: CGFloat = 0
    
    if isLeft {
      x = validMargins.horizontal
    } else if isRight {
      x = screenSize.width - width - validMargins.horizontal - 6 // badge
    } else {
      x = (screenSize.width - width)/2
    }
    
    if isTop {
      y = validMargins.vertical
    } else if isBottom {
      y = screenSize.height - width - validMargins.vertical
    } else {
      y = (screenSize.height - width)/2
    }
    return CGPoint(x: x, y: y)
  }
}

public struct WidgetMargins {
  public let vertical: CGFloat
  public let horizontal: CGFloat
  
  public init(vertical: CGFloat, horizontal: CGFloat) {
    self.vertical = max(0, vertical)
    self.horizontal = max(0, horizontal)
  }
}

private let width: CGFloat = 84

@objc
public class AntWidget: NSObject {
  
  @objc
  public static let shared = AntWidget()
  
  private var dataSource = DataSource()
  private var animationProcessing = false
  private var isBackground = false
  private var currentState = WidgetState.resting {
    didSet {
      if case .loading = currentState {
        animationProcessing = true
      }
      widgetView.prepare(for: currentState, completion: { state in
        print("Button state: \(state.description)")
        self.currentContent = self.preparedContent
        self.preparedContent = nil
        if case .loading = state {
          self.animationProcessing = false
        }
      })
    }
  }

  private var player: ModernAVPlayer?
  
  private var topConstraint: NSLayoutConstraint?
  private var leadingConstraint: NSLayoutConstraint?
  
  private lazy var widgetView: WidgetView = {
    let view = WidgetView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.heightAnchor.constraint(equalToConstant: width).isActive = true
    view.widthAnchor.constraint(equalToConstant: width).isActive = true
    view.backgroundColor = .clear
    view.delegate = self
    return view
  }()

  private var currentContent: VideoContent?
  private var preparedContent: VideoContent?
  private var visible = false
  private var feedShown = false
  private var failedPlaybackCount = 0
  private var failedPlaybackDebouncer = Debouncer(delay: 15)
  private var updateSizeDebouncer = Debouncer(delay: 0.1)
  
  private var position: WidgetPosition? {
    didSet {
      updatePosition()
    }
  }
  
  private var margins: WidgetMargins? {
    didSet {
      updatePosition()
    }
  }
  
  public var widgetLocale: WidgetLocale?
  
  public var widgetPosition: WidgetPosition {
    get {
      return position ?? .bottomRight
    }
    set {
      position = newValue
    }
  }
  
  public var widgetMargins: WidgetMargins {
    get {
      return margins ?? widgetPosition.validateMargins(nil)
    }
    set {
      margins = newValue
    }
  }
  @objc
  public var view: UIView { widgetView }
  @objc
  public var onViewerAppear: ((NSDictionary) -> Void)?
  @objc
  public var onViewerDisappear: ((NSDictionary) -> Void)?

  private override init() {
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(handleStreamUpdate(_:)), name: NSNotification.Name(rawValue: "StreamsUpdated"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleViewerDisappear(_:)), name: NSNotification.Name(rawValue: "ViewerWillDisappear"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleViewerAppear(_:)), name: NSNotification.Name(rawValue: "ViewerWillAppear"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    UIDevice.current.isBatteryMonitoringEnabled = true
    AppAuth.shared.auth()
    widgetView.prepare(for: .resting, completion: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  public static var AntSenderId = "1090288296965"

  @objc
  public static func authWith(apiKey: String, refUserId: String?, nickname: String?) {
    AntViewerManager.shared.authWith(apiKey: apiKey, refUserId: refUserId, nickname: nickname, completionHandler: {_ in })
  }

  public static func registerNotifications(FCMToken: String, completionHandler: @escaping (Result<String, Error>) -> Void) {
    AntViewerManager.shared.registerNotificationsWith(FCMToken: FCMToken, completionHandler: completionHandler)
  }

  @objc
  public static func objc_registerNotifications(FCMToken: String, completionHandler: @escaping (String?, Error?) -> Void) {
    AntViewerManager.shared.registerNotificationsWith(FCMToken: FCMToken) { (result) in
      switch result {
      case .success(let topic):
        completionHandler(topic, nil)
      case .failure(let error):
        completionHandler(nil, error)
      }
    }
  }

  @objc
  public func showFeed() {
    if feedShown { return }
    showFeed(with: nil, animated: false)
  }
  
  private func updatePosition(size: CGSize? = nil) {
    //MARK: superview.frame != .zero cause RN
    updateSizeDebouncer.call { [weak self] in
      guard let superview = self?.widgetView.superview, superview.frame != .zero else { return }
      let size = size ?? superview.frame.size
      let point = self?.widgetPosition.getPointWith(margins: self?.margins, for: size) ?? .zero
      self?.topConstraint?.constant = point.y
      self?.leadingConstraint?.constant = point.x
    }

  }

  private func set(state: WidgetState) {
    os_log("Trying to set state: %{public}@ ", log: OSLog.antButton, type: .info, state.description)
    switch currentState {
    case .resting:
      if case .resting = state { return }
      if case .live = state { return }
    case .vod:
      if case .vod = state {
        currentContent = preparedContent
        preparedContent = nil
        return
      }
    case .loading:
      if case .loading = state { return }
      if case .live = state { break }
      self.player?.stop()
      self.player = nil
    case .live:
      if case .live = state { return }
      if case .loading = state { break }
      self.player?.stop()
      self.player = nil
    }
    os_log("Setting state: %{public}@ ", log: OSLog.antButton, type: .info, state.description)
    currentState = state
  }

  private func showLive(with content: Live) {
    guard let url = URL(string: content.url) else { return }
    let media = ModernAVPlayerMedia(url: url, type: .stream(isLive: true))
    let player = ModernAVPlayer(config: AntourageAVPlayerConfiguration())
    player.delegate = self
    failedPlaybackCount = 0
    player.load(media: media, autostart: true)
    self.player = player
    player.player.isMuted = true
    set(state: .loading(player: player.player))
  }

  fileprivate func showFeed(with content: VideoContent?, animated: Bool = false) {
    func configureTransitionAnimation(inView view: UIView = self.view) {
      let transition = CATransition()
      transition.duration = 0.3
      transition.type = .push
      transition.subtype = .fromRight
      transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      view.window?.layer.add(transition, forKey: kCATransition)
    }
    
    guard let vc = view.findViewController() ?? UIApplication.getTopViewController() else {return}

    let listController = StreamListController(nibName: "StreamListController", bundle: Bundle(for: type(of: self)))
    listController.dataSource = dataSource
    let navController = NavigationController(rootViewController: listController)
    navController.modalPresentationStyle = .fullScreen
    if let stream = content {
      let playerVC = PlayerController(nibName: "PlayerController", bundle: Bundle(for: type(of: self)))
      playerVC.videoContent = stream
      playerVC.dataSource = dataSource
      navController.view.isHidden = true
      let controllerToPresent: UIViewController = currentContent is VOD ? PlayerNavigationController(rootViewController: playerVC) : playerVC
      controllerToPresent.modalPresentationStyle = .fullScreen
      vc.present(navController, animated: false, completion: {
        if animated {
          configureTransitionAnimation(inView: navController.view)
        }
        navController.present(controllerToPresent, animated: false, completion: {
          navController.view.isHidden = false
        })
      })
      return
    }
    if animated {
      configureTransitionAnimation()
    }
    vc.present(navController, animated: false, completion: nil)
  }

  @objc
  func handleStreamUpdate(_ notification: NSNotification) {
    let error = notification.userInfo?["error"]
    os_log("handleStreamUpdate", log: OSLog.antButton, type: .info)
    guard visible,
      !isBackground,
      error == nil else {
      os_log("Invalid handleStreamUpdate - isVisible: %{public}@, isBackground: %{public}@, error: %{public}@ ", log: OSLog.antButton, type: .info, "\(visible)", "\(isBackground)", error.debugDescription)
      set(state: .resting)
      return
    }
    if let stream = dataSource.streams.first {
      if currentContent?.id != stream.id, animationProcessing == false {
        preparedContent = stream
        showLive(with: stream)
      }
      return
    }
    preparedContent = nil
    if let vod = dataSource.newVod {
      preparedContent = vod
      set(state: .vod)
      return
    }
    set(state: .resting)
  }

  @objc
  func handleViewerDisappear(_ notification: NSNotification) {
    feedShown = false
    onViewerDisappear?([:])
  }
  
  @objc
  func handleViewerAppear(_ notification: NSNotification) {
    feedShown = true
    onViewerAppear?([:])
  }

  @objc
  func handleWillResignActive(_ notification: NSNotification) {
    guard visible else { return }
    isBackground = true
    currentContent = nil
    dataSource.pauseUpdatingVods()
    set(state: .resting)
  }

  @objc
  func handleDidBecomeActive(_ notification: NSNotification) {
    guard visible else { return }
    if isBackground {
      dataSource.startUpdatingVods()
    }
    isBackground = false
  }
  
  @objc
  func handleOrientationDidChange(_ notification: NSNotification) {
    updatePosition()
  }
}

extension AntWidget: WidgetViewDelegate {
  
  func widgetDidMoveToSuperview(_ widgetView: WidgetView, superview: UIView?) {
    guard let superview = superview else { return }
    let size = superview.frame.size
    let point = widgetPosition.getPointWith(margins: margins, for: size)
    if let topConstraint = topConstraint {
      widgetView.removeConstraint(topConstraint)
    }
    if let leadingConstraint = leadingConstraint {
      widgetView.removeConstraint(leadingConstraint)
    }
    topConstraint = widgetView.topAnchor.constraint(equalTo: superview.topAnchor, constant: point.y)
    topConstraint?.isActive = true
    leadingConstraint = widgetView.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: point.x)
    leadingConstraint?.isActive = true
    updatePosition(size: superview.bounds.size)
  }
  
  func widgetLayoutSubviews(_ widgetView: WidgetView) {
    updatePosition()
  }
  
  func widgetViewWillAppear(_ widgetView: WidgetView) {
    os_log("widgetViewWillAppear", log: OSLog.antButton, type: .info)
    currentContent = nil
    visible = true
    widgetView.isUserInteractionEnabled = true
    dataSource.startUpdatingVods()
  }

  func widgetViewWillDisappear(_ widgetView: WidgetView) {
    os_log("widgetViewWillDisappear", log: OSLog.antButton, type: .info)
    visible = false
    dataSource.pauseUpdatingVods()
    set(state: .resting)
  }

  func widgetViewDidPressButton(_ widgetView: WidgetView) {
    widgetView.isUserInteractionEnabled = false
    showFeed(with: currentContent, animated: true)
  }

}

extension AntWidget: ModernAVPlayerDelegate {
  public func modernAVPlayer(_ player: ModernAVPlayer, didStateChange state: ModernAVPlayer.State) {
    switch state {
    case .failed:
      failedPlaybackCount += 1
      if failedPlaybackCount > 2 {
        set(state: .resting)
      } else {
        player.play()
        failedPlaybackDebouncer.call { [weak self] in
          self?.failedPlaybackCount = 0
        }
      }
        
    default:
      return
    }
  }
  public func modernAVPlayer(_ player: ModernAVPlayer, didItemDurationChange itemDuration: Double?) {
    set(state: .live)
  }
}
