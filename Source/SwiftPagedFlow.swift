//
//  SwiftPagedFlow.swift
//  PagedFlowView
//
//  Created by LawLincoln on 15/6/25.
//  Copyright (c) 2015年 Taobao.com. All rights reserved.
//

import UIKit

public protocol SwiftPagedFlowViewDataSource: NSObjectProtocol {
    func numberOfPagesInFlowView(flowView: SwiftPagedFlow)->Int
    func cellForPageAtIndex(flowView: SwiftPagedFlow, index: Int)->UIView
}

public  protocol SwiftPagedFlowViewDelegate: NSObjectProtocol {
    func sizeForPageInFlowView(flowView: SwiftPagedFlow)->CGSize
    func didScrollToPageAtIndex(flowView: SwiftPagedFlow, index: Int)
    func didTapPageAtIndex(flowView: SwiftPagedFlow, index: Int)
}
public enum SwiftPagedFlowViewOrientation: Int {
    case Horizontal
    case Vertical
}
public class SwiftPagedFlow: UIView{
    // MARK: - Public
    public var dataSource: SwiftPagedFlowViewDataSource!
    public var delegate: SwiftPagedFlowViewDelegate!
    public lazy var minimumPageAlpha: CGFloat = 0.8
    public lazy var minimumPageScale: CGFloat = 0.8
    /// adjust pageControl origin Y by minus the value from bottom of the SwiftPagedFlow view, for the default pageControl
    public lazy var pageControlOffsetY: CGFloat = 10
    public lazy var orientation: SwiftPagedFlowViewOrientation = .Horizontal
    public var pageControl: UIPageControl!
    public var currentPageIndex: Int {
        return _currentPageIndex
    }
    
    init() {
        super.init(frame: CGRectZero)
        initialize()
    }
    
