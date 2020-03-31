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
}

//TODO: make me a singleton
public class AntWidget {

  private static var dataSource: DataSource?
  private var animationProcessing = false
  private var currentState = WidgetState.resting {
    didSet {
      let value = currentState
      animationProcessing = true
      widgetView.prepare(for: value, completion: {
        self.animationProcessing = false
        if case .live = value { return }
        self.currentContent = self.preparedContent
        self.preparedContent = nil
      })
    }
  }
  private var player: AVPlayer?
  private lazy var widgetView: WidgetView = {
    let screenSize = UIScreen.main.bounds.size
    let width: CGFloat = 74
    let x = (screenSize.width - width)/2
    let y = screenSize.height - width - 80
    let rect = CGRect(x: x, y: y, width: width, height: width)
    let view = WidgetView(frame: rect)
    view.backgroundColor = .clear
    view.delegate = self
    return view
  }()

  private var currentContent: AntViewerExt.Stream?
  private var preparedContent: AntViewerExt.Stream?
  private var visible = false

  public var view: UIView { widgetView }
  @objc
  public var onViewerAppear: ((NSDictionary) -> Void)?
  @objc
  public var onViewerDisappear: ((NSDictionary) -> Void)?

  public init() {
    NotificationCenter.default.addObserver(self, selector: #selector(handleStreamUpdate(_:)), name: NSNotification.Name(rawValue: "StreamsUpdated"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleViewerDisappear(_:)), name: NSNotification.Name(rawValue: "ViewerWillDisappear"), object: nil)

    AppAuth.shared.auth()
    Statistic.sync()
    if AntWidget.dataSource == nil {
      AntWidget.dataSource = DataSource()
    }
    widgetView.prepare(for: .resting, completion: {})
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

  private func showLive(with content: AntViewerExt.Stream) {
    guard let url = URL(string: content.url) else { return }
    let player = AVPlayer(url: url)
    self.player = player
    player.isMuted = true
    currentState = .loading(player: player)
    player.play()
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
      self?.currentState = .live
    }
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
    guard visible, let dataSource = AntWidget.dataSource else {
      return
    }
    if case .loading = currentState { return }
    if let stream = dataSource.streams.last {
      if currentContent?.id != stream.id, animationProcessing == false {
        preparedContent = stream
        showLive(with: stream)
      }
      return
    }
    preparedContent = nil
    if dataSource.newVodsCount > 0 {
      if case .vod = currentState { return }
      currentState = .vod
      return
    }
    if case .resting = currentState { return }
    currentState = .resting
  }

  @objc
  func handleViewerDisappear(_ notification: NSNotification) {
    onViewerDisappear?([:])
  }
}

extension AntWidget: WidgetViewDelegate {
  func widgetViewWillAppear(_ widgetView: WidgetView) {
    visible = true
    widgetView.isUserInteractionEnabled = true
    AntWidget.dataSource?.startUpdatingVods()
  }

  func widgetViewWillDisappear(_ widgetView: WidgetView) {
    visible = false
    AntWidget.dataSource?.pauseUpdatingVods()
    currentState = .resting
  }

  func widgetViewDidPressButton(_ widgetView: WidgetView) {
    widgetView.isUserInteractionEnabled = false
    didTapButton()
  }

}
