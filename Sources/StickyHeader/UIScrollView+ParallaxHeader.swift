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
