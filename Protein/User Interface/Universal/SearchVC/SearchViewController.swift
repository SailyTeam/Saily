//
//  SearchViewController.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/26.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    private var searchBar: SearchBar?
    private var searchResultView: SearchResultView?
    
    private var cache: [PackageStruct]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "SplitDetail-G-Background")

        let goBackButton = UIButton(frame: CGRect())
        goBackButton.setTitle("Navigation_GoBack".localized(), for: .normal)
        goBackButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .black)
        goBackButton.contentHorizontalAlignment = .left
        goBackButton.contentVerticalAlignment = .bottom
        goBackButton.addTarget(self, action: #selector(dismissAction), for: .touchUpInside)
        goBackButton.setTitleColor(UIColor(named: "G-Button-Normal"), for: .normal)
        goBackButton.setTitleColor(UIColor(named: "G-Button-Highlighted"), for: .highlighted)
        view.addSubview(goBackButton)
        goBackButton.snp.makeConstraints { (x) in
            x.left.equalTo(self.view).offset(18)
            x.top.equalTo(self.view).offset(38)
            x.width.equalTo(80)
            x.height.equalTo(40)
        }
        
        searchBar = SearchBar()
        view.addSubview(searchBar!);
        searchBar?.snp.makeConstraints({ (x) in
            x.left.equalTo(self.view.snp.left).offset(18)
            x.right.equalTo(self.view.snp.right).offset(-18)
            x.height.equalTo(40)
//            x.centerY.equalTo(goBackButton.snp.centerY)
            x.top.equalTo(goBackButton.snp.bottom).offset(20)
        })
        searchBar?.delegate = self
        
        searchResultView = SearchResultView()
        view.addSubview(searchResultView!)
        searchResultView?.snp.makeConstraints({ (x) in
            x.left.equalTo(self.view.snp.left)
            x.right.equalTo(self.view.snp.right)
            x.top.equalTo(searchBar!.snp.bottom).offset(30)
            x.bottom.equalTo(self.view.snp.bottom).offset(-12)
        })
        
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
    
    @objc private
    func dismissAction() {
        if let nav = navigationController {
            nav.popViewController()
        } else {
            dismiss(animated: true)
        }
    }
        
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
