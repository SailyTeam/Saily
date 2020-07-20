//
//  SearchResultView.swift
//  Protein
//
//  Created by soulghost on 10/5/2020.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class SearchResultView : UIView {
    
    internal var tableView: UITableView?
    internal var results: [SearchResultCellModel]? {
        didSet {
            // debug purpose
            // todo: put all search in .global(qos: .background).async queue
        }
    }
    private  var throttler: CommonThrottler?
    private  var searchManager: SearchIndexManager?
    private  var lastSearchContent: String?
    private  var searchSequence: Int = 0
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        throttler = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        asyncSetup()
    }

    // async setup should be called from background thread
    private var indexCache: [PackageStruct]?
    private func asyncSetup() {
        
        throttler = CommonThrottler(minimumDelay: 0.1) // data goes a lot if you have 125 repos
        
        tableView = UITableView()
        tableView?.backgroundColor = .clear
        tableView?.separatorColor = .clear
        addSubview(tableView!)
        tableView?.snp.makeConstraints({ (x) in
            x.edges.equalTo(self.snp.edges)
        })
        
        searchManager = SearchIndexManager.shared
        setupDataSource()
        setupResults()
    }
    
    private func setupResults() {
        self.results = []
    }
    
    func onSearch(content: String, now: Bool = false) {
        defer {
            lastSearchContent = content
        }
        if content.count > 0 {
            if now {
                searchSequence += 1
                DispatchQueue.global(qos: .background).async {
                    self.doSearch(content: content)
                }
            } else {
                throttler?.throttle {
                    self.searchSequence += 1
                    DispatchQueue.global(qos: .background).async {
                        self.doSearch(content: content)
                    }
                }
            }
        } else {
            // if we go from search to idle
            // we should revert the list and keywords
            guard self.lastSearchContent?.count ?? 0 > 0 else {
                return
            }
            
            // this maybe got stucked
            results = []
            tableView?.reloadData()
        }
    }
    
    // rua rua rua rua rua rua
    
//    private var searchLock = false
//    private var onceMore: String? = nil
    private func doSearch(content: String) {
        print("[Search] Throttler passed value: "  + content)
        let mySequence = searchSequence
        let packages = searchManager!.searchInSnapshotWith(keywords: content)
        var models: [SearchResultCellModel] = []
        for (package, tokens) in packages {
            let desc = package.obtainAuthorIfExists() + ": " + package.obtainDescriptionIfExistsOrVersion()
            let model = SearchResultCellModel(withPackageRef: package, andDescriptionShownInResultView: desc)
            model.keywords = tokens
            model.setup()
            models.append(model)
        }
        DispatchQueue.main.async {
            if self.searchSequence != mySequence {
                return
            }
            self.results = models
            self.tableView?.reloadData()
        }
    }
}
