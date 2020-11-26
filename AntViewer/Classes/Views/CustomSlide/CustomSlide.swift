

import UIKit
import ViewerExtension


class CustomSlide: UISlider {

@IBInspectable var trackHeight: CGFloat = 4 {
  didSet { setNeedsDisplay() }
}



override func trackRect(forBounds bounds: CGRect) -> CGRect {
  //set your bounds here

  let defaultBounds = super.trackRect(forBounds: bounds)
  let rect = CGRect(
      x: defaultBounds.origin.x,
      y: (bounds.height / 2) - (trackHeight / 2),
      width: defaultBounds.size.width,
      height: trackHeight
  )
  return rect
  

}
}

extension CustomSlide {
  func createAndSetMaxTrackImage(for videoContent: VideoContent) {
    let backgroundColor = UIColor.white.withAlphaComponent(0.6)
    let width: CGFloat = 1200
    let imageSize = CGSize(width: width, height: trackHeight)
    UIGraphicsBeginImageContext(imageSize)
    backgroundColor.setFill()
    UIRectFill(CGRect(origin: .zero, size: imageSize))
    guard let content = videoContent as? VOD  else {
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      setMaximumTrackImage(newImage ?? UIImage(), for: .normal)
      return
    }
    
    let context = UIGraphicsGetCurrentContext()!
    let videoDuration = Double(content.duration.duration())
    
//    let colors = [0, 1, 1, 0].map({ UIColor.curtainYellow.withAlphaComponent($0).cgColor})
//    let colorSpace = CGColorSpaceCreateDeviceRGB()
//    let colorLocations: [CGFloat] = [0.0, 0.25, 0.75, 1.0]
    UIColor.curtainYellow.setFill()
//    guard let gradient = CGGradient(
//      colorsSpace: colorSpace,
//      colors: colors as CFArray,
//      locations: colorLocations
//    ) else {
//      fatalError()
//    }
    
    for curtain in content.curtainRangeModels {
      var cur = curtain
      let lowerBoudn = cur.range.lowerBound
      let upperBoudn = cur.range.upperBound
      
      let origin = CGPoint(x: CGFloat(lowerBoudn/videoDuration)*width, y: 0)
      let size = CGSize(width: CGFloat(upperBoudn/videoDuration)*width - origin.x, height: imageSize.height)
//      context.drawLinearGradient(
//        gradient,
//        start: CGPoint(x: origin.x, y: 0),
//        end: CGPoint(x: origin.x + size.width, y: 0),
//        options: []
//      )
      context.fill(CGRect(origin: origin, size: size))

    }
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    setMaximumTrackImage(newImage ?? UIImage(), for: .normal)
  }
}
