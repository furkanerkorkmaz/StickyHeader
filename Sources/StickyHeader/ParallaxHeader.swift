//
//  ParallaxHeader.swift
//  ParallaxHeader
//
//  Created by Roman Sorochak on 6/22/17.
//  Copyright © 2017 MagicLab. All rights reserved.
//

import ObjectiveC.runtime
import UIKit

public typealias ParallaxHeaderHandlerBlock = (_ parallaxHeader: ParallaxHeader) -> Void

private let parallaxHeaderKVOContext = UnsafeMutableRawPointer.allocate(
    byteCount: 4,
    alignment: 1
)

// MARK: - ParallaxView

class ParallaxView: UIView {
    fileprivate weak var parent: ParallaxHeader!

    override func willMove(toSuperview _: UIView?) {
        guard let scrollView = superview as? UIScrollView else {
            return
        }
        scrollView.removeObserver(
            parent,
            forKeyPath: NSStringFromSelector(
                #selector(getter: scrollView.contentOffset)
            ),
            context: parallaxHeaderKVOContext
        )
    }

    override func didMoveToSuperview() {
        guard let scrollView = superview as? UIScrollView else {
            return
        }
        scrollView.addObserver(
            parent,
            forKeyPath: NSStringFromSelector(
                #selector(getter: scrollView.contentOffset)
            ),
            options: NSKeyValueObservingOptions.new,
            context: parallaxHeaderKVOContext
        )
    }
}

// MARK: - ParallaxHeader

public class ParallaxHeader: NSObject {
    // MARK: properties

    /**
     Block to handle parallax header scrolling.
     */
    public var parallaxHeaderDidScrollHandler: ParallaxHeaderHandlerBlock?

    private weak var _scrollView: UIScrollView?
    var scrollView: UIScrollView! {
        get {
            _scrollView
        }
        set(scrollView) {
            guard let scrollView = scrollView,
                  scrollView != _scrollView
            else {
                return
            }
            _scrollView = scrollView

            adjustScrollViewTopInset(
                top: scrollView.contentInset.top + height
            )
            scrollView.addSubview(contentView)

            layoutContentView()
        }
    }

    /**
     The content view on top of the UIScrollView's content.
     */
    private var _contentView: UIView?
    var contentView: UIView {
        if let contentView = _contentView {
            return contentView
        }
        let contentView = ParallaxView()
        contentView.parent = self
        contentView.clipsToBounds = true

        _contentView = contentView

        return contentView
    }

    /**
     The header's view.
     */
    private var _view: UIView?
    public var view: UIView {
        get {
            _view!
        }
        set(view) {
            guard _view != view else {
                return
            }
            _view = view
            updateConstraints()
        }
    }

    /**
     The parallax header behavior mode. By default is fill mode.
     */
    private var _mode: ParallaxHeaderMode = .fill
    public var mode: ParallaxHeaderMode {
        get {
            _mode
        }
        set(mode) {
            guard _mode != mode else {
                return
            }
            _mode = mode
            updateConstraints()
        }
    }

    /**
     The header's default height. 0 0 by default.
     */
    private var _height: CGFloat = 0
    public var height: CGFloat {
        get {
            _height
        }
        set(height) {
            guard _height != height,
                  let scrollView = scrollView
            else {
                return
            }
            adjustScrollViewTopInset(
                top: scrollView.contentInset.top - _height + height
            )

            _height = height

            updateConstraints()
            layoutContentView()
        }
    }

    /**
     The header's minimum height while scrolling up. 0 by default.
     */
    public var minimumHeight: CGFloat = 0 {
        didSet {
            layoutContentView()
        }
    }

    /**
     The parallax header progress value.
     */
    private var _progress: CGFloat = 0
    public var progress: CGFloat {
        get {
            _progress
        }
        set(progress) {
            guard _progress != progress else {
                return
            }
            _progress = progress

            parallaxHeaderDidScrollHandler?(self)
        }
    }

    // MARK: constraints

    private func updateConstraints(update: Bool = false) {
        if !update {
            view.removeFromSuperview()
            contentView.addSubview(view)

            view.translatesAutoresizingMaskIntoConstraints = false
        }

        switch mode {
        case .fill:
            setFillModeConstraints()

        case .top:
            setTopModeConstraints()

        case .topFill:
            setTopFillModeConstraints()

        case .center:
            setCenterModeConstraints()

        case .centerFill:
            setCenterFillModeConstraints()

        case .bottom:
            setBottomModeConstraints()

        case .bottomFill:
            setBottomFillModeConstraints()

        case .bottomAndTopFill:
            setBottomAndModeConstraints()
        }
    }

    private func setFillModeConstraints() {
        view.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
    }

    private func setTopModeConstraints() {
        view.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.left.right.equalToSuperview()
            make.height.equalTo(height)
        }
    }

    private func setTopFillModeConstraints() {
        view.snp.makeConstraints { make in
            make.top.equalTo(contentView).priority(.high)
            make.left.right.equalToSuperview()
            make.height.greaterThanOrEqualTo(height)
            make.bottom.equalToSuperview().priority(.high)
        }
    }

    private func setCenterModeConstraints() {
        view.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.lessThanOrEqualTo(contentView)
        }
    }

    private func setCenterFillModeConstraints() {
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets.zero).priority(.high)
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.greaterThanOrEqualTo(height).priority(.high)
        }
    }

    private func setBottomModeConstraints() {
        view.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(height)
        }
    }

    private func setBottomFillModeConstraints() {
        view.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(contentView.snp.bottom).offset(0.0).priority(.high)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.greaterThanOrEqualTo(height)
        }
    }

    private func setBottomAndModeConstraints() {
        view.snp.makeConstraints { make in
            make.top.equalTo(contentView).priority(.high)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(height)
        }
    }

    // MARK: private

    private func layoutContentView() {
        guard let scrollView = scrollView else {
            return
        }
        let minimumHeight = min(self.minimumHeight, height)
        let relativeYOffset = scrollView.contentOffset.y + scrollView.contentInset.top - height
//        if #available(iOS 11.0, *) {
//            relativeYOffset += scrollView.safeAreaInsets.top
//        }
        let relativeHeight = -relativeYOffset

        let frame = CGRect(
            x: 0,
            y: relativeYOffset,
            width: scrollView.frame.size.width,
            height: max(relativeHeight, minimumHeight)
        )
        contentView.frame = frame

        let div = height - self.minimumHeight
        progress = (contentView.frame.size.height - self.minimumHeight) / div
    }

    private func adjustScrollViewTopInset(top: CGFloat) {
        guard let scrollView = scrollView else {
            return
        }
        var inset = scrollView.contentInset

        // Adjust content offset
        var offset = scrollView.contentOffset
        offset.y += inset.top - top
        scrollView.contentOffset = offset

        // Adjust content inset
        inset.top = top
        scrollView.contentInset = inset
    }

    // MARK: KVO

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == parallaxHeaderKVOContext,
              let scrollView = scrollView
        else {
            super.observeValue(
                forKeyPath: keyPath,
                of: object,
                change: change,
                context: context
            )
            return
        }
        if keyPath == NSStringFromSelector(#selector(getter: scrollView.contentOffset)) {
            layoutContentView()
        }
    }
}
