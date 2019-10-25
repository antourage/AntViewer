# AntViewer

[![Version](https://img.shields.io/cocoapods/v/AntViewer.svg?style=flat)](https://cocoapods.org/pods/AntViewer)
[![License](https://img.shields.io/cocoapods/l/AntViewer.svg?style=flat)](https://cocoapods.org/pods/AntViewer)
[![Platform](https://img.shields.io/cocoapods/p/AntViewer.svg?style=flat)](https://cocoapods.org/pods/AntViewer)

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
### Push notifications (in progress...)

We use Firebase for PN in our project. To support PN on your side you should retrieve token for our senderID, send all needed data to us and subscribe yourself to our topic.
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
