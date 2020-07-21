//
//  AppleCardColorView.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class AppleCardColorView: UIView {
    
    private var isAinUse: Bool = false
    private var containerA = UIView()
    private var containerB = UIView()
    
    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.regular))
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init() {
        super.init(frame: CGRect())
        
        backgroundColor = UIColor(named: "G-ViewController-Background")
        
        addSubview(containerA)
        containerA.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        addSubview(containerB)
        containerB.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        clipsToBounds = true
//        blurEffectView.alpha = 0
        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadColors), name: .AppleCardColorViewDataUpdated, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AppleCardColorProvider.shared.cacheWidth = Int(self.frame.width)
            AppleCardColorProvider.shared.cacheHeight = Int(self.frame.height)
            self.reloadColors()
        }
    }
    
    
    private var tot = CommonThrottler(minimumDelay: 3)
    @objc
    func reloadColors() {
        tot.throttle {
            let targetContainer = self.isAinUse ? self.containerB : self.containerA
            let oldContainer = self.isAinUse ? self.containerA : self.containerB
            
            self.isAinUse = !self.isAinUse
            
            targetContainer.alpha = 0
            targetContainer.subviews.forEach { (view) in
                view.removeFromSuperview()
            }
            
            //                          from  x        y        r  to    x        y        r
            var viewContainer = [Int : (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, UIView)]()
            //                          0        1        2        3        4        5        6
            
            for (index, item) in AppleCardColorProvider.shared.records.enumerated() {
                let view = UIView()
                targetContainer.addSubview(view)
                view.backgroundColor = item.2
                view.alpha = /* CGFloat(Double.random(in: 0.4...1.0)) */ 0.6
                view.layer.cornerRadius = CGFloat(item.3)
                
                let getx = CGFloat(item.0)
                let gety = CGFloat(item.1)
                let getr = CGFloat(item.3 * 2)
                let rndx = CGFloat.random(in: -200...200)
                let rndy = CGFloat.random(in: -200...200)
                let rndr = CGFloat.random(in: 0.5...2)
                
                let fromx = getx + rndx
                let fromy = gety + rndy
                let fromsize = getr * rndr
                
                view.snp.makeConstraints { (x) in
                    x.width.equalTo(fromsize)
                    x.height.equalTo(fromsize)
                    x.centerX.equalTo(targetContainer.snp.left).offset(fromx)
                    x.centerY.equalTo(targetContainer.snp.top).offset(fromy)
                }
                view.layoutIfNeeded()
                viewContainer[index] = (fromx, fromy, fromsize, getx, gety, getr, view)
//                print(viewContainer[index].debugDescription)
            }
            self.bringSubviewToFront(targetContainer)
            self.bringSubviewToFront(self.blurEffectView)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIView.animate(withDuration: 1.5) {
                    targetContainer.alpha = 1
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                UIView.animate(withDuration: 2.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    for (_, load) in viewContainer {
                        load.6.snp.updateConstraints { (x) in
                            x.width.equalTo(load.5)
                            x.height.equalTo(load.5)
                            x.centerX.equalTo(targetContainer.snp.left).offset(load.3)
                            x.centerY.equalTo(targetContainer.snp.top).offset(load.4)
                        }
                    }
                    self.layoutIfNeeded()
                }) { (_) in
                    
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIView.animate(withDuration: 1) {
                    oldContainer.alpha = 0
                }
            }
        }
    }
    
}

class AppleCardColorProvider {
    
    static let shared = AppleCardColorProvider()
    
    let maxColor = 32
    
    var recordLocation: String = ConfigManager.shared.documentString + "/AppleCardColorRecord.foo"
    
    required init() {
        loadRecord()
        
        #if DEBUG
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            self.addColor(withCount: 4)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
//            self.addColor(withCount: 4)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
//            self.addColor(withCount: 4)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 14) {
//            self.addColor(withCount: 4)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 17) {
//            self.addColor(withCount: 4)
//        }
        #endif
        
    }
    
    public var records: [(Int, Int, UIColor, Int)] = [] {
        didSet {
            saveRecord()
            NotificationCenter.default.post(name: .AppleCardColorViewDataUpdated, object: nil)
        }
    }
    
    func saveRecord() {
        var write = ""
        for item in records {
            write += String(item.0) + "|"
            write += String(item.1) + "|"
            write += item.2.toHexString() + "|"
            write += String(item.3) + "\n"
        }
        try? write.write(toFile: recordLocation, atomically: true, encoding: .utf8)
    }
    
    func loadRecord() {
        do {
            let str = try String(contentsOfFile: recordLocation)
            var new = [(Int, Int, UIColor, Int)]()
            inner: for line in str.components(separatedBy: "\n") {
                // 10|10|0xffffff|10
                // xx|yy|00xColor|rr
                let cut = line.components(separatedBy: "|")
                if cut.count != 4 {
                    continue inner
                }
                if let xl = Int(cut[0]), let yl = Int(cut[1]),
                    let color = UIColor(hexString: cut[2]), let rl = Int(cut[3]) {
                    new.append((xl, yl, color, rl))
                }
            }
            records = new
        } catch {
            try? FileManager.default.removeItem(atPath: recordLocation)
            FileManager.default.createFile(atPath: recordLocation, contents: nil, attributes: [:])
            records = []
        }
    }
    
    public var _cacheWidth: Int = 320
    public var cacheWidth: Int {
        set {
            if newValue < 10 {
                return
            }
            _cacheWidth = newValue
        }
        get {
            return _cacheWidth
        }
    }
    private var _cacheHeight: Int = 180
    public var cacheHeight: Int {
        set {
            if newValue < 10 {
                return
            }
            _cacheHeight = newValue
        }
        get {
            return _cacheHeight
        }
    }
    
    func addColor(withCount: Int) {
        
        if withCount < 1 {
            return
        }
        if withCount > 10 {
            return
        }
        var capture = records
        for _ in 0...withCount {
            var rangeX = Int(cacheWidth)
            var rangeY = Int(cacheHeight)
            var rangeR = Int((rangeY + rangeX) / 8)
            if rangeX < 0 { rangeX = 0 }
            if rangeY < 0 { rangeY = 0 }
            if rangeR < 25 { rangeR = 25 }
            let color = UIColor.randomAsPudding
            
            let x = Int.random(in: (-10)...(rangeX + 10))
            let y = Int.random(in: (-10)...(rangeY + 10))
            let r = Int.random(in: (25...rangeR))
            
            #if DEBUG
            print("[AppleCard] x" + String(x) + ", y" + String(y) + ", c " + color.toHexString() + ", r", String(r))
            #endif
            
            capture.append((x, y, color, r))
        }
        while capture.count > maxColor {
            capture.removeFirst()
        }
        records = capture
    }
}
