

import UIKit


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
