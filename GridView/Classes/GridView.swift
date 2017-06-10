//
//  GridView.swift
//  ccggyy.com
//
//  Created by Chakery on 2017/6/10.
//
//
//

import UIKit

open class GridView: UIView {
    private var rects: [[CGRect]] = []
    private var enables: [[Bool]] = []
    private var texts: [[String]] = []
    private var colum: Int = 0
    private var row: Int = 0
    private var tap: UITapGestureRecognizer!
    private var pan: UIPanGestureRecognizer!
    
    private var startPoint: (row:Int, col:Int)!
    private var endPoint: (row:Int, col:Int)!
    private var fillMode: Bool!
    
    public enum Direction { case horizontal, vertical }
    
    public var itemSize: CGSize! { didSet{ setNeedsDisplay() } }
    public var direction: Direction = .horizontal { didSet{ setNeedsDisplay() } }
    
    public var didChangeCallback: (([[Bool]]) -> Void)?
    public var margin: CGFloat =  0.0 { didSet{ setNeedsDisplay(); invalidateIntrinsicContentSize() } }
    public var padding: CGFloat = 0.1 { didSet{ setNeedsDisplay(); invalidateIntrinsicContentSize() } }
    public var textColor = UIColor.white { didSet{ setNeedsDisplay() } }
    public var itemCornerRadius: CGFloat = 0.0 { didSet{ setNeedsDisplay() } }
    public var normalColor: UIColor = UIColor.lightGray { didSet{ setNeedsDisplay() } }
    public var selectedColor: UIColor = UIColor.brown { didSet{ setNeedsDisplay() } }
    public var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) { didSet{ setNeedsDisplay() } }
    
    public init(frame: CGRect = .zero, texts: [[String]]) {
        self.texts = texts
        super.init(frame: frame)
        setupParams()
        setupGesture()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let itemSize = getItemSize()
        let attributes = getAttributes()
        rects.removeAll()
        
        for i in 0 ..< row {
            var tempRects: [CGRect] = []
            for j in 0 ..< colum {
                let enable = enables[i][j]
                let text = texts[i][j]
                var h = i
                var v = j
                if direction == .vertical { (h, v) = (v , h) }
                let x = (CGFloat(v) * (itemSize.width + padding)) + margin
                let y = (CGFloat(h) * (itemSize.height + padding)) + margin
                let rect = CGRect(origin: CGPoint.init(x: x, y: y), size: itemSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: itemCornerRadius)
                context?.setFillColor(enable ? selectedColor.cgColor : normalColor.cgColor)
                path.fill()
                text.draw(in: rect, attributes: attributes)
                tempRects.append(rect)
            }
            rects.append(tempRects)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    private func setupParams() {
        guard texts.count > 0 else { return }
        guard let val = texts.first?.count, val > 0 else { return }
        row = texts.count
        colum = val
        enables = Array<Array<Bool>>(repeating: Array<Bool>(repeating: false, count: colum), count: row)
    }
    
    private func setupGesture() {
        tap = UITapGestureRecognizer(target: self, action: #selector(GridView.didTap(_:)))
        pan = UIPanGestureRecognizer(target: self, action: #selector(GridView.didPan(_:)))
        addGestureRecognizer(tap)
        addGestureRecognizer(pan)
    }
    
    @objc private func didTap(_ tap: UITapGestureRecognizer) {
        let point = tap.location(in: self)
        guard let position = findPosition(by: point, from: rects) else { return }
        let i = position.0
        let j = position.1
        guard i < enables.count else { return }
        guard let val = enables.first?.count, j < val else { return }
        enables[i][j] = !enables[i][j]
        setNeedsDisplay()
        didChangeCallback?(enables)
    }
    
    @objc private func didPan(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: self)
        guard let position = findPosition(by: point, from: rects) else { return }
        let i = position.0
        let j = position.1
        guard i < row, j < colum else { return }
        
        switch pan.state {
        case .began:
            fillMode = enables[i][j]
            startPoint = (i, j)
            endPoint = (i, j)
            
        case .changed:
            guard
                let startPoint = startPoint,
                let fillMode = fillMode
                else { return }
            
            if startPoint.row == i {
                let minIndex = min(startPoint.col, j)
                let maxIndex = max(startPoint.col, j)
                for index in minIndex ... maxIndex {
                    enables[i][index] = !fillMode
                }
            }
            
            if startPoint.col == j {
                let minIndex = min(startPoint.row, i)
                let maxIndex = max(startPoint.row, i)
                for index in minIndex ... maxIndex {
                    enables[index][j] = !fillMode
                }
            }
            
            setNeedsDisplay()
            
        case .failed:
            fallthrough
        case .cancelled:
            fallthrough
        case .ended:
            fillMode = nil
            startPoint = nil
            endPoint = nil
            
        default:
            break
        }
        
        didChangeCallback?(enables)
    }
    
    public func getItemSize() -> CGSize {
        if let itemSize = itemSize { return itemSize }
        guard colum > 0 else { return .zero }
        guard row > 0 else { return .zero }
        var w = (bounds.width - (margin * 2) - (CGFloat(colum - 1) * padding)) / CGFloat(colum)
        var h = (bounds.height - (margin * 2) - (CGFloat(row - 1) * padding)) / CGFloat(row)
        if direction == .vertical { (w, h) = (h, w) }
        return CGSize(width: w, height: h)
    }
    
    private func getAttributes() -> [String: Any] {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        return [NSFontAttributeName: font,
                NSForegroundColorAttributeName: textColor,
                NSParagraphStyleAttributeName: style]
    }
    
    /// 根据点击的坐标，获取对应二维数组的坐标
    private func findPosition(by point: CGPoint, from rects: [[CGRect]]) -> (Int, Int)? {
        guard rects.count > 0 else { return nil }
        for i in 0 ..< rects.count {
            for j in 0 ..< rects[i].count {
                if rects[i][j].contains(point) {
                    return (i, j)
                }
            }
        }
        return nil
    }
    
    open override var intrinsicContentSize: CGSize {
        if let itemSize = itemSize {
            var w = itemSize.width
            var h = itemSize.height
            
            if direction == .vertical {
                (w, h) = (h, w)
            }
            
            let maxW = margin * 2 + CGFloat(colum - 1) * padding + CGFloat(colum) * w
            let maxH = margin * 2 + CGFloat(row - 1) * padding + CGFloat(row) * h
            return CGSize(width: maxW, height: maxH)
        }
        return CGSize(width: UIViewNoIntrinsicMetric, height: UIViewNoIntrinsicMetric)
    }
}

private extension String {
    
    func draw(in rect: CGRect, attributes: [String: Any]) {
        let str = self as NSString
        let strSize = str.size(attributes: attributes)
        let strRect = CGRect(x: rect.origin.x,
                             y: rect.origin.y + (rect.size.height - strSize.height) * 0.5,
                             width: rect.size.width,
                             height: strSize.height)
        str.draw(in: strRect, withAttributes: attributes)
    }
    
}
