//
//  AntWidgetN.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 25.03.2020.
//

import AntViewerExt
import AVKit

enum WidgetState {
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

public class AntWidget {
  public static let shared = AntWidget()
  private static var dataSource: DataSource?
  private var animationProcessing = false
  private var isBackground = false
  private var currentState = WidgetState.resting {
    didSet {
      if case .loading = currentState {
        animationProcessing = true
      }
      widgetView.prepare(for: currentState, completion: { state in
        print(state.description)
        self.currentContent = self.preparedContent
        self.preparedContent = nil
        if case .loading = state {
          self.animationProcessing = false
        }
      })
    }
  }

  private var player: ModernAVPlayer?
  private lazy var widgetView: WidgetView = {
    let screenSize = UIScreen.main.bounds.size
    let width: CGFloat = screenSize.width * 0.225
    let x = (screenSize.width - width)/2
    let y = screenSize.height - width - 80
    let rect = CGRect(x: x, y: y, width: width, height: width)
    let view = WidgetView(frame: rect)
    view.backgroundColor = .clear
    view.delegate = self
    return view
  }()

  private var currentContent: VideoContent?
  private var preparedContent: VideoContent?
  private var visible = false

  public var view: UIView { widgetView }
  @objc
  public var onViewerAppear: ((NSDictionary) -> Void)?
  @objc
  public var onViewerDisappear: ((NSDictionary) -> Void)?

  private init() {
    NotificationCenter.default.addObserver(self, selector: #selector(handleStreamUpdate(_:)), name: NSNotification.Name(rawValue: "StreamsUpdated"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleViewerDisappear(_:)), name: NSNotification.Name(rawValue: "ViewerWillDisappear"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)

    AppAuth.shared.auth()
    Statistic.sync()
    if AntWidget.dataSource == nil {
      AntWidget.dataSource = DataSource()
    }
    widgetView.prepare(for: .resting, completion: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  public static var AntSenderId = "1090288296965"

  public static func authWith(apiKey: String, refUserId: String?, nickname: String?, completionHandler: @escaping (Result<Void, Error>) -> Void) {
    AntViewerManager.shared.authWith(apiKey: apiKey, refUserId: refUserId, nickname: nickname, completionHandler: completionHandler)
  }

  public static func registerNotifications(FCMToken: String, completionHandler: @escaping (Result<String, Error>) -> Void) {
    AntViewerManager.shared.registerNotificationsWith(FCMToken: FCMToken, completionHandler: completionHandler)
  }

  @objc
  public static func objc_authWith(apiKey: String, refUserId: String?, nickname: String?, completionHandler: @escaping (Error?) -> Void) {
    AntViewerManager.shared.authWith(
      apiKey: apiKey,
      refUserId: refUserId,
      nickname: nickname) { (result) in
        switch result {
        case .success():
          completionHandler(nil)
        case .failure(let error):
          completionHandler(error)
        }
    }
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
  public static func getListController() -> UIViewController {
    AppAuth.shared.auth()
    Statistic.sync()

    let listController = StreamListController(nibName: "StreamListController", bundle: Bundle(for: AntWidget.self))
    if AntWidget.dataSource == nil {
      AntWidget.dataSource = DataSource()
    }
    listController.dataSource = AntWidget.dataSource

    let navController = NavigationController(rootViewController: listController)
    navController.modalPresentationStyle = .fullScreen
    return navController
  }

  @objc
  public static func getListController(withDismissCallback callback: @escaping (NSDictionary) -> Void) -> UIViewController {
    let navController = AntWidget.getListController() as! NavigationController
    let listController = navController.viewControllers.first as! StreamListController
    listController.onViewerDismiss = callback
    return navController
  }

  private func set(state: WidgetState) {
    switch currentState {
    case .resting:
      if case .resting = state { return }
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
    currentState = state
  }

  private func showLive(with content: Live) {
    guard let url = URL(string: content.url) else { return }
    let media = ModernAVPlayerMedia(url: url, type: .stream(isLive: true))
    let player = ModernAVPlayer()
    player.delegate = self
    player.load(media: media, autostart: true)
    self.player = player
    player.player.isMuted = true
    set(state: .loading(player: player.player))
  }

  private func didTapButton() {
    guard let vc = view.findViewController() else {return}
    onViewerAppear?([:])

    let listController = StreamListController(nibName: "StreamListController", bundle: Bundle(for: type(of: self)))
    listController.dataSource = AntWidget.dataSource
    let navController = NavigationController(rootViewController: listController)
    navController.modalPresentationStyle = .fullScreen
    if let stream = currentContent {
      let playerVC = PlayerController(nibName: "PlayerController", bundle: Bundle(for: type(of: self)))
      playerVC.videoContent = stream
      playerVC.dataSource = AntWidget.dataSource
      playerVC.modalPresentationStyle = .fullScreen
      navController.view.isHidden = true
      vc.present(navController, animated: false, completion: nil)
      navController.present(playerVC, animated: true, completion: {
        navController.view.isHidden = false
      })
      return
    }
    vc.present(navController, animated: true, completion: nil)
  }

  @objc
  func handleStreamUpdate(_ notification: NSNotification) {
    let error = notification.userInfo?["error"]
    guard visible,
      !isBackground,
      error == nil,
      let dataSource = AntWidget.dataSource else {
      set(state: .resting)
      return
    }
    if let stream = dataSource.streams.last {
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
    onViewerDisappear?([:])
  }

  @objc
  func handleWillResignActive(_ notification: NSNotification) {
    isBackground = true
    AntWidget.dataSource?.pauseUpdatingVods()
    set(state: .resting)
  }

  @objc
  func handleDidBecomeActive(_ notification: NSNotification) {
    isBackground = false
    AntWidget.dataSource?.startUpdatingVods()
  }
}

extension AntWidget: WidgetViewDelegate {
  func widgetViewWillAppear(_ widgetView: WidgetView) {
    currentContent = nil
    visible = true
    widgetView.isUserInteractionEnabled = true
    AntWidget.dataSource?.startUpdatingVods()
  }

  func widgetViewWillDisappear(_ widgetView: WidgetView) {
    visible = false
    AntWidget.dataSource?.pauseUpdatingVods()
    set(state: .resting)
  }

  func widgetViewDidPressButton(_ widgetView: WidgetView) {
    widgetView.isUserInteractionEnabled = false
    didTapButton()
  }

}

extension AntWidget: ModernAVPlayerDelegate {
  public func modernAVPlayer(_ player: ModernAVPlayer, didStateChange state: ModernAVPlayer.State) {
    switch state {
    case .failed:
        set(state: .resting)
    default:
      return
    }
  }
  public func modernAVPlayer(_ player: ModernAVPlayer, didItemDurationChange itemDuration: Double?) {
    set(state: .live)
  }
}
