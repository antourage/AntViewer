//
//  PlayerNavigationController.swift
//  AntViewer_ios
//
//  Created by Mykola Vaniurskyi on 16.10.2019.
//

import Foundation

class PlayerNavigationController: UINavigationController {
  
  var transitionCoordinatorHelper: TransitionCoordinator?

  override func viewDidLoad() {
    super.viewDidLoad()
    commonInit()
  }
  

  func commonInit() {
    setNavigationBarHidden(true, animated: false)
    let edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
    edgeSwipeGestureRecognizer.edges = .left
//    view.addGestureRecognizer(edgeSwipeGestureRecognizer)
    transitionCoordinatorHelper = TransitionCoordinator()
    delegate = transitionCoordinatorHelper
    self.view.backgroundColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)
  }
  
  func pushViewController(_ viewController: UIViewController, withPopAnimation: Bool = false) {
    transitionCoordinatorHelper?.popAnimation = withPopAnimation
    pushViewController(viewController, animated: true)
    viewControllers.removeFirst()
  }

  @objc func handleSwipe(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
    guard let delegate = delegate as? TransitionCoordinator else { return }
      guard let gestureRecognizerView = gestureRecognizer.view else {
          delegate.interactionController = nil
          return
      }

      let percent = gestureRecognizer.translation(in: gestureRecognizerView).x / gestureRecognizerView.bounds.size.width

      if gestureRecognizer.state == .began {
          delegate.interactionController = UIPercentDrivenInteractiveTransition()
          popViewController(animated: true)
      } else if gestureRecognizer.state == .changed {
          delegate.interactionController?.update(percent)
      } else if gestureRecognizer.state == .ended {
          if percent > 0.5 && gestureRecognizer.state != .cancelled {
              delegate.interactionController?.finish()
          } else {
              delegate.interactionController?.cancel()
          }
          delegate.interactionController = nil
      }
  }
  
}

final class TransitionCoordinator: NSObject, UINavigationControllerDelegate {
    
  var interactionController: UIPercentDrivenInteractiveTransition?
  
  var popAnimation: Bool = false

  func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            return TransitionAnimator(presenting: !popAnimation)
        default:
            return nil
        }
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
}

final class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let presenting: Bool

    init(presenting: Bool) {
        self.presenting = presenting
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
      return TimeInterval(UINavigationController.hideShowBarDuration)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        guard let toView = transitionContext.view(forKey: .to) else { return }

        let duration = transitionDuration(using: transitionContext)
        let container = transitionContext.containerView
        if presenting {
            container.addSubview(toView)
        } else {
            container.insertSubview(toView, belowSubview: fromView)
        }

        let toViewFrame = toView.frame
        toView.frame = CGRect(x: presenting ? toView.frame.width : -toView.frame.width, y: toView.frame.origin.y, width: toView.frame.width, height: toView.frame.height)

        let animations = {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                toView.alpha = 1
                if self.presenting {
                    fromView.alpha = 0
                }
            }

            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                toView.frame = toViewFrame
                fromView.frame = CGRect(x: self.presenting ? -fromView.frame.width : fromView.frame.width, y: fromView.frame.origin.y, width: fromView.frame.width, height: fromView.frame.height)
                if !self.presenting {
                    fromView.alpha = 0
                }
            }

        }

        UIView.animateKeyframes(withDuration: duration,
                                delay: 0,
                                options: .calculationModeCubic,
                                animations: animations,
                                completion: { finished in
                                    // 8
                                    container.addSubview(toView)
                                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
