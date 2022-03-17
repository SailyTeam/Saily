//
//  CSTextView.swift
//  Sileo
//
//  Created by CoolStar on 2/29/20.
//  Copyright © 2020 CoolStar. All rights reserved.
//

import UIKit

internal protocol CSTextViewActionHandler {
    func process(action: String) -> Bool
}

internal class CSTextView: UIView, CSTextViewActionHandler {
    public var attributedText: NSAttributedString? {
        set {
            renderView.attributedText = newValue
        }
        get {
            renderView.attributedText
        }
    }

    var renderView: CSTextRenderView
    public private(set) var overlayView: UIView

    override init(frame: CGRect) {
        renderView = CSTextRenderView(frame: CGRect(origin: .zero, size: frame.size))
        overlayView = UIView(frame: .zero)

        super.init(frame: frame)
        renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(renderView)

        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.25)
        addSubview(overlayView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        renderView.setNeedsDisplay()
    }

    override var backgroundColor: UIColor? {
        didSet {
            renderView.backgroundColor = backgroundColor
        }
    }

    func process(action: String) -> Bool {
        let superview = superview as? CSTextViewActionHandler
        return superview?.process(action: action) ?? false
    }
}

internal class CSTextRenderView: UIView {
    private var links: [[String: Any]] = []
    private var linkActive: Bool = false
    private var activeLink: [String: Any] = [:]
    private var activeLinkRect: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var attributedText: NSAttributedString? {
        didSet {
            self.isAccessibilityElement = true
            self.accessibilityLabel = self.attributedText?.string
            self.accessibilityTraits = .staticText
        }
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }

        links = []

        guard let attributedText = attributedText else {
            return
        }

        ctx.textMatrix = .identity
        ctx.translateBy(x: 0, y: rect.size.height)
        ctx.scaleBy(x: 1, y: -1)

        let path = UIBezierPath(rect: rect).cgPath

        let framesetter = CTFramesetterCreateWithAttributedString(attributedText as CFAttributedString)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: attributedText.length), path, nil)
        CTFrameDraw(frame, ctx)

        let lines = CTFrameGetLines(frame) as? [CTLine]

        // Get the origin point of each of the lines
        var origins = [CGPoint](repeating: .zero, count: lines?.count ?? 0)
        CTFrameGetLineOrigins(frame, CFRange(), &origins)

        var idx = 0
        for line in lines ?? [] {
            // For each line, get the bounds for the line
            guard let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun] else {
                idx += 1
                continue
            }
            // Go through the glyph runs in the line
            for run in glyphRuns {
                let attributes = CTRunGetAttributes(run) as? [NSAttributedString.Key: Any]
                if let url = attributes?[.link] {
                    var ascent: CGFloat = 0
                    var descent: CGFloat = 0
                    var runBounds = CGRect.zero
                    runBounds.size.width = CGFloat(CTRunGetTypographicBounds(run, CFRange(), &ascent, &descent, nil))
                    runBounds.size.height = ascent + descent

                    // The bounds returned by the Core Text function are in the coordinate system used by Core Text.  Convert the values here into the coordinate system which our gesture recognizers will use.
                    runBounds.origin.x = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
                    runBounds.origin.y = self.frame.height - origins[idx].y - runBounds.height

                    links.append(["bounds": NSCoder.string(for: runBounds),
                                  "url": url])
                }
            }
            idx += 1
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        if touches.count > 1 {
            return
        }

        guard let touch = touches.first else {
            return
        }
        let loc = touch.location(in: self)

        let textView = superview as? CSTextView

        for link in links {
            guard let boundsStr = link["bounds"] as? String else {
                return
            }

            let bounds = NSCoder.cgRect(for: boundsStr)
            if bounds.contains(loc) {
                linkActive = true
                activeLink = link
                activeLinkRect = bounds

                textView?.overlayView.isHidden = false
                textView?.overlayView.frame = activeLinkRect
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 {
            return
        }

        guard let touch = touches.first else {
            return
        }

        let loc = touch.location(in: self)
        if !activeLinkRect.contains(loc) {
            touchesCancelled(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 {
            return
        }

        guard let touch = touches.first else {
            return
        }

        let loc = touch.location(in: self)
        if !activeLinkRect.contains(loc) {
            touchesCancelled(touches, with: event)
        } else {
            let textView = superview as? CSTextView
            textView?.overlayView.isHidden = true
            textView?.overlayView.frame = .zero

            if let url = activeLink["url"] as? URL {
                _ = textView?.process(action: url.absoluteString)
            } else if let str = activeLink["url"] as? String, let url = URL(string: str) {
                _ = textView?.process(action: url.absoluteString)
            }

            linkActive = false
            activeLink = [:]
            activeLinkRect = .zero
        }
    }

    override func touchesCancelled(_: Set<UITouch>, with _: UIEvent?) {
        linkActive = false
        activeLink = [:]
        activeLinkRect = .zero

        let textView = superview as? CSTextView
        textView?.overlayView.isHidden = true
        textView?.overlayView.frame = .zero
    }
}
