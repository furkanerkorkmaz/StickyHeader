//
//  UIScrollView+ParallaxHeader.swift
//  ParallaxHeader
//
//  Created by Roman Sorochak on 6/23/17.
//  Copyright © 2017 MagicLab. All rights reserved.
//

import ObjectiveC.runtime
import UIKit

/**
 A UIScrollView extension with a ParallaxHeader.
 */
extension UIScrollView {
    private enum AssociatedKeys {
        static var descriptiveName:String = "AssociatedKeys.DescriptiveName.parallaxHeader"
    }

    /**
     The parallax header.
     */
    public var parallaxHeader: ParallaxHeader {
        get {
            if let header = objc_getAssociatedObject(
                self,
                &AssociatedKeys.descriptiveName
            ) as? ParallaxHeader {
                return header
            }
            let header = ParallaxHeader()
            self.parallaxHeader = header
            return header
        }
        set(parallaxHeader) {
            parallaxHeader.scrollView = self
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.descriptiveName,
                parallaxHeader,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
extension UIView {
    /**
       Rotate a view by specified degrees
       parameter angle: angle in degrees
     */

    func rotate(angle: CGFloat) {
        let radians = angle / 180.0 * CGFloat.pi
        let rotation = CGAffineTransformRotate(self.transform, radians)
        self.transform = rotation
    }

    private struct AssociatedKeys {
        static var descriptiveName: String = "AssociatedKeys.DescriptiveName.blurView"
    }

    private(set) var blurView: BlurView {
        get {
            if let blurView = objc_getAssociatedObject(
                self,
                &AssociatedKeys.descriptiveName
            ) as? BlurView {
                return blurView
            }
            self.blurView = BlurView(to: self)
            return self.blurView
        }
        set(blurView) {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.descriptiveName,
                blurView,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    class BlurView {
        private var superview: UIView
        private var blur: UIVisualEffectView?
        private var editing = false
        private(set) var blurContentView: UIView?
        private(set) var vibrancyContentView: UIView?

        var animationDuration: TimeInterval = 0.1

        /**
         * Blur style. After it is changed all subviews on
         * blurContentView & vibrancyContentView will be deleted.
         */
        var style: UIBlurEffect.Style = .light {
            didSet {
                guard oldValue != style,
                      !editing else { return }
                applyBlurEffect()
            }
        }

        /**
         * Alpha component of view. It can be changed freely.
         */
        var alpha: CGFloat = 0 {
            didSet {
                guard !editing else { return }
                if blur == nil {
                    applyBlurEffect()
                }
                let alpha = self.alpha
                UIView.animate(withDuration: animationDuration) {
                    self.blur?.alpha = alpha
                }
            }
        }

        init(to view: UIView) {
            self.superview = view
        }

        func setup(style: UIBlurEffect.Style, alpha: CGFloat) -> Self {
            self.editing = true

            self.style = style
            self.alpha = alpha

            self.editing = false

            return self
        }

        func enable(isHidden: Bool = false) {
            if blur == nil {
                applyBlurEffect()
            }

            self.blur?.isHidden = isHidden
        }

        private func applyBlurEffect() {
            blur?.removeFromSuperview()

            applyBlurEffect(
                style: style,
                blurAlpha: alpha
            )
        }

        private func applyBlurEffect(
            style: UIBlurEffect.Style,
            blurAlpha: CGFloat
        ) {
            superview.backgroundColor = UIColor.clear

            let blurEffect = UIBlurEffect(style: style)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)

            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
            blurEffectView.contentView.addSubview(vibrancyView)

            blurEffectView.alpha = blurAlpha

            superview.insertSubview(blurEffectView, at: 0)

            blurEffectView.addAlignedConstrains()
            vibrancyView.addAlignedConstrains()

            self.blur = blurEffectView
            self.blurContentView = blurEffectView.contentView
            self.vibrancyContentView = vibrancyView.contentView
        }
    }

    private func addAlignedConstrains() {
        translatesAutoresizingMaskIntoConstraints = false
        addAlignConstraintToSuperview(attribute: NSLayoutConstraint.Attribute.top)
        addAlignConstraintToSuperview(attribute: NSLayoutConstraint.Attribute.leading)
        addAlignConstraintToSuperview(attribute: NSLayoutConstraint.Attribute.trailing)
        addAlignConstraintToSuperview(attribute: NSLayoutConstraint.Attribute.bottom)
    }

    private func addAlignConstraintToSuperview(attribute: NSLayoutConstraint.Attribute) {
        superview?.addConstraint(
            NSLayoutConstraint(
                item: self,
                attribute: attribute,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: superview,
                attribute: attribute,
                multiplier: 1,
                constant: 0
            )
        )
    }
}
