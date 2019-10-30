# Antourage Widget SDK

[![Version](https://img.shields.io/cocoapods/v/AntViewer.svg?style=flat)](https://cocoapods.org/pods/AntViewer)
[![License](https://img.shields.io/cocoapods/l/AntViewer.svg?style=flat)](https://cocoapods.org/pods/AntViewer)
[![Platform](https://img.shields.io/cocoapods/p/AntViewer.svg?style=flat)](https://cocoapods.org/pods/AntViewer)

## Functional Description

The Antourage Widget is designed to work as a self-contained ‘widget’ within a host app. It shows live broadcasts and on-demand videos which have been captured by our mobile Broadcaster application. Antourage is mobile first and designed for the creation and viewing of realtime and near realtime micro-content.

### Magnetic Button

The entry point for a user is the magnetic button that appears on the host app, usually on the main screen.

When a video is live, the button changes state and shows the title of the broadcast, and the name of the broadcaster. If the user taps the button at this point, they are taken directly to the live broadcast.

<img src="/screenshots/widget_Live.jpeg" alt="Screenshots" width="200" />

When no video is live, the button shows how many on-demand videos the viewer has not yet watched. If they tap the button at this point, they are taken to the main view:

<img src="/screenshots/list_VOD_new.jpeg" alt="Screenshots" width="200" />

### Viewing Live Broadcasts

The video player may be used in portrait or landscape mode. In both modes, the viewer can watch the broadcast, see and contribute to comments, and see and respond to polls.

<div>
  <img src="/screenshots/player_portrait.jpeg" alt="Screenshots" width="200" />
  <img src="/screenshots/landscape_poll_chat.jpeg" alt="Screenshots" width="400" />
</div>

### Viewing On-demand videos

When the user taps on a video, the video begins playing at the beginning, or if this video has already been partially viewed, it will begin playing at the last point the viewer watched. The Antourage Widget keeps track of which videos the user has seen, and updates the number on the magnetic button accordingly.

Each video shows the name of the video, name of the broadcaster, total time, and total view count.

### Display Name

In order to contribute to the comments, a user must have an identity in our system, as well as a Display Name that shows in the comments stream. Since not all host apps require a username, we ask users to create a Display Name the first time they try to chat. If the host app does require users to create a username, we can turn off this feature.

### Comments

Comments are contributed by viewers of the live broadcast only. When a video is being watched later, these comments may be displayed, but cannot be added to. The broadcaster has the ability to review comments on a video and delete ones that they deem to be unacceptable. Antourage administration also has this ability.

### Polls

Polls are created by the broadcaster, and sent out during a live broadcast. They appear on the screen when they are first pushed out to the audience, and viewers can respond or simply close the poll if they do not want to answer. If they answer, they are shown the results right away, and they can see updated results as they come in.

<img src="/screenshots/poll_opened.jpeg" alt="Screenshots" width="200" />

### Curation

Content can only be created by those who have been actively selected by our customers to broadcast, and broadcasters can remove their own content from view at any time. Each customer designates a time period for the storage and display of their content — usually between 2 weeks and 6 weeks. After the storage period is over, content is automatically removed. These three elements together — actively selected creators, video removal, and video aging — ensure that the viewers get a consistent experience of interesting and fresh content.


### Third Party Technology

To support our functionality, we use a few third-party services and applications.   
Firebase: used for push notifications, comments and polls.   
Amazon Media Live: used for streaming and hosting our content

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 11.3 +

## Installation

AntViewer_ios is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:
`pod 'AntViewer'`.
And run `$ pod install`

## Plist entries

In order for your app to access camera,
you'll need to ad these `plist entries` :

- Privacy - Camera Usage Description (photo/videos)

```xml
<key>NSCameraUsageDescription</key>
<string>yourWording</string>
```

## Usage

### Auth

It's static method (no need object init), you can use it anywhere you want (login/app start etc).

```swift
AntWidget.authWith(apiKey: "put_your_apiKey_there", refUserId: "put_user_id_from_your_base_or_nil", nickname: "put_user_nickname_from_your_base_or_nil") { result in
  switch result {
  case .success:
    break
  case .failure(let error):
    print(error)
  }
}
```
### Push notifications 

We use Firebase for PN in our project. To support PN on your side you should retrieve token for our senderID, send all needed data to us right after successful auth (you can call it in auth success block) and subscribe yourself to our topic.   
senderID = 1090288296965

```swift
  //MARK: Connect PN to Antourage Firebase app
  Messaging.messaging().retrieveFCMToken(forSenderID: "1090288296965") { (token, error) in
    AntWidget.registerNotifications(FCMToken: token) { (result) in
      //MARK: Handle result
    }
  }

  Messaging.messaging().subscribe(toTopic: "topicName")
```
### Add UI part

Programmatically:
```swift
class ViewController: UIViewController {

  var widget: AntWidget! {
    didSet {
      view.addSubview(widget)
      widget.bottomMargin = 30
      widget.rightMargin = 40
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    widget = AntWidget()
    widget.onViewerAppear = { [weak self] _ in
      self?.changeSomething()
    }
  }
}
```
Or by interface builder:
Just add UIView, type AntWidget to class field, link to outlet. Thats all.



| Property          | Type     | Description                                                            |
|-------------------|----------|------------------------------------------------------------------------|
| isLightMode       | Bool     | There are two widget appearance modes: light & dark. By default false. |
| bottomMargin      | Int   | Bottom margin. Default: 20.                                            |
| rightMargin       | Int   | Right margin. Default: 20.                                             |
| onViewerAppear    | Closure | Called when the user opens the widget controller.                      |
| onViewerDisappear | Closure | Called when the user dismisses the widget controller.                  |


## Author

Mykola Vaniurskyi, mv@leobit.com

## License

AntViewer is available under the MIT license. See the LICENSE file for more info.
