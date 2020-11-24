//
//  SearchViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/26.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class SearchViewController: UIViewControllerWithCustomizedNavBar {
    
    private var searchBar: SearchBar?
    private var searchResultView: SearchResultView?
    
    private var cache: [PackageStruct]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer {
            setupNavigationBar()
            makeSimpleNavBarBackgorundTransparency()
            makeSimpleNavBarButtonBlue()
            searchBar?.snp.makeConstraints({ (x) in
                x.left.equalTo(self.view.snp.left).offset(18)
                x.right.equalTo(self.view.snp.right).offset(-18)
                x.top.equalTo(SimpleNavBar.snp.bottom).offset(8)
            })
            searchResultView?.snp.makeConstraints({ (x) in
                x.left.equalTo(self.view.snp.left)
                x.right.equalTo(self.view.snp.right)
                x.top.equalTo(searchBar!.snp.bottom).offset(30)
                x.bottom.equalTo(self.view.snp.bottom).offset(-12)
            })
        }
        
        view.backgroundColor = UIColor(named: "SplitDetail-G-Background")
        
        searchBar = SearchBar()
        view.addSubview(searchBar!);
        searchBar?.delegate = self
        
        searchResultView = SearchResultView()
        view.addSubview(searchResultView!)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchResultView?.removeFromSuperview()
        view.addSubview(searchResultView!)
        searchResultView?.snp.makeConstraints({ (x) in
            x.left.equalTo(self.view.snp.left)
            x.right.equalTo(self.view.snp.right)
            x.top.equalTo(searchBar!.snp.bottom).offset(30)
            x.bottom.equalTo(self.view.snp.bottom).offset(-12)
        })
        self.searchBar?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.searchBar?.active()
        }
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.searchBar?.delegate = nil
        }
        
    }
    
    deinit {
        print("[ARC] SearchViewController has been deinited")
    }
    
    
}

// MARK: Operations
extension SearchViewController: SearchBarDelegate {
        
    func focused() {
        
    }
    
    func textDidChange(input: String) {
        searchResultView?.onSearch(content: input)
    }
    
    func performSearch(input: String) {
        // some elastic search result goes here
    }
    
    func finishInput(withResult: String) {
        searchResultView?.onSearch(content: withResult)
    }
    
}