    override public init(frame: CGRect){
        super.init(frame: frame)
        initialize()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    deinit {
        scrollView.delegate = nil
    }
    // MARK: - Private
    private lazy var needReload = false
    private lazy var _currentPageIndex: Int = 0
    private lazy var pageSize = CGSizeMake(0,0)
    private lazy var pageCount: Int = 0
    private lazy var cells = [NSObject]()
    private lazy var reusableCells = [UIView]()
    private lazy var visibleRange = NSMakeRange(0, 0)
    private lazy var scrollView = UIScrollView()
}
// MARK: - Public func
extension SwiftPagedFlow {
    public func reloadData() {
        needReload = true
        for view in scrollView.subviews as! [UIView]{
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
    
    public func scrollToPage(page: Int) {
        if page < pageCount {
            let horizontal = orientation == .Horizontal
            var offset: CGFloat = horizontal ? pageSize.width : pageSize.height
            offset *= CGFloat(page)
            let point = CGPointMake(horizontal ? offset : 0, horizontal ? 0 : offset)
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
    
    
}
// MARK: - override
extension SwiftPagedFlow {
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if needReload {
            if pageControl == nil {
                pageControl = UIPageControl()
                pageControl.frame = CGRectMake(0, self.bounds.size.height-10-pageControlOffsetY, self.bounds.size.width, 10)
                self.addSubview(pageControl)
            }
            if let count = dataSource?.numberOfPagesInFlowView(self) {
                pageCount = count
                pageControl.numberOfPages = count
            }
            if let size = delegate?.sizeForPageInFlowView(self) {
                pageSize = size
            }
            reusableCells.removeAll(keepCapacity: false)
            visibleRange = NSMakeRange(0, 0)
            for i in 0..<cells.count {
                removeCellAtIndex(i)
            }
            cells.removeAll(keepCapacity: false)
            for i in 0..<pageCount {
                cells.append(NSNull())
            }
            let h = orientation == .Horizontal
            let width = h ? pageSize.width * CGFloat(pageCount) : pageSize.width
            let height = h ? pageSize.height : pageSize.height * CGFloat(pageCount)
            let size = CGSizeMake(width, height)
            scrollView.frame = CGRectMake(0, 0, pageSize.width, pageSize.height)
            
            scrollView.contentSize = size
            let theCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
            scrollView.center = theCenter
        }
        setPagesAtContentOffset(scrollView.contentOffset)
        refreshVisibleCellAppearance()
        if (_currentPageIndex >= pageCount) {
            _currentPageIndex = 0
            scrollToPage(0)
        }
    }
    
    public override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        if self.pointInside(point, withEvent: event) {
            let sp = scrollView.frame.origin
            let os = scrollView.contentOffset
            let x = point.x - sp.x + os.x
            let y = point.y - sp.y + os.y
            let p = CGPointMake(x, y)
            if scrollView .pointInside(p, withEvent: event) {
                return scrollView.hitTest(p, withEvent: event)
            }
            return scrollView
        }
        return nil
    }
}
// MARK: - Private func
extension SwiftPagedFlow {
    private func initialize() {
        self.clipsToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: Selector("handleTapGesture:"))
        self.addGestureRecognizer(tap)
        
        pageSize = self.bounds.size
        scrollView.frame = self.bounds
        scrollView.delegate = self
        scrollView.pagingEnabled = true
        scrollView.clipsToBounds = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        let superViewOfScrollView = UIView(frame: self.bounds)
        superViewOfScrollView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        superViewOfScrollView.backgroundColor = UIColor.clearColor()
        superViewOfScrollView.addSubview(scrollView)
        self.addSubview(superViewOfScrollView)
        
        
    }
    
    private func queueReusableCell(cell: UIView) {
        reusableCells.append(cell)
    }
    private func removeCellAtIndex(index: Int) {
        if let cell = cells[index] as? UIView {
            queueReusableCell(cell)
            if cell.superview != nil {
                cell.layer.transform = CATransform3DIdentity
                cell .removeFromSuperview()
            }
            cells[index] = NSNull()
        }
    }
    private func refreshVisibleCellAppearance() {
        if minimumPageAlpha == 1.0 && minimumPageScale == 1.0 {
            return
        }
        let start = visibleRange.location
        let end = start + visibleRange.length
        let h = orientation == .Horizontal
        var offset:CGFloat = h ? scrollView.contentOffset.x : scrollView.contentOffset.y
        for i in start..<end {
            if let cell = cells[i] as? UIView {
                let value = h ? cell.frame.origin.x : cell.frame.origin.y
                let delta = fabs(value - offset)
                let len = h ? pageSize.width : pageSize.height
                if delta < len {
                    let b = (delta / len)
                    cell.alpha = 1 -  b * (1 - minimumPageAlpha)
                    let scale = 1 - b * (1 - minimumPageScale)
                    cell.layer.transform = CATransform3DMakeScale(scale, scale, 1)
                }else{
                    cell.alpha = minimumPageAlpha
                    cell.layer.transform = CATransform3DMakeScale(minimumPageScale, minimumPageScale, 1)
                }
            }
        }
    }
    
    private func setPagesAtContentOffset(offset: CGPoint) {
        if cells.count == 0 {
            return
        }
        let h = orientation == .Horizontal
        let startPoint = CGPointMake(offset.x - scrollView.frame.origin.x, offset.y - scrollView.frame.origin.y)
        let endPoint = CGPointMake(max(0, startPoint.x) + self.bounds.size.width, max(0, startPoint.y) + self.bounds.size.height)
        
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
        var endStandar = h ? endPoint.x : endPoint.y
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
        for i in endIndex+1..<cells.count {
            removeCellAtIndex(i)
        }
    }
    private func setPageAtIndex(index: Int) {
        assert(index >= 0 && index < cells.count, "index over bounds")
        if let cell = cells[index] as? NSNull {
            let aCell = dataSource.cellForPageAtIndex(self, index: index)
            let range = Range(start: index, end: index + 1)
            cells[index] = aCell
            let fIndex = CGFloat(index)
            switch orientation {
            case .Horizontal:
                aCell.frame = CGRectMake(pageSize.width * fIndex, 0, pageSize.width, pageSize.height);
                break;
            case .Vertical:
                aCell.frame = CGRectMake(0, pageSize.height * fIndex, pageSize.width, pageSize.height);
                break;
            default:
                break;
            }
            if aCell.superview == nil {
                scrollView .addSubview(aCell)
            }
        }
    }
    
    func handleTapGesture(tap: UIGestureRecognizer){
        var tappedIndex: Int = 0
        let locationInScrollView = tap.locationInView(scrollView)
        if CGRectContainsPoint(scrollView.bounds, locationInScrollView) {
            tappedIndex = _currentPageIndex
            delegate?.didTapPageAtIndex(self, index: tappedIndex)
        }
    }
    
    
}
// MARK: - UIScrollViewDelegate
extension SwiftPagedFlow: UIScrollViewDelegate{
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        setPagesAtContentOffset(scrollView.contentOffset)
        refreshVisibleCellAppearance()
    }
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let horizontal = orientation == .Horizontal
        let up = horizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y
        let down = horizontal ? pageSize.width : pageSize.height
        var index = floor(max(up, 0) / down)
        let pageIndex = index.isNaN ? 0 : Int(index)
        let tmpIndex = _currentPageIndex
        _currentPageIndex = pageIndex
        pageControl?.currentPage = _currentPageIndex
        if tmpIndex != _currentPageIndex {
            delegate?.didScrollToPageAtIndex(self, index: _currentPageIndex)
        }
    }
}