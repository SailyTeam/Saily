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
    
    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.systemThinMaterial))
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init() {
        super.init(frame: CGRect())
        addSubview(containerA)
        containerA.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        addSubview(containerB)
        containerB.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        clipsToBounds = true
        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { (x) in
            x.edges.equalToSuperview()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadColors), name: .AppleCardColorViewDataUpdated, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppleCardColorProvider.shared.cacheWidth = Int(self.frame.width)
            AppleCardColorProvider.shared.cacheHeight = Int(self.frame.height)
            self.reloadColors()
        }
    }
    
    
    private var tot = CommonThrottler(minimumDelay: 1)
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
            for item in AppleCardColorProvider.shared.records {
                let view = UIView()
                targetContainer.addSubview(view)
                view.backgroundColor = item.2
                view.layer.cornerRadius = CGFloat(item.3)
                view.snp.makeConstraints { (x) in
                    x.width.equalTo(item.3 * 2)
                    x.height.equalTo(item.3 * 2)
                    x.centerX.equalTo(targetContainer.snp.left).offset(item.0)
                    x.centerY.equalTo(targetContainer.snp.top).offset(item.1)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIView.animate(withDuration: 0.8) {
                    targetContainer.alpha = 1
                    oldContainer.alpha = 0
                }
            }
        }
    }
    
}

class AppleCardColorProvider {
    
    static let shared = AppleCardColorProvider()
    
    var recordLocation: String = ConfigManager.shared.documentString + "/AppleCardColorRecord.foo"
    
    required init() {
        loadRecord()
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
    
    public var cacheWidth: Int = 0
    public var cacheHeight: Int = 0
    
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
            var rangeR = Int((rangeY + rangeX) / 10)
            if rangeX < 0 { rangeX = 0 }
            if rangeY < 0 { rangeY = 0 }
            if rangeR < 50 { rangeR = 50 }
            capture.append((Int.random(in: (-10)...(rangeX + 10)),
                            Int.random(in: (-10)...(rangeY + 10)),
                            UIColor.randomAsPudding,
                            Int.random(in: (50...rangeR))))
        }
        while capture.count > 10 {
            capture.removeFirst()
        }
        records = capture
    }
}
