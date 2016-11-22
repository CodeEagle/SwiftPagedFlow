//
//  SwiftPagedFlow.swift
//  PagedFlowView
//
//  Created by LawLincoln on 15/6/25.
//  Copyright (c) 2015年 Taobao.com. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}


public protocol SwiftPagedFlowViewDataSource: NSObjectProtocol {
    func numberOfPagesInFlowView(_ flowView: SwiftPagedFlow) -> Int
    func cellForPageAtIndex(_ flowView: SwiftPagedFlow, index: Int) -> UIView
}

public protocol SwiftPagedFlowViewDelegate: NSObjectProtocol {
    func sizeForPageInFlowView(_ flowView: SwiftPagedFlow) -> CGSize
    func didScrollToPageAtIndex(_ flowView: SwiftPagedFlow, index: Int)
    func didTapPageAtIndex(_ flowView: SwiftPagedFlow, index: Int)
}
public enum SwiftPagedFlowViewOrientation: Int {
    case horizontal
    case vertical
}
open class SwiftPagedFlow: UIView {
    // MARK: - Public
    open var dataSource: SwiftPagedFlowViewDataSource!
    open var delegate: SwiftPagedFlowViewDelegate!
    open lazy var minimumPageAlpha: CGFloat = 0.8
    open lazy var minimumPageScale: CGFloat = 0.8

    fileprivate var task: CancelableTask?
    /// adjust pageControl origin Y by minus the value from bottom of the SwiftPagedFlow view, for the default pageControl
    open lazy var pageControlOffsetY: CGFloat = 10

    open var orientation: SwiftPagedFlowViewOrientation = .horizontal {
        didSet {
            adjustBounce()
        }
    }
    open var hidePageControl: Bool = false {
        didSet {
            pageControl.isHidden = hidePageControl
        }
    }

    open lazy var pageControl: UIPageControl! = {
        let pc = UIPageControl()
        return pc
    }()
    open var currentPageIndex: Int {
        return _currentPageIndex
    }
    init() {
        super.init(frame: CGRect.zero)
        initialize()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    deinit {
        scrollView.delegate = nil
    }
    // MARK: - Private
    fileprivate lazy var needReload = false
    fileprivate var _currentPageIndex: Int = 0 {
        didSet {
            autoLoopNext()
        }
    }
    fileprivate lazy var pageSize = CGSize(width: 0, height: 0)
    fileprivate lazy var pageCount: Int = 0
    fileprivate lazy var cells = [NSObject]()
    fileprivate lazy var reusableCells = [UIView]()
    fileprivate lazy var visibleRange = NSMakeRange(0, 0)
    fileprivate lazy var scrollView = UIScrollView()
    fileprivate lazy var timeInterVal: CGFloat = 0

}
// MARK: - Public func
extension SwiftPagedFlow {
    public func reloadData() {
        needReload = true
        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        self.setNeedsLayout()
    }

    public func dequeueReusableCell() -> UIView! {
        if reusableCells.count > 0 {
            return reusableCells.removeLast()
        }
        return nil
    }

    public func scrollToPage(_ page: Int) {
        if page < pageCount {
            let horizontal = orientation == .horizontal
            var offset: CGFloat = horizontal ? pageSize.width : pageSize.height
            offset *= CGFloat(page)
            let point = CGPoint(x: horizontal ? offset : 0, y: horizontal ? 0 : offset)
            scrollView.setContentOffset(point, animated: true)
            setPagesAtContentOffset(scrollView.contentOffset)
            refreshVisibleCellAppearance()
        }
    }

    public func getCurrentView() -> UIView! {
        if _currentPageIndex < cells.count {
            return cells[_currentPageIndex] as? UIView
        }
        return nil
    }

    public func enableLoopWithInternal(_ timeInterval: CGFloat, autoStart: Bool = true) {
        timeInterVal = timeInterval
        if autoStart { startLoop() }
    }

    public func startLoop() {
        autoLoopNext()
    }

    public func stopLoop() {
        cancel(task)
    }

}
// MARK: - override
extension SwiftPagedFlow {

