//
//  ViewController.swift
//  SwiftPagedFlow
//
//  Created by CodeEagle on 06/25/2015.
//  Copyright (c) 06/25/2015 CodeEagle. All rights reserved.
//

import UIKit
import SwiftPagedFlow
class ViewController: UIViewController {

    @IBOutlet weak var pc: UIPageControl!
    @IBOutlet weak var hFlow: SwiftPagedFlow!
    @IBOutlet weak var vFlow: SwiftPagedFlow!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        hFlow.delegate = self
        hFlow.dataSource = self
        hFlow.pageControl = pc
        hFlow.minimumPageAlpha = 0.4
        hFlow.minimumPageScale = 0.8
        
        vFlow.delegate = self
        vFlow.dataSource = self
        vFlow.minimumPageAlpha = 0.4
        vFlow.minimumPageScale = 0.8
        vFlow.orientation = .Vertical
        vFlow.pageControlOffsetY = 50
        
        hFlow.reloadData()
        vFlow.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: SwiftPagedFlowViewDelegate, SwiftPagedFlowViewDataSource {
    func numberOfPagesInFlowView(flowView: SwiftPagedFlow) -> Int{
        return 8
    }
    
    func cellForPageAtIndex(flowView: SwiftPagedFlow, index: Int) -> UIView{
        var view = flowView.dequeueReusableCell() as? UIImageView
        if view == nil {
            let aview = UIImageView()
            aview.layer.cornerRadius = 6
            aview.layer.masksToBounds = true
            view = aview
        }
        view?.image = UIImage(named: "\(index).tiff", inBundle: nil, compatibleWithTraitCollection: nil)
        return view!
    }
    
    
    func sizeForPageInFlowView(flowView: SwiftPagedFlow) -> CGSize {
        let width = self.view.bounds.size.width - 60
        return CGSizeMake(width, width*0.75)
    }
    func didScrollToPageAtIndex(flowView: SwiftPagedFlow, index: Int){
        debugPrintln("Scrolled to page:\(index)")
    }
    func didTapPageAtIndex(flowView: SwiftPagedFlow, index: Int){
        debugPrintln("Tapped on page:\(index)")
    }
}