//
//  ViewController.swift
//  SwiftPagedFlow
//
//  Created by CodeEagle on 06/25/2015.
//  Copyright (c) 06/25/2015 CodeEagle. All rights reserved.
//

import UIKit

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
        hFlow.minimumPageAlpha = 0.8
        hFlow.minimumPageScale = 0.8
//        hFlow.enableLoopWithInternal(3)
        vFlow.delegate = self
        vFlow.dataSource = self
        vFlow.minimumPageAlpha = 0.4
        vFlow.minimumPageScale = 0.8
        vFlow.orientation = .vertical
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
    func numberOfPagesInFlowView(_ flowView: SwiftPagedFlow) -> Int{
        return 8
    }
    
    func cellForPageAtIndex(_ flowView: SwiftPagedFlow, index: Int) -> UIView{
        var view = flowView.dequeueReusableCell() as? UIImageView
        if view == nil {
            let aview = UIImageView()
            aview.layer.cornerRadius = 6
            aview.layer.masksToBounds = true
            view = aview
        }
        view?.backgroundColor = .orange
        return view!
    }
    
    
    func sizeForPageInFlowView(_ flowView: SwiftPagedFlow) -> CGSize {
        let width = self.view.bounds.size.width - 100
        return CGSize(width: width, height: width*0.75)
    }
    func didScrollToPageAtIndex(_ flowView: SwiftPagedFlow, index: Int){
//        debugPrint("Scrolled to page:\(index)")
    }
    func didTapPageAtIndex(_ flowView: SwiftPagedFlow, index: Int){
//        debugPrint("Tapped on page:\(index)")
    }
}