    open override func layoutSubviews() {
        super.layoutSubviews()
        if needReload {
            pageControl.frame = CGRect(x: 0, y: self.bounds.size.height - 10 - self.pageControlOffsetY, width: self.bounds.size.width, height: 10)
            if let count = dataSource?.numberOfPagesInFlowView(self) {
                pageCount = count
                pageControl.numberOfPages = count
            }
            if let size = delegate?.sizeForPageInFlowView(self) {
                pageSize = size
            }
            reusableCells.removeAll(keepingCapacity: false)
            visibleRange = NSMakeRange(0, 0)
            for i in 0..<cells.count {
                removeCellAtIndex(i)
            }
            cells.removeAll(keepingCapacity: false)
            for _ in 0..<pageCount {
                cells.append(NSNull())
            }
            let h = orientation == .horizontal
            let width = h ? pageSize.width * CGFloat(pageCount): pageSize.width
            let height = h ? pageSize.height : pageSize.height * CGFloat(pageCount)
            let size = CGSize(width: width, height: height)
            scrollView.frame = CGRect(x: 0, y: 0, width: pageSize.width, height: pageSize.height)

            scrollView.contentSize = size
            let theCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            scrollView.center = theCenter
        }
        setPagesAtContentOffset(scrollView.contentOffset)
        refreshVisibleCellAppearance()
        if (_currentPageIndex >= pageCount) {
            _currentPageIndex = 0
            scrollToPage(0)
        }
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.point(inside: point, with: event) {
            let sp = scrollView.frame.origin
            let os = scrollView.contentOffset
            let x = point.x - sp.x + os.x
            let y = point.y - sp.y + os.y
            let p = CGPoint(x: x, y: y)
            if scrollView .point(inside: p, with: event) {
                return scrollView.hitTest(p, with: event)
            }
            return scrollView
        }
        return nil
    }
}
// MARK: - Private func
extension SwiftPagedFlow {
    fileprivate func initialize() {
        self.clipsToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(SwiftPagedFlow.handleTapGesture(_:)))
        self.addGestureRecognizer(tap)

        pageSize = self.bounds.size
        scrollView.frame = self.bounds
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.clipsToBounds = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        let superViewOfScrollView = UIView(frame: self.bounds)
        superViewOfScrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        superViewOfScrollView.backgroundColor = UIColor.clear
        superViewOfScrollView.addSubview(scrollView)
        self.addSubview(superViewOfScrollView)

        self.addSubview(pageControl)

        adjustBounce()
    }

    fileprivate func adjustBounce() {
        let h = orientation == .horizontal
        scrollView.alwaysBounceHorizontal = h
        scrollView.alwaysBounceVertical = !h
    }

    fileprivate func queueReusableCell(_ cell: UIView) {
        reusableCells.append(cell)
    }
    fileprivate func removeCellAtIndex(_ index: Int) {
        if let cell = cells[index] as? UIView {
            queueReusableCell(cell)
            if cell.superview != nil {
                cell.layer.transform = CATransform3DIdentity
                cell .removeFromSuperview()
            }
            cells[index] = NSNull()
        }
    }
    fileprivate func refreshVisibleCellAppearance() {
        if minimumPageAlpha == 1.0 && minimumPageScale == 1.0 {
            return
        }
        let start = visibleRange.location
        let end = start + visibleRange.length
        let h = orientation == .horizontal
        let offset: CGFloat = h ? scrollView.contentOffset.x : scrollView.contentOffset.y
        for i in start..<end {
            if let cell = cells[i] as? UIView {
                let value = h ? cell.frame.origin.x : cell.frame.origin.y
                let delta = fabs(value - offset)
                let len = h ? pageSize.width : pageSize.height
                if delta < len {
                    let b = (delta / len)
                    cell.alpha = 1 - b * (1 - minimumPageAlpha)
                    let scale = 1 - b * (1 - minimumPageScale)
                    cell.layer.transform = CATransform3DMakeScale(scale, scale, 1)
                } else {
                    cell.alpha = minimumPageAlpha
                    cell.layer.transform = CATransform3DMakeScale(minimumPageScale, minimumPageScale, 1)
                }
            }
        }
    }

