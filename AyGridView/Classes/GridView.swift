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
    
    /// 布局方向
    public enum Direction {
        case horizontal
        case vertical
    }
    
    /// 空盒子模型
    public struct EmptyBox {
        // 开始点（对应二维数组的坐标）
        public var start: (Int, Int)
        // 结束点（对应二维数组的坐标）
        public var end: (Int, Int)
        
        public init(start: (Int, Int), end: (Int, Int)) {
            self.start = start
            self.end = end
        }
    }
    
    // item大小
    public var itemSize: CGSize! { didSet{ setNeedsDisplay() } }
    // 布局方向
    public var direction: Direction = .horizontal { didSet{ setNeedsDisplay() } }
    //改变时的回调
    public var didChangeCallback: (([[Bool]]) -> Void)?
    // 外边距
    public var margin: CGFloat =  0.0 { didSet{ setNeedsDisplay(); invalidateIntrinsicContentSize() } }
    // 内边距
    public var padding: CGFloat = 0.1 { didSet{ setNeedsDisplay(); invalidateIntrinsicContentSize() } }
    // 文本颜色
    public var textColor = UIColor.white { didSet{ setNeedsDisplay() } }
    // item圆角
    public var itemCornerRadius: CGFloat = 0.0 { didSet{ setNeedsDisplay() } }
    // 常规颜色
    public var normalColor: UIColor = UIColor.lightGray { didSet{ setNeedsDisplay() } }
    // 选中后的颜色
    public var selectedColor: UIColor = UIColor.brown { didSet{ setNeedsDisplay() } }
    // 字体
    public var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) { didSet{ setNeedsDisplay() } }
    
    // 是否需要虚线边框
    public var isDotted: Bool = true { didSet{ setNeedsDisplay() } }
    // 边框大小
    public var borderSize: CGFloat = 1.0 { didSet{ setNeedsDisplay() } }
    // 虚线的大小
    public var lineDashPattern: [CGFloat] = [3, 3] { didSet{ setNeedsDisplay() } }
    
    // 空盒子
    public var emptyBoxs: [GridView.EmptyBox] = [] { didSet{ setNeedsDisplay() } }
    // 盒子的边框大小
    public var boxBorderSize: CGFloat = 1.0 { didSet{ setNeedsDisplay() } }
    // 盒子的边框颜色
    public var boxBorderColor: UIColor = .red { didSet{ setNeedsDisplay() } }
    
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
                if isDotted {
                    path.lineWidth = borderSize
                    path.lineCapStyle = .round
                    path.lineJoinStyle = .round
                    path.setLineDash(lineDashPattern, count: 2, phase: 0)
                    context?.setStrokeColor(UIColor.red.cgColor)
                    path.stroke()
                }
                context?.setFillColor(enable ? selectedColor.cgColor : normalColor.cgColor)
                path.fill()
                
                text.draw(in: rect, attributes: attributes)
                tempRects.append(rect)
            }
            rects.append(tempRects)
        }
        drawBox()
    }
    
    private func drawEmptyBox(_ rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: itemCornerRadius)
        boxBorderColor.setStroke()
        path.lineWidth = boxBorderSize
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }
    
    private func drawBox() {
        for item in emptyBoxs {
            let r1 = findRect(by: item.start, from: rects)
            let r2 = findRect(by: item.end, from: rects)
            let rect = mergeRects(r1, r2)
            drawEmptyBox(rect)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    /// 初始化参数
    private func setupParams() {
        guard texts.count > 0 else { return }
        guard let val = texts.first?.count, val > 0 else { return }
        row = texts.count
        colum = val
        enables = Array<Array<Bool>>(repeating: Array<Bool>(repeating: false, count: colum), count: row)
    }
    
    /// 设置手势
    private func setupGesture() {
        tap = UITapGestureRecognizer(target: self, action: #selector(GridView.didTap(_:)))
        pan = UIPanGestureRecognizer(target: self, action: #selector(GridView.didPan(_:)))
        addGestureRecognizer(tap)
        addGestureRecognizer(pan)
    }
    
    /// 单点手势
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
    
    /// 滑动手势
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
    
    /// 根据二维数组的位置，获取对应的坐标级大小
    private func findRect(by position: (Int, Int), from rects: [[CGRect]]) -> CGRect {
        guard position.0 >= 0, position.0 < rects.count else { return .zero }
        guard position.1 >= 0, position.1 < rects[0].count else { return .zero }
        return rects[position.0][position.1]
    }
    
    /// 合并两个矩形
    private func mergeRects(_ rect1: CGRect, _ rect2: CGRect) -> CGRect {
        let maxX = rect1.maxX > rect2.maxX ? rect1.maxX : rect2.maxX
        let maxY = rect1.maxY > rect2.maxY ? rect1.maxY : rect2.maxY
        let minX: CGFloat = rect1.minX > rect2.minX ? rect2.minX : rect1.minX
        let minY: CGFloat = rect1.minY > rect2.minY ? rect2.minY : rect1.minY
        let w: CGFloat = maxX - minX
        let h: CGFloat = maxY - minY
        return CGRect(x: minX, y: minY, width: w, height: h)
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
