//
//  ViewController.swift
//  Example
//
//  Created by Chakery on 2017/6/10.
//  Copyright © 2017年 Chakery. All rights reserved.
//

import UIKit
import AyGridView

class ViewController: UIViewController {
    var gridView: GridView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    lazy var texts: [[String]] = {
        return [["d", "i", "s", "p", "o", "s", "e"],
                ["d", "i", "s", "p", "o", "s", "e"],
                ["d", "i", "s", "p", "o", "s", "e"],
                ["d", "i", "s", "p", "o", "s", "e"]]
    }()
    
    func setupView() {
        gridView = GridView(texts: texts)
        gridView.backgroundColor = .green
        gridView.itemSize = CGSize.init(width: 40, height: 40)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.padding = 1.0
        view.addSubview(gridView)
        setupConstraints()
        
        gridView.didChangeCallback = { change in
            print(change)
        }
    }
    
    func setupConstraints() {
        let centerX = NSLayoutConstraint.init(item: gridView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        let top = NSLayoutConstraint.init(item: gridView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 64.0)
        let w = NSLayoutConstraint.init(item: gridView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
        let h = NSLayoutConstraint.init(item: gridView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
        view.addConstraint(centerX)
        view.addConstraint(top)
        view.addConstraint(w)
        view.addConstraint(h)
    }
    
    @IBAction func radiusHandler(_ sender: UISlider) {
        gridView.itemCornerRadius = CGFloat(sender.value) * gridView.getItemSize().height * 0.5
    }
    @IBAction func marginHandler(_ sender: UISlider) {
        gridView.margin = CGFloat(sender.value * 10)
    }
    @IBAction func paddingHandler(_ sender: UISlider) {
        gridView.padding = CGFloat(sender.value * 10)
    }
}