    fileprivate func setPagesAtContentOffset(_ offset: CGPoint) {
        if cells.count == 0 {
            return
        }
        let h = orientation == .horizontal
        let startPoint = CGPoint(x: offset.x - scrollView.frame.origin.x, y: offset.y - scrollView.frame.origin.y)
        let endPoint = CGPoint(x: max(0, startPoint.x) + self.bounds.size.width, y: max(0, startPoint.y) + self.bounds.size.height)

        var startIndex: Int = 0
        let startStandar = h ? startPoint.x : startPoint.y
        let factor = h ? pageSize.width : pageSize.height

        for i in 0..<cells.count {
            if factor * CGFloat(i + 1) > startStandar {
                startIndex = i
                break
            }
        }

        var endIndex = startIndex
        let endStandar = h ? endPoint.x : endPoint.y
        for i in startIndex..<cells.count {
            //如果都不超过则取最后一个
            let b = (factor * CGFloat(i + 1) < endStandar && factor * CGFloat(i + 2) >= endStandar) || i + 2 == cells.count
            if b {
                endIndex = i + 1 //i+2 是以个数，所以其index需要减去1
                break
            }
        }
        //可见页分别向前向后扩展一个，提高效率
        startIndex = max(startIndex - 1, 0)
        endIndex = min(endIndex + 1, cells.count - 1)
        if visibleRange.location == startIndex && visibleRange.length == (endIndex - startIndex + 1) {
            return
        }
        visibleRange.location = startIndex
        visibleRange.length = endIndex - startIndex + 1
        for i in startIndex...endIndex {
            setPageAtIndex(i)
        }
        for i in 0..<startIndex {
            removeCellAtIndex(i)
        }
        for i in endIndex + 1..<cells.count {
            removeCellAtIndex(i)
        }
    }

    fileprivate func autoLoopNext() {
        if timeInterVal == 0 {
            return
        }
        cancel(task)
        task = delay(TimeInterval(timeInterVal), work: { [weak self] () -> Void in
            guard let sself = self else { return }
            var next = sself._currentPageIndex + 1
            if next >= sself.dataSource?.numberOfPagesInFlowView(sself) {
                next = 0
            }
            DispatchQueue.main.async(execute: { () -> Void in
                sself._currentPageIndex = next
                sself.pageControl?.currentPage = next
                sself.scrollToPage(next)
            })
        })
    }

    fileprivate func setPageAtIndex(_ index: Int) {
        if index >= 0 && index < cells.count {
            if let _ = cells[index] as? NSNull {
                let aCell = dataSource.cellForPageAtIndex(self, index: index)
                cells[index] = aCell
                let fIndex = CGFloat(index)
                switch orientation {
                case .horizontal:
                    aCell.frame = CGRect(x: pageSize.width * fIndex, y: 0, width: pageSize.width, height: pageSize.height);
                    break;
                case .vertical:
                    aCell.frame = CGRect(x: 0, y: pageSize.height * fIndex, width: pageSize.width, height: pageSize.height);
                    break;
                }
                if aCell.superview == nil {
                    // align aCell from the left
                    scrollView .addSubview(aCell)
                }
            }
        } else {
            debugPrint("index over bounds")
        }

    }

    func handleTapGesture(_ tap: UIGestureRecognizer) {
        var tappedIndex: Int = 0
        let locationInScrollView = tap.location(in: scrollView)
        if scrollView.bounds.contains(locationInScrollView) {
            tappedIndex = _currentPageIndex
            delegate?.didTapPageAtIndex(self, index: tappedIndex)
        }
    }


}
// MARK: - UIScrollViewDelegate
extension SwiftPagedFlow: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setPagesAtContentOffset(scrollView.contentOffset)
        refreshVisibleCellAppearance()
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        let horizontal = orientation == .horizontal
        let up = horizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y
        let down = horizontal ? pageSize.width : pageSize.height
        let index = floor(max(floor(up), 0) / floor(down))
        let pageIndex = index.isNaN ? 0 : Int(index)
        let tmpIndex = _currentPageIndex
        _currentPageIndex = pageIndex
        pageControl?.currentPage = _currentPageIndex
        if tmpIndex != _currentPageIndex {
            delegate?.didScrollToPageAtIndex(self, index: _currentPageIndex)
        }
    }
}

//MARK:- CancelableTask

typealias CancelableTask = (_ cancel: Bool) -> Void

func delay(_ time: TimeInterval, work: @escaping () -> ()) -> CancelableTask? {

    var finalTask: CancelableTask?

    let cancelableTask: CancelableTask = { cancel in
        if cancel {
            finalTask = nil // key
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    finalTask = cancelableTask

    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
        if let task = finalTask {
            task(false)
        }
    }

    return finalTask
}

func cancel(_ cancelableTask: CancelableTask?) {
    cancelableTask?(true)
}
